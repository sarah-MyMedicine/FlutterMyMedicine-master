
import React, { useState, useEffect } from 'react';
import { Medication, UserProfile } from '../types';

interface MedicationFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (medication: Medication) => void;
  medicationToEdit: Partial<Medication> | null;
  isBirthControlMode: boolean;
  userProfile: UserProfile;
}

const MedicationFormModal: React.FC<MedicationFormModalProps> = ({ isOpen, onClose, onSave, medicationToEdit, isBirthControlMode, userProfile }) => {
  const [name, setName] = useState('');
  const [dosage, setDosage] = useState('');
  const [frequency, setFrequency] = useState(8);
  const [startDate, setStartDate] = useState(new Date().toISOString().substring(0, 10));
  const [startTimeOfDay, setStartTimeOfDay] = useState(() => {
    const now = new Date();
    return now.toTimeString().substring(0, 5);
  });
  const [notes, setNotes] = useState('');
  const [quantity, setQuantity] = useState('');
  const [refillThreshold, setRefillThreshold] = useState('');
  
  // Cyclic medication state
  const [isCyclic, setIsCyclic] = useState(false);
  const [activeDays, setActiveDays] = useState('21');
  const [restDays, setRestDays] = useState('7');


  useEffect(() => {
    if (medicationToEdit) {
      setName(medicationToEdit.name || '');
      setDosage(medicationToEdit.dosage || '');
      setFrequency(medicationToEdit.frequency || 8);
      const doseDate = medicationToEdit.nextDose ? new Date(medicationToEdit.nextDose) : new Date();
      setStartDate(doseDate.toISOString().substring(0, 10));
      setStartTimeOfDay(doseDate.toTimeString().substring(0, 5));
      setNotes(medicationToEdit.notes || '');
      setQuantity(medicationToEdit.quantity?.toString() || '');
      setRefillThreshold(medicationToEdit.refillThreshold?.toString() || '');
      setIsCyclic(medicationToEdit.isCyclic || false);
      setActiveDays(medicationToEdit.activeDays?.toString() || '21');
      setRestDays(medicationToEdit.restDays?.toString() || '7');
    } else {
      // Reset form when adding a new one
      const now = new Date();
      setName('');
      setDosage('');
      setFrequency(isBirthControlMode ? 24 : 8);
      setStartDate(now.toISOString().substring(0, 10));
      setStartTimeOfDay(now.toTimeString().substring(0, 5));
      setNotes('');
      setQuantity('');
      setRefillThreshold('');
      setIsCyclic(isBirthControlMode);
      setActiveDays('21');
      setRestDays('7');
    }
  }, [medicationToEdit, isOpen, isBirthControlMode]);

  useEffect(() => {
    // If cyclic is enabled, force frequency to 24 hours
    if (isCyclic || isBirthControlMode) {
        setFrequency(24);
    }
  }, [isCyclic, isBirthControlMode]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !dosage || !frequency) return;

    const nextDoseTimestamp = new Date(`${startDate}T${startTimeOfDay}`).getTime();
    const qty = quantity ? Number(quantity) : undefined;
    
    const needsRefillReset = medicationToEdit?.quantity !== qty;

    onSave({
      id: medicationToEdit?.id || Date.now().toString(),
      name,
      dosage,
      frequency: Number(frequency),
      nextDose: nextDoseTimestamp,
      notes,
      quantity: qty,
      remainingDoses: medicationToEdit?.id && !needsRefillReset ? medicationToEdit.remainingDoses : qty,
      refillThreshold: refillThreshold ? Number(refillThreshold) : undefined,
      refillNotified: needsRefillReset ? false : medicationToEdit?.refillNotified,
      isCyclic: isCyclic || isBirthControlMode,
      activeDays: (isCyclic || isBirthControlMode) ? Number(activeDays) : undefined,
      restDays: (isCyclic || isBirthControlMode) ? Number(restDays) : undefined,
      cycleStartDate: medicationToEdit?.cycleStartDate,
    });
    onClose();
  };

  if (!isOpen) return null;

  const effectiveIsCyclic = isCyclic || isBirthControlMode;
  const title = isBirthControlMode && !medicationToEdit?.id ? 'إضافة حبوب منع الحمل' : (medicationToEdit?.id ? 'تعديل الدواء' : 'إضافة دواء جديد');

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-md transform transition-all animate-fade-in-up max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">{title}</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="name" className="block text-gray-700 text-sm font-bold mb-2">اسم الدواء</label>
            <input type="text" id="name" value={name} onChange={(e) => setName(e.target.value)} className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" required />
          </div>
          <div className="mb-4">
            <label htmlFor="dosage" className="block text-gray-700 text-sm font-bold mb-2">الجرعة (مثال: 1 قرص, 500 ملغ)</label>
            <input type="text" id="dosage" value={dosage} onChange={(e) => setDosage(e.target.value)} className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" required />
          </div>
          
          {userProfile.gender === 'أنثى' && !userProfile.isPregnant && !isBirthControlMode && (
             <div className="mb-4 bg-gray-50 p-3 rounded-lg">
                <label className="flex items-center cursor-pointer">
                    <input type="checkbox" checked={isCyclic} onChange={(e) => setIsCyclic(e.target.checked)} className="form-checkbox h-5 w-5 text-[#5fb8a8] rounded focus:ring-[#5fb8a8]" />
                    <span className="ms-3 text-gray-700 font-semibold">هذا دواء دوري (مثل حبوب منع الحمل)</span>
                </label>
            </div>
          )}

          {effectiveIsCyclic ? (
            <div className="mb-4 p-4 border rounded-lg bg-[#f0f9f8] border-[#c3e7e2] animate-fade-in">
                <h3 className="text-lg font-bold text-[#45887e] mb-2">إعدادات الدورة</h3>
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label htmlFor="activeDays" className="block text-gray-700 text-sm font-bold mb-2">أيام التناول</label>
                        <input type="number" id="activeDays" value={activeDays} onChange={(e) => setActiveDays(e.target.value)} placeholder="21" className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" />
                    </div>
                    <div>
                        <label htmlFor="restDays" className="block text-gray-700 text-sm font-bold mb-2">أيام الراحة</label>
                        <input type="number" id="restDays" value={restDays} onChange={(e) => setRestDays(e.target.value)} placeholder="7" className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" />
                    </div>
                </div>
                 <p className="text-xs text-gray-600 mt-3">سيتم تذكيرك يوميًا خلال فترة التناول، ثم يتوقف التذكير خلال فترة الراحة.</p>
            </div>
          ) : (
             <div className="mb-4">
                <label htmlFor="frequency" className="block text-gray-700 text-sm font-bold mb-2">التكرار (كل كم ساعة)</label>
                <select id="frequency" value={frequency} onChange={(e) => setFrequency(Number(e.target.value))} className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]">
                  <option value={4}>كل 4 ساعات</option>
                  <option value={6}>كل 6 ساعات</option>
                  <option value={8}>كل 8 ساعات</option>
                  <option value={12}>كل 12 ساعة</option>
                  <option value={24}>كل 24 ساعة (مرة يوميًا)</option>
                </select>
            </div>
          )}
          
          <div className="mb-4">
            <label className="block text-gray-700 text-sm font-bold mb-2">وقت أول جرعة</label>
            <div className="grid grid-cols-2 gap-2">
              <input type="date" id="start-date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" required />
              <input type="time" id="start-time" value={startTimeOfDay} onChange={(e) => setStartTimeOfDay(e.target.value)} className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" required />
            </div>
          </div>
          <div className="mb-4">
            <label htmlFor="notes" className="block text-gray-700 text-sm font-bold mb-2">ملاحظات (اختياري)</label>
            <textarea id="notes" value={notes} onChange={(e) => setNotes(e.target.value)} className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8] h-24"></textarea>
          </div>
          
          <div className="border-t my-6"></div>
          
          <h3 className="text-lg font-bold text-[#45887e] mb-2">تنبيهات إعادة التعبئة (اختياري)</h3>
          <p className="text-sm text-gray-600 mb-4">
            سنقوم بتنبيهك عندما ينخفض مخزون الدواء عن الحد الذي تحدده.
          </p>
          <div className="grid grid-cols-2 gap-4 mb-6">
              <div>
                  <label htmlFor="quantity" className="block text-gray-700 text-sm font-bold mb-2">الكمية الإجمالية (عدد الجرعات)</label>
                  <input type="number" id="quantity" value={quantity} onChange={(e) => setQuantity(e.target.value)} placeholder="مثال: 30" className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" />
              </div>
              <div>
                  <label htmlFor="refill-threshold" className="block text-gray-700 text-sm font-bold mb-2">تنبيه عند وصول المخزون إلى</label>
                  <input type="number" id="refill-threshold" value={refillThreshold} onChange={(e) => setRefillThreshold(e.target.value)} placeholder="مثال: 5" className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" />
              </div>
          </div>

          <div className="flex items-center justify-between">
            <button type="submit" className="bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 transition-colors duration-300">
              حفظ
            </button>
            <button type="button" onClick={onClose} className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 ms-3 transition-colors duration-300">
              إلغاء
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default MedicationFormModal;

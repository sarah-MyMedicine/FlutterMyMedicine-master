
import React, { useState, useEffect } from 'react';
import { Medication, SymptomLog } from '../types';
import { ShieldCheckIcon, PillIcon, UserIcon } from './icons';

interface SymptomFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (symptom: { 
    symptom: string; 
    severity: 'خفيف' | 'متوسط' | 'شديد'; 
    notes?: string; 
    isReported?: boolean; 
    relatedMedicationId?: string;
    patientConditions?: {
        hasAllergy: boolean;
        isSmoker: boolean;
        hasKidneyIssue: boolean;
        hasLiverIssue: boolean;
    }
  }) => void;
  medications: Medication[];
  symptomToEdit?: SymptomLog | null;
}

const SymptomFormModal: React.FC<SymptomFormModalProps> = ({ isOpen, onClose, onSave, medications, symptomToEdit }) => {
  const [symptom, setSymptom] = useState('');
  const [severity, setSeverity] = useState<'خفيف' | 'متوسط' | 'شديد'>('متوسط');
  const [notes, setNotes] = useState('');
  const [isReported, setIsReported] = useState(false);
  const [selectedMedId, setSelectedMedId] = useState('');
  
  // Patient Conditions State
  const [hasAllergy, setHasAllergy] = useState(false);
  const [isSmoker, setIsSmoker] = useState(false);
  const [hasKidneyIssue, setHasKidneyIssue] = useState(false);
  const [hasLiverIssue, setHasLiverIssue] = useState(false);

  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen) {
        if (symptomToEdit) {
            setSymptom(symptomToEdit.symptom);
            setSeverity(symptomToEdit.severity);
            setNotes(symptomToEdit.notes || '');
            setIsReported(symptomToEdit.isReported || false);
            setSelectedMedId(symptomToEdit.relatedMedicationId || '');
            
            // Load conditions
            setHasAllergy(symptomToEdit.patientConditions?.hasAllergy || false);
            setIsSmoker(symptomToEdit.patientConditions?.isSmoker || false);
            setHasKidneyIssue(symptomToEdit.patientConditions?.hasKidneyIssue || false);
            setHasLiverIssue(symptomToEdit.patientConditions?.hasLiverIssue || false);
        } else {
            setSymptom('');
            setSeverity('متوسط');
            setNotes('');
            setIsReported(false); // Default to private
            setSelectedMedId('');
            setHasAllergy(false);
            setIsSmoker(false);
            setHasKidneyIssue(false);
            setHasLiverIssue(false);
        }
        setError('');
    }
  }, [isOpen, symptomToEdit]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!symptom.trim()) {
      setError('الرجاء إدخال وصف العرض.');
      return;
    }
    setError('');
    onSave({ 
        symptom, 
        severity, 
        notes,
        isReported,
        relatedMedicationId: selectedMedId || undefined,
        patientConditions: {
            hasAllergy,
            isSmoker,
            hasKidneyIssue,
            hasLiverIssue
        }
    });
  };

  const handleClose = () => {
    onClose();
  };

  if (!isOpen) return null;

  const title = symptomToEdit ? 'تعديل العرض المسجل' : 'تسجيل عرض جديد';

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-md transform transition-all animate-fade-in-up max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">{title}</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="symptom-name" className="block text-gray-700 text-sm font-bold mb-2">
              العرض
            </label>
            <input
              type="text"
              id="symptom-name"
              value={symptom}
              onChange={(e) => setSymptom(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]"
              required
              placeholder="مثال: صداع، غثيان، ألم في المفاصل..."
            />
            {error && <p className="text-red-500 text-xs italic mt-2">{error}</p>}
          </div>

          <div className="mb-4 bg-gray-50 p-3 rounded-lg border border-gray-100">
            <label htmlFor="related-med" className="block text-gray-700 text-sm font-bold mb-2 flex items-center gap-2">
                <PillIcon className="w-5 h-5 text-[#5fb8a8]" />
                الدواء المحتمل المسبب (اختياري)
            </label>
            <div className="relative">
                <select
                    id="related-med"
                    value={selectedMedId}
                    onChange={(e) => setSelectedMedId(e.target.value)}
                    className="appearance-none shadow-sm border border-[#c3e7e2] bg-white rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8] pr-8"
                >
                    <option value="">-- اختر من قائمة أدويتك --</option>
                    {medications.map(med => (
                        <option key={med.id} value={med.id}>{med.name} ({med.dosage})</option>
                    ))}
                </select>
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center px-2 text-gray-700">
                  <svg className="fill-current h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z"/></svg>
                </div>
            </div>
            <p className="text-xs text-gray-500 mt-1">إذا كنت تشك أن العرض بسبب أحد أدويتك، اختره هنا.</p>
          </div>
          
          <div className="mb-4">
            <label className="block text-gray-700 text-sm font-bold mb-2">الشدة</label>
            <div className="flex justify-around rounded-lg shadow-sm" role="group">
              {(['خفيف', 'متوسط', 'شديد'] as const).map((level) => (
                <button
                  key={level}
                  type="button"
                  onClick={() => setSeverity(level)}
                  className={`w-full py-2 px-4 text-sm font-medium border-y border-s first:rounded-s-lg last:rounded-e-lg last:border-e transition-colors duration-200 focus:z-10 focus:ring-2 focus:ring-[#5fb8a8]
                    ${severity === level 
                      ? 'bg-[#5fb8a8] text-white border-[#5fb8a8]' 
                      : 'bg-white text-gray-900 hover:bg-gray-100 border-gray-200'}`}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>

          {/* Risk Factors Section */}
          <div className="mb-4 bg-blue-50 p-3 rounded-lg border border-blue-100">
             <div className="flex items-center gap-2 mb-3">
                <UserIcon className="w-5 h-5 text-blue-600" />
                <label className="text-gray-700 text-sm font-bold">
                    حالات صحية / عوامل خطورة
                </label>
             </div>
             <div className="grid grid-cols-2 gap-3">
                <label className="flex items-center space-x-2 space-x-reverse cursor-pointer bg-white p-2 rounded border border-blue-100 hover:border-blue-300 transition-colors">
                    <input type="checkbox" checked={hasAllergy} onChange={(e) => setHasAllergy(e.target.checked)} className="form-checkbox text-blue-600 rounded focus:ring-blue-500 h-4 w-4" />
                    <span className="text-sm text-gray-700">لديه حساسية</span>
                </label>
                <label className="flex items-center space-x-2 space-x-reverse cursor-pointer bg-white p-2 rounded border border-blue-100 hover:border-blue-300 transition-colors">
                    <input type="checkbox" checked={isSmoker} onChange={(e) => setIsSmoker(e.target.checked)} className="form-checkbox text-blue-600 rounded focus:ring-blue-500 h-4 w-4" />
                    <span className="text-sm text-gray-700">مدخن</span>
                </label>
                <label className="flex items-center space-x-2 space-x-reverse cursor-pointer bg-white p-2 rounded border border-blue-100 hover:border-blue-300 transition-colors">
                    <input type="checkbox" checked={hasKidneyIssue} onChange={(e) => setHasKidneyIssue(e.target.checked)} className="form-checkbox text-blue-600 rounded focus:ring-blue-500 h-4 w-4" />
                    <span className="text-sm text-gray-700">أمراض الكلى</span>
                </label>
                <label className="flex items-center space-x-2 space-x-reverse cursor-pointer bg-white p-2 rounded border border-blue-100 hover:border-blue-300 transition-colors">
                    <input type="checkbox" checked={hasLiverIssue} onChange={(e) => setHasLiverIssue(e.target.checked)} className="form-checkbox text-blue-600 rounded focus:ring-blue-500 h-4 w-4" />
                    <span className="text-sm text-gray-700">أمراض الكبد</span>
                </label>
             </div>
          </div>

          <div className="mb-4">
            <label htmlFor="symptom-notes" className="block text-gray-700 text-sm font-bold mb-2">
              ملاحظات إضافية
            </label>
            <textarea
              id="symptom-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8] h-20"
              placeholder="وصف إضافي للحالة..."
            />
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 text-sm font-bold mb-3">خيارات المشاركة والخصوصية</label>
            <div className="space-y-3">
                {/* Option 1: Report */}
                <label className={`flex items-start p-3 border rounded-lg cursor-pointer transition-all duration-200 ${isReported ? 'bg-orange-50 border-orange-300 ring-1 ring-orange-300' : 'bg-white border-gray-200 hover:border-gray-300'}`}>
                    <input 
                        type="radio" 
                        name="reportOption" 
                        checked={isReported === true} 
                        onChange={() => setIsReported(true)} 
                        className="mt-1 h-4 w-4 text-orange-600 focus:ring-orange-500 border-gray-300"
                    />
                    <div className="ms-3">
                        <span className="block text-gray-900 font-bold text-sm">إبلاغ الجهات الطبية</span>
                        <span className="block text-xs text-gray-600 mt-1">لزيادة سلامة استخدام الدواء والمساهمة في رصد الآثار الجانبية.</span>
                    </div>
                </label>

                {/* Option 2: Save Only */}
                <label className={`flex items-start p-3 border rounded-lg cursor-pointer transition-all duration-200 ${!isReported ? 'bg-green-50 border-green-300 ring-1 ring-green-300' : 'bg-white border-gray-200 hover:border-gray-300'}`}>
                    <input 
                        type="radio" 
                        name="reportOption" 
                        checked={isReported === false} 
                        onChange={() => setIsReported(false)} 
                        className="mt-1 h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300"
                    />
                    <div className="ms-3">
                        <span className="block text-gray-900 font-bold text-sm">أود حفظها لدي فقط</span>
                        <span className="block text-xs text-gray-600 mt-1">حفظ في سجلي الشخصي فقط دون مشاركة.</span>
                    </div>
                </label>
            </div>
          </div>

          <div className="flex items-center justify-between">
            <button
              type="submit"
              className="bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 transition-colors duration-300"
            >
              حفظ
            </button>
            <button
              type="button"
              onClick={handleClose}
              className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 ms-3 transition-colors duration-300"
            >
              إلغاء
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SymptomFormModal;

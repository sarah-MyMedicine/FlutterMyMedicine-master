
import React, { useState, useEffect } from 'react';
import { BloodPressureLog } from '../types';

interface BloodPressureFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (reading: { systolic: number; diastolic: number; pulse?: number; notes?: string }) => void;
  readingToEdit?: BloodPressureLog | null;
}

const BloodPressureFormModal: React.FC<BloodPressureFormModalProps> = ({ isOpen, onClose, onSave, readingToEdit }) => {
  const [systolic, setSystolic] = useState('');
  const [diastolic, setDiastolic] = useState('');
  const [pulse, setPulse] = useState('');
  const [notes, setNotes] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen) {
        if (readingToEdit) {
            setSystolic(readingToEdit.systolic.toString());
            setDiastolic(readingToEdit.diastolic.toString());
            setPulse(readingToEdit.pulse ? readingToEdit.pulse.toString() : '');
            setNotes(readingToEdit.notes || '');
        } else {
            setSystolic('');
            setDiastolic('');
            setPulse('');
            setNotes('');
        }
        setError('');
    }
  }, [isOpen, readingToEdit]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const sys = Number(systolic);
    const dia = Number(diastolic);
    const pul = pulse ? Number(pulse) : undefined;

    if (!systolic || !diastolic || isNaN(sys) || isNaN(dia) || sys <= 0 || dia <= 0) {
      setError('الرجاء إدخال قيم صحيحة للضغط.');
      return;
    }
    if (sys < dia) {
        setError('القيمة الانقباضية (العليا) يجب أن تكون أكبر من الانبساطية (السفلى).');
        return;
    }

    setError('');
    onSave({ systolic: sys, diastolic: dia, pulse: pul, notes });
  };

  const handleClose = () => {
    setSystolic('');
    setDiastolic('');
    setPulse('');
    setNotes('');
    setError('');
    onClose();
  };

  if (!isOpen) return null;

  const title = readingToEdit ? 'تعديل قراءة الضغط' : 'إضافة قراءة ضغط الدم';

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-sm transform transition-all animate-fade-in-up">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">{title}</h2>
        <form onSubmit={handleSubmit}>
          <div className="flex gap-4 mb-4">
              <div className="flex-1">
                <label htmlFor="sys-value" className="block text-gray-700 text-sm font-bold mb-2">
                  الانقباضي (SYS)
                </label>
                <input
                  type="number"
                  id="sys-value"
                  value={systolic}
                  onChange={(e) => setSystolic(e.target.value)}
                  className="shadow-sm appearance-none border border-red-100 bg-red-50 rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-red-400"
                  required
                  placeholder="120"
                />
              </div>
              <div className="flex-1">
                <label htmlFor="dia-value" className="block text-gray-700 text-sm font-bold mb-2">
                  الانبساطي (DIA)
                </label>
                <input
                  type="number"
                  id="dia-value"
                  value={diastolic}
                  onChange={(e) => setDiastolic(e.target.value)}
                  className="shadow-sm appearance-none border border-blue-100 bg-blue-50 rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-400"
                  required
                  placeholder="80"
                />
              </div>
          </div>
          
          <div className="mb-4">
            <label htmlFor="pulse-value" className="block text-gray-700 text-sm font-bold mb-2">
              النبض (Pulse) - اختياري
            </label>
            <input
              type="number"
              id="pulse-value"
              value={pulse}
              onChange={(e) => setPulse(e.target.value)}
              className="shadow-sm appearance-none border border-gray-200 bg-gray-50 rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]"
              placeholder="75"
            />
          </div>

          {error && <p className="text-red-500 text-xs italic mb-4">{error}</p>}

          <div className="mb-6">
            <label htmlFor="bp-notes" className="block text-gray-700 text-sm font-bold mb-2">
              ملاحظات (اختياري)
            </label>
            <input
              type="text"
              id="bp-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]"
              placeholder="مثال: بعد الاستيقاظ"
            />
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

export default BloodPressureFormModal;

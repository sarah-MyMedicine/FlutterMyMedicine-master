import React, { useState } from 'react';

interface BloodSugarFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (reading: { value: number; notes?: string }) => void;
}

const BloodSugarFormModal: React.FC<BloodSugarFormModalProps> = ({ isOpen, onClose, onSave }) => {
  const [value, setValue] = useState('');
  const [notes, setNotes] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const numericValue = Number(value);
    if (!value || isNaN(numericValue) || numericValue <= 0) {
      setError('الرجاء إدخال قيمة رقمية صحيحة.');
      return;
    }
    setError('');
    onSave({ value: numericValue, notes });
    // Reset form for next time
    setValue('');
    setNotes('');
  };

  const handleClose = () => {
    // Reset form state on close
    setValue('');
    setNotes('');
    setError('');
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-sm transform transition-all animate-fade-in-up">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">إضافة قراءة سكر الدم</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="bs-value" className="block text-gray-700 text-sm font-bold mb-2">
              قيمة القراءة (ملغ/ديسيلتر)
            </label>
            <input
              type="number"
              id="bs-value"
              value={value}
              onChange={(e) => setValue(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]"
              required
              placeholder="مثال: 120"
            />
            {error && <p className="text-red-500 text-xs italic mt-2">{error}</p>}
          </div>
          <div className="mb-6">
            <label htmlFor="bs-notes" className="block text-gray-700 text-sm font-bold mb-2">
              ملاحظات (اختياري)
            </label>
            <input
              type="text"
              id="bs-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]"
              placeholder="مثال: صائم، بعد الأكل بساعتين"
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

export default BloodSugarFormModal;
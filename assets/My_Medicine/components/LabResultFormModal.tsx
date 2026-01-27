
import React, { useState, useEffect } from 'react';
import { LabResult } from '../types';
import { CameraIcon, TrashIcon, PlusIcon } from './icons';

interface LabResultFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: { title: string; notes: string }) => void;
  images: string[];
  onAddImage: () => void;
  onRemoveImage: (index: number) => void;
  labResultToEdit?: LabResult | null;
}

const LabResultFormModal: React.FC<LabResultFormModalProps> = ({ 
    isOpen, 
    onClose, 
    onSave, 
    images, 
    onAddImage, 
    onRemoveImage, 
    labResultToEdit 
}) => {
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (isOpen) {
        if (labResultToEdit) {
            setTitle(labResultToEdit.title || '');
            setNotes(labResultToEdit.notes || '');
        } else {
            setTitle('');
            setNotes('');
        }
    }
  }, [isOpen, labResultToEdit]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({ title, notes });
    setTitle('');
    setNotes('');
  };

  if (!isOpen) return null;

  const modalTitle = labResultToEdit ? 'تعديل النتيجة' : 'حفظ النتيجة';

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-sm transform transition-all animate-fade-in-up max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4 text-gray-800 text-center">{modalTitle}</h2>
        
        {/* Images Grid */}
        <div className="mb-4">
            <div className="grid grid-cols-2 gap-2 mb-2">
                {images.map((imgSrc, index) => (
                    <div key={index} className="relative h-24 bg-gray-100 rounded-lg overflow-hidden border border-gray-200 group">
                        <img src={imgSrc} alt={`Result ${index + 1}`} className="w-full h-full object-cover" />
                        <button 
                            type="button"
                            onClick={() => onRemoveImage(index)}
                            className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 shadow-sm opacity-90 hover:opacity-100"
                            title="حذف الصورة"
                        >
                            <TrashIcon className="w-4 h-4" />
                        </button>
                    </div>
                ))}
                
                {/* Add Image Button */}
                <button
                    type="button"
                    onClick={onAddImage}
                    className="h-24 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300 flex flex-col items-center justify-center text-gray-500 hover:bg-gray-100 hover:border-[#5fb8a8] hover:text-[#5fb8a8] transition-colors"
                >
                    <PlusIcon className="w-6 h-6 mb-1" />
                    <span className="text-xs font-bold">إضافة صورة</span>
                </button>
            </div>
            {images.length === 0 && (
                <p className="text-red-500 text-xs text-center mt-1">يجب إضافة صورة واحدة على الأقل</p>
            )}
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="lab-title" className="block text-gray-700 text-sm font-bold mb-2">
              عنوان التحليل (اختياري)
            </label>
            <input
              type="text"
              id="lab-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]"
              placeholder="مثال: تحليل دم شامل"
            />
          </div>
          <div className="mb-6">
            <label htmlFor="lab-notes" className="block text-gray-700 text-sm font-bold mb-2">
              ملاحظات (اختياري)
            </label>
            <textarea
              id="lab-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8] h-20"
              placeholder="ملاحظات حول النتيجة..."
            />
          </div>
          <div className="flex items-center justify-between">
            <button
              type="submit"
              disabled={images.length === 0}
              className={`font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 transition-colors duration-300 ${images.length === 0 ? 'bg-gray-400 cursor-not-allowed text-white' : 'bg-[#5fb8a8] hover:bg-[#4a9184] text-white'}`}
            >
              حفظ
            </button>
            <button
              type="button"
              onClick={onClose}
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

export default LabResultFormModal;


import React from 'react';
import { CameraIcon, PencilIcon, PillIcon } from './icons';
import { UserProfile } from '../types';

interface AddOptionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddManually: () => void;
  onAddWithPhoto: () => void;
  onAddBirthControl: () => void;
  userProfile: UserProfile;
}

const AddOptionModal: React.FC<AddOptionModalProps> = ({ isOpen, onClose, onAddManually, onAddWithPhoto, onAddBirthControl, userProfile }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4" onClick={onClose}>
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-sm transform transition-all animate-fade-in-up" onClick={(e) => e.stopPropagation()}>
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">إضافة دواء</h2>
        <div className="space-y-4">
          <button
            onClick={onAddManually}
            className="w-full flex items-center justify-center gap-3 bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition-colors duration-300 text-lg"
          >
            <PencilIcon className="w-6 h-6" />
            <span>إضافة يدوياً</span>
          </button>
          
          {userProfile.gender === 'أنثى' && !userProfile.isPregnant && (
             <button
                onClick={onAddBirthControl}
                className="w-full flex items-center justify-center gap-3 bg-pink-500 hover:bg-pink-700 text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition-colors duration-300 text-lg"
             >
                <PillIcon className="w-6 h-6" />
                <span>حبوب منع الحمل</span>
             </button>
          )}

          <button
            onClick={onAddWithPhoto}
            className="w-full flex items-center justify-center gap-3 bg-sky-500 hover:bg-sky-700 text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition-colors duration-300 text-lg"
          >
            <CameraIcon className="w-6 h-6" />
            <span>إضافة بصورة</span>
          </button>
        </div>
        <div className="mt-6 text-center">
            <button type="button" onClick={onClose} className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-6 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300">
              إغلاق
            </button>
        </div>
      </div>
    </div>
  );
};

export default AddOptionModal;

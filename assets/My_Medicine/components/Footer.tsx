

import React from 'react';
import { UserIcon, PlusIcon } from './icons';

interface FooterProps {
  activeView: 'home' | 'medications' | 'log' | 'bloodSugar' | 'symptoms' | 'pregnancy' | 'bloodPressure' | 'labResults' | 'menopause' | 'puberty' | 'shop' | 'appointments';
  onNavigate: (view: 'home' | 'medications' | 'log' | 'bloodSugar' | 'symptoms' | 'pregnancy' | 'bloodPressure' | 'labResults' | 'menopause' | 'puberty' | 'shop' | 'appointments') => void;
  onAddMedication: () => void;
  onProfileClick: () => void;
}

const Footer: React.FC<FooterProps> = ({ onAddMedication, onProfileClick }) => {
  return (
    <footer className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 shadow-[0_-4px_20px_rgba(0,0,0,0.05)] z-40 pb-safe">
      <nav className="flex items-center justify-between h-16 w-full max-w-lg mx-auto px-6">
        
        <div className="flex-1 flex justify-start">
             {/* Left side spacer */}
        </div>

        <button
            onClick={onAddMedication}
            className="flex flex-col items-center justify-center relative group -top-5"
            aria-label="إضافة دواء"
        >
            <div className="bg-[#5fb8a8] text-white w-16 h-16 rounded-full shadow-xl shadow-[#5fb8a8]/40 flex items-center justify-center border-[4px] border-white transform transition-transform group-hover:scale-105">
                <PlusIcon className="w-8 h-8" />
            </div>
            <span className="text-xs font-bold text-[#5fb8a8] mt-1">إضافة دواء</span>
        </button>

        <div className="flex-1 flex justify-end">
             <button
              onClick={onProfileClick}
              className="flex flex-col items-center justify-center space-y-1 text-gray-400 hover:text-gray-600"
              aria-label="الإعدادات"
            >
              <UserIcon className="w-6 h-6" />
              <span className="text-[10px] font-medium">الإعدادات</span>
            </button>
        </div>

      </nav>
    </footer>
  );
};

export default Footer;
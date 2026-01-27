
import React from 'react';
import { CapsuleIcon, SparklesIcon } from './icons';

const PharmacistBanner: React.FC = () => {
  return (
    <div className="bg-gradient-to-r from-teal-600 to-[#5fb8a8] rounded-xl p-3 mb-4 shadow-md text-white relative overflow-hidden animate-fade-in">
       {/* Decorative background elements */}
       <div className="absolute top-0 right-0 -mt-2 -mr-2 bg-white opacity-10 rounded-full w-20 h-20 blur-xl"></div>
       <div className="absolute bottom-0 left-0 -mb-2 -ml-2 bg-black opacity-10 rounded-full w-16 h-16 blur-xl"></div>

       <div className="flex items-center gap-3 relative z-0">
         <div className="bg-white/20 p-2 rounded-full backdrop-blur-sm shrink-0">
            <CapsuleIcon className="w-5 h-5 text-white" />
         </div>
         <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
                <span className="bg-yellow-400 text-teal-900 text-[10px] font-bold px-1.5 py-0.5 rounded-full flex items-center gap-0.5 shadow-sm">
                    <SparklesIcon className="w-2.5 h-2.5" />
                    قريباً
                </span>
                <h3 className="font-bold text-sm">استشارة صيدلي</h3>
            </div>
            <p className="text-xs opacity-95 leading-snug font-medium">
               مراجعة شاملة لملفك الطبي وجرعاتك على يد صيادلة متخصصين لضمان علاج آمن وفعال.
            </p>
         </div>
       </div>
    </div>
  );
};

export default PharmacistBanner;

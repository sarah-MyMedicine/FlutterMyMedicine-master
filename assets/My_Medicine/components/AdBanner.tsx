
import React, { useState } from 'react';
import { SparklesIcon } from './icons';

interface AdBannerProps {
  onNavigateToProduct?: () => void;
}

const AdBanner: React.FC<AdBannerProps> = ({ onNavigateToProduct }) => {
  const [isVisible, setIsVisible] = useState(true);

  if (!isVisible) {
    return null;
  }

  return (
    <div className="relative bg-gradient-to-br from-purple-100 to-pink-100 rounded-xl shadow-md p-4 mt-8" role="region" aria-label="إعلان">
      <button 
        onClick={() => setIsVisible(false)}
        className="absolute top-2 left-2 text-purple-600 hover:text-purple-800"
        aria-label="إغلاق الإعلان"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-5 h-5">
          <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>

      <div className="flex items-center gap-4">
        <div className="text-purple-500">
          <SparklesIcon className="w-12 h-12" />
        </div>
        <div className="flex-1">
          <p className="text-xs text-purple-700 font-semibold">إعلان</p>
          <p className="font-bold text-purple-800">
            اكتشفي Giniwa: الحل الأمثل لصحة المرأة ومنع الالتهابات المتكررة.
          </p>
        </div>
        <button
          onClick={onNavigateToProduct}
          className="bg-purple-500 hover:bg-purple-600 text-white font-bold py-2 px-4 rounded-full text-sm whitespace-nowrap transition-colors duration-300"
        >
          اعرفي المزيد
        </button>
      </div>
    </div>
  );
};

export default AdBanner;

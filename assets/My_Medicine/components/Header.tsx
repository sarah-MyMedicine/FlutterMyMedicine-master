

import React, { useState, useEffect } from 'react';
import { BellIcon, ArrowRightIcon, MapPinIcon, CapsuleIcon, MagnifyingGlassIcon, XMarkIcon } from './icons';

interface HeaderProps {
    activeView: 'home' | 'medications' | 'log' | 'bloodSugar' | 'symptoms' | 'pregnancy' | 'bloodPressure' | 'labResults' | 'menopause' | 'puberty' | 'shop' | 'appointments';
    onNavigate: (view: 'home' | 'medications' | 'log' | 'bloodSugar' | 'symptoms' | 'pregnancy' | 'bloodPressure' | 'labResults' | 'menopause' | 'puberty' | 'shop' | 'appointments') => void;
    userName?: string;
    onSearch?: (query: string) => void;
    searchQuery?: string;
}

const viewTitles: Record<HeaderProps['activeView'], string> = {
    home: 'دوائي',
    medications: 'أدويتي',
    log: 'سجل الالتزام',
    bloodSugar: 'سجل سكري الدم',
    bloodPressure: 'سجل ضغط الدم',
    symptoms: 'سجل الأعراض',
    pregnancy: 'رعاية الأم والجنين',
    labResults: 'نتائجي المختبرية',
    menopause: 'مرحلة سن الأمل',
    puberty: 'مرحلة البلوغ',
    shop: 'المتجر الصحي',
    appointments: 'مواعيدي الطبية'
};


const Header: React.FC<HeaderProps> = ({ activeView, onNavigate, userName, onSearch, searchQuery }) => {
  const [isSearchActive, setIsSearchActive] = useState(false);
  const title = viewTitles[activeView];
  
  // Close search when view changes
  useEffect(() => {
    setIsSearchActive(false);
  }, [activeView]);

  return (
    <header className="bg-[#5fb8a8] text-white shadow-md sticky top-0 z-10 transition-all duration-300">
      <div className="container mx-auto px-4 py-4 flex justify-between items-center h-[72px]">
        {/* Left side in LTR, which is RIGHT side in RTL screen */}
        <div className="flex items-center gap-2">
           <button onClick={() => window.open('https://maps.google.com/?q=صيدلية', '_blank')} className="p-2 rounded-full hover:bg-[#52a396] transition-colors duration-200" title="أقرب صيدلية">
             <MapPinIcon className="w-6 h-6" />
           </button>
           <button 
             onClick={() => alert('قريباً: استشارة على يد صيادلة متخصصين لتعديل مواعيد الجرعات الموصوفة من قبل الطبيب ومراجعة الملف الطبي كامل للتخلص من الأعراض الجانبية والحصول على علاج آمن وفعال.')} 
             className="p-2 rounded-full hover:bg-[#52a396] transition-colors duration-200" 
             title="استشارة صيدلي (قريباً)"
           >
             <CapsuleIcon className="w-6 h-6" />
           </button>
        </div>
        
        {/* Right side in LTR, which is LEFT side in RTL screen */}
         <div className="flex items-center gap-3 flex-1 justify-end">
          {activeView === 'home' ? (
             <>
              <h1 className="text-2xl font-bold">{title}</h1>
              <BellIcon className="w-7 h-7"/>
            </>
          ) : (
             <>
                {isSearchActive ? (
                   <div className="flex items-center gap-2 w-full max-w-[200px] sm:max-w-xs animate-fade-in bg-white/10 rounded-lg px-2">
                       <input 
                         type="text" 
                         autoFocus
                         placeholder="بحث..."
                         className="bg-transparent border-none text-white placeholder-white/70 focus:outline-none w-full py-1"
                         value={searchQuery || ''}
                         onChange={(e) => onSearch && onSearch(e.target.value)}
                       />
                       <button onClick={() => { setIsSearchActive(false); onSearch && onSearch(''); }} className="text-white/80 hover:text-white">
                           <XMarkIcon className="w-5 h-5" />
                       </button>
                   </div>
                ) : (
                    <>
                         {/* Search Icon Trigger */}
                        {onSearch && activeView === 'medications' && (
                            <button 
                                onClick={() => setIsSearchActive(true)} 
                                className="p-2 rounded-full hover:bg-[#52a396] transition-colors duration-200"
                            >
                                <MagnifyingGlassIcon className="w-6 h-6" />
                            </button>
                        )}
                        
                        <h1 className="text-2xl font-bold whitespace-nowrap">{title}</h1>
                    </>
                )}

                <button onClick={() => onNavigate('home')} className="p-2 -m-2 rounded-full hover:bg-[#52a396] transition-colors duration-200" aria-label="العودة للشاشة الرئيسية">
                    <ArrowRightIcon className="w-7 h-7" />
                </button>
            </>
          )}
        </div>
      </div>
    </header>
  );
};

export default Header;
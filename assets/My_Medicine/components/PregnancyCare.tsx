

import React, { useState, useEffect } from 'react';
import { ColorPregnantIcon, FootprintIcon, StopwatchIcon, ShoppingBagIcon, CheckCircleIcon } from './icons';

const PregnancyCare: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'summary' | 'kicks' | 'timer' | 'bag'>('summary');

  // --- TAB 1: SUMMARY / CALCULATOR LOGIC ---
  const getInitialDatePart = (part: 'day' | 'month' | 'year') => {
    const saved = localStorage.getItem('pregnancy_lmp');
    if (saved) {
       const parts = saved.split('-');
       if (parts.length === 3) {
           if (part === 'day') return parseInt(parts[2]).toString();
           if (part === 'month') return parseInt(parts[1]).toString();
           if (part === 'year') return parts[0];
       }
    }
    return '';
  };

  const [lastPeriodDate, setLastPeriodDate] = useState(() => localStorage.getItem('pregnancy_lmp') || '');
  const [day, setDay] = useState(() => getInitialDatePart('day'));
  const [month, setMonth] = useState(() => getInitialDatePart('month'));
  const [year, setYear] = useState(() => getInitialDatePart('year'));
  
  const [pregnancyInfo, setPregnancyInfo] = useState<{weeks: number, days: number, trimester: number, dueDate: Date} | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (lastPeriodDate) {
      calculatePregnancy(lastPeriodDate);
      localStorage.setItem('pregnancy_lmp', lastPeriodDate);
    } else {
      setPregnancyInfo(null);
      setError(null);
      localStorage.removeItem('pregnancy_lmp');
    }
  }, [lastPeriodDate]);

  const calculatePregnancy = (dateStr: string) => {
    const [yStr, mStr, dStr] = dateStr.split('-');
    const start = new Date(parseInt(yStr), parseInt(mStr) - 1, parseInt(dStr));
    const now = new Date();
    start.setHours(0, 0, 0, 0);
    now.setHours(0, 0, 0, 0);
    
    if (start > now) return;

    const diffTime = now.getTime() - start.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24)); 
    const weeks = Math.floor(diffDays / 7);
    const days = diffDays % 7;
    
    if (weeks > 45) {
        setPregnancyInfo(null);
        setError('التاريخ المدخل قديم جداً. يرجى التحقق من التاريخ.');
        return;
    }
    setError(null);
    const dueDate = new Date(start);
    dueDate.setDate(dueDate.getDate() + 280);

    let trimester = 1;
    if (weeks >= 13 && weeks < 27) trimester = 2;
    if (weeks >= 27) trimester = 3;

    setPregnancyInfo({ weeks, days, trimester, dueDate });
  };

  const handleDatePartChange = (part: 'day' | 'month' | 'year', value: string) => {
      let newDay = part === 'day' ? value : day;
      let newMonth = part === 'month' ? value : month;
      let newYear = part === 'year' ? value : year;

      if (part === 'day') setDay(value);
      if (part === 'month') setMonth(value);
      if (part === 'year') setYear(value);

      if (newDay && newMonth && newYear) {
          const dateStr = `${newYear}-${newMonth.padStart(2, '0')}-${newDay.padStart(2, '0')}`;
          setLastPeriodDate(dateStr);
      }
  };

  const getTrimesterName = (t: number) => t === 1 ? 'الثلث الأول' : (t === 2 ? 'الثلث الثاني' : 'الثلث الثالث');
  const getBabySize = (weeks: number) => {
    if (weeks < 4) return "حبة خشخاش";
    if (weeks < 8) return "حبة توت";
    if (weeks < 12) return "ليمونة";
    if (weeks < 16) return "تفاحة";
    if (weeks < 20) return "موزة";
    if (weeks < 24) return "ذرة";
    if (weeks < 28) return "باذنجان";
    if (weeks < 32) return "قرع";
    if (weeks < 36) return "بطيخة صغيرة";
    return "بطيخة كبيرة";
  };
  
  const currentYear = new Date().getFullYear();
  const years = [currentYear, currentYear - 1];
  const daysList = Array.from({length: 31}, (_, i) => i + 1);
  const monthsList = [
      { num: 1, name: 'يناير' }, { num: 2, name: 'فبراير' }, { num: 3, name: 'مارس' }, 
      { num: 4, name: 'أبريل' }, { num: 5, name: 'مايو' }, { num: 6, name: 'يونيو' },
      { num: 7, name: 'يوليو' }, { num: 8, name: 'أغسطس' }, { num: 9, name: 'سبتمبر' },
      { num: 10, name: 'أكتوبر' }, { num: 11, name: 'نوفمبر' }, { num: 12, name: 'ديسمبر' }
  ];

  // --- TAB 2: KICK COUNTER LOGIC ---
  const [kickCount, setKickCount] = useState(0);
  const [kickStartTime, setKickStartTime] = useState<Date | null>(null);

  const handleKick = () => {
      if (kickCount === 0) setKickStartTime(new Date());
      setKickCount(prev => prev + 1);
  };
  
  const resetKicks = () => {
      setKickCount(0);
      setKickStartTime(null);
  };

  // --- TAB 3: CONTRACTION TIMER LOGIC ---
  const [contractions, setContractions] = useState<{start: Date, end: Date, duration: number, interval?: number}[]>([]);
  const [isTiming, setIsTiming] = useState(false);
  const [currentStartTime, setCurrentStartTime] = useState<Date | null>(null);

  const toggleTimer = () => {
      if (isTiming) {
          // Stop
          if (currentStartTime) {
              const now = new Date();
              const duration = Math.floor((now.getTime() - currentStartTime.getTime()) / 1000); // seconds
              
              let interval = undefined;
              if (contractions.length > 0) {
                  const lastStart = contractions[0].start;
                  interval = Math.floor((currentStartTime.getTime() - lastStart.getTime()) / 1000 / 60); // minutes
              }

              setContractions([{ start: currentStartTime, end: now, duration, interval }, ...contractions]);
          }
          setIsTiming(false);
          setCurrentStartTime(null);
      } else {
          // Start
          setCurrentStartTime(new Date());
          setIsTiming(true);
      }
  };

  const formatDuration = (seconds: number) => {
      const min = Math.floor(seconds / 60);
      const sec = seconds % 60;
      return `${min}د ${sec}ث`;
  };

  // --- TAB 4: HOSPITAL BAG LOGIC ---
  const initialBagItems = {
      mom: [
          { id: 'm1', label: 'روب نوم مريح (يفضل للرضاعة)', checked: false },
          { id: 'm2', label: 'ملابس داخلية قطنية', checked: false },
          { id: 'm3', label: 'فوط صحية (حجم كبير)', checked: false },
          { id: 'm4', label: 'حمالات صدر للرضاعة', checked: false },
          { id: 'm5', label: 'أدوات العناية الشخصية (فرشاة، شامبو...)', checked: false },
          { id: 'm6', label: 'ملابس للخروج من المستشفى', checked: false },
      ],
      baby: [
          { id: 'b1', label: 'ملابس داخلية (اوفر) عدد 3', checked: false },
          { id: 'b2', label: 'أطقم خارجية كاملة عدد 3', checked: false },
          { id: 'b3', label: 'قبعات وجوارب وقفازات', checked: false },
          { id: 'b4', label: 'بطانية ناعمة', checked: false },
          { id: 'b5', label: 'حفاضات مقاس مولود جديد', checked: false },
          { id: 'b6', label: 'مناديل مبللة (Wipes)', checked: false },
      ],
      docs: [
          { id: 'd1', label: 'بطاقة الهوية / الإقامة', checked: false },
          { id: 'd2', label: 'بطاقة التأمين', checked: false },
          { id: 'd3', label: 'ملف متابعة الحمل والتحاليل', checked: false },
      ]
  };

  const [bagItems, setBagItems] = useState(() => {
      const saved = localStorage.getItem('hospital_bag');
      return saved ? JSON.parse(saved) : initialBagItems;
  });

  useEffect(() => {
      localStorage.setItem('hospital_bag', JSON.stringify(bagItems));
  }, [bagItems]);

  const toggleBagItem = (category: 'mom' | 'baby' | 'docs', id: string) => {
      setBagItems((prev: any) => ({
          ...prev,
          [category]: prev[category].map((item: any) => 
              item.id === id ? { ...item, checked: !item.checked } : item
          )
      }));
  };

  return (
    <div className="animate-fade-in pb-20">
        {/* Header Section */}
        <div className="bg-gradient-to-br from-pink-400 to-rose-400 rounded-2xl p-6 text-white shadow-lg mb-6 relative overflow-hidden">
             <div className="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full -mt-10 -mr-10"></div>
             <div className="absolute bottom-0 left-0 w-24 h-24 bg-pink-600 opacity-10 rounded-full -mb-8 -ml-8"></div>
             
             <div className="relative z-10 flex items-center justify-between">
                 <div>
                     <h2 className="text-2xl font-bold mb-1">رعاية الأم والجنين</h2>
                     <p className="text-pink-100 text-sm">رفيقك الآمن طوال الرحلة</p>
                 </div>
                 <div className="bg-white/20 p-2 rounded-full backdrop-blur-sm">
                     <ColorPregnantIcon className="w-12 h-12" />
                 </div>
             </div>
             
             {/* Tabs Navigation */}
             <div className="flex bg-white/20 p-1 rounded-xl overflow-x-auto no-scrollbar gap-1 mt-6 backdrop-blur-md">
                 <button 
                     onClick={() => setActiveTab('summary')}
                     className={`flex-1 py-2 px-3 rounded-lg text-xs sm:text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'summary' ? 'bg-white text-pink-600 shadow-md' : 'text-white hover:bg-white/10'}`}
                 >
                     ملخص الحمل
                 </button>
                 <button 
                     onClick={() => setActiveTab('kicks')}
                     className={`flex-1 py-2 px-3 rounded-lg text-xs sm:text-sm font-bold whitespace-nowrap transition-all flex items-center justify-center gap-1 ${activeTab === 'kicks' ? 'bg-white text-pink-600 shadow-md' : 'text-white hover:bg-white/10'}`}
                 >
                     <FootprintIcon className="w-4 h-4" />
                     حركة الجنين
                 </button>
                 <button 
                     onClick={() => setActiveTab('timer')}
                     className={`flex-1 py-2 px-3 rounded-lg text-xs sm:text-sm font-bold whitespace-nowrap transition-all flex items-center justify-center gap-1 ${activeTab === 'timer' ? 'bg-white text-pink-600 shadow-md' : 'text-white hover:bg-white/10'}`}
                 >
                     <StopwatchIcon className="w-4 h-4" />
                     مؤقت الطلق
                 </button>
                 <button 
                     onClick={() => setActiveTab('bag')}
                     className={`flex-1 py-2 px-3 rounded-lg text-xs sm:text-sm font-bold whitespace-nowrap transition-all flex items-center justify-center gap-1 ${activeTab === 'bag' ? 'bg-white text-pink-600 shadow-md' : 'text-white hover:bg-white/10'}`}
                 >
                     <ShoppingBagIcon className="w-4 h-4" />
                     الحقيبة
                 </button>
             </div>
        </div>

        {/* --- SUMMARY TAB --- */}
        {activeTab === 'summary' && (
            <div className="animate-fade-in">
                {!pregnancyInfo ? (
                    <div className="bg-white p-6 rounded-xl shadow-md border border-gray-100">
                    <label className="block text-gray-700 font-bold mb-3 text-center">أدخلي تاريخ أول يوم من آخر دورة شهرية</label>
                    <div className="grid grid-cols-3 gap-2 mb-4">
                            <select value={day} onChange={(e) => handleDatePartChange('day', e.target.value)} className="w-full p-2 rounded-lg border border-pink-200 bg-white text-center">
                                <option value="">اليوم</option>
                                {daysList.map(d => <option key={d} value={d}>{d}</option>)}
                            </select>
                            <select value={month} onChange={(e) => handleDatePartChange('month', e.target.value)} className="w-full p-2 rounded-lg border border-pink-200 bg-white text-center">
                                <option value="">الشهر</option>
                                {monthsList.map(m => <option key={m.num} value={m.num}>{m.name}</option>)}
                            </select>
                            <select value={year} onChange={(e) => handleDatePartChange('year', e.target.value)} className="w-full p-2 rounded-lg border border-pink-200 bg-white text-center">
                                <option value="">السنة</option>
                                {years.map(y => <option key={y} value={y}>{y}</option>)}
                            </select>
                    </div>
                    {error && <div className="p-3 bg-red-100 text-red-700 rounded-lg text-sm text-center mb-2">{error}</div>}
                    <p className="text-xs text-gray-500 text-center">سنقوم بحساب الموعد المتوقع للولادة وعمر الحمل.</p>
                    </div>
                ) : (
                    <div className="space-y-4">
                        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 text-center">
                            <p className="text-gray-500 text-sm">عمر الحمل الحالي</p>
                            <h3 className="text-3xl font-bold text-gray-800 my-2">{pregnancyInfo.weeks} أسبوع <span className="text-lg font-normal text-gray-600">و {pregnancyInfo.days} يوم</span></h3>
                            <span className="inline-block bg-pink-100 text-pink-600 px-3 py-1 rounded-full text-sm font-bold">{getTrimesterName(pregnancyInfo.trimester)}</span>
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex flex-col items-center justify-center text-center">
                                <span className="text-gray-500 text-xs mb-1">موعد الولادة</span>
                                <span className="font-bold text-pink-600 text-md">
                                {new Intl.DateTimeFormat('ar-EG', { day: 'numeric', month: 'long', year: 'numeric' }).format(pregnancyInfo.dueDate)}
                                </span>
                            </div>
                            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex flex-col items-center justify-center text-center">
                                <span className="text-gray-500 text-xs mb-1">حجم الطفل</span>
                                <span className="font-bold text-purple-600 text-md">{getBabySize(pregnancyInfo.weeks)}</span>
                            </div>
                        </div>
                        <button onClick={() => {setPregnancyInfo(null); setLastPeriodDate(''); setDay(''); setMonth(''); setYear('');}} className="w-full text-center text-sm text-gray-400 hover:text-pink-500 mt-2">إعادة حساب التاريخ</button>
                    </div>
                )}
            </div>
        )}

        {/* --- KICK COUNTER TAB --- */}
        {activeTab === 'kicks' && (
            <div className="animate-fade-in space-y-4">
                <div className="bg-white rounded-xl shadow-md p-6 text-center border border-gray-100">
                    <h3 className="font-bold text-gray-700 mb-2">عداد ركلات الجنين</h3>
                    <p className="text-xs text-gray-500 mb-6">يوصى بحساب 10 ركلات خلال ساعتين في الثلث الثالث</p>
                    
                    <div className="relative w-40 h-40 mx-auto flex items-center justify-center mb-6">
                        <div className="absolute inset-0 bg-pink-50 rounded-full animate-pulse"></div>
                        <div className="relative z-10 flex flex-col items-center">
                            <span className="text-5xl font-bold text-pink-600">{kickCount}</span>
                            <span className="text-xs text-gray-500 mt-1">ركلات اليوم</span>
                        </div>
                    </div>

                    <button 
                        onClick={handleKick}
                        className="w-full bg-pink-500 hover:bg-pink-600 text-white font-bold py-4 rounded-2xl shadow-lg transform active:scale-95 transition-all flex items-center justify-center gap-3 text-lg"
                    >
                        <FootprintIcon className="w-8 h-8" />
                        سجلي ركلة!
                    </button>
                    
                    {kickStartTime && (
                        <div className="mt-4 text-sm text-gray-500 bg-gray-50 p-2 rounded-lg">
                            بدأ العد: {kickStartTime.toLocaleTimeString('ar-EG', {hour: '2-digit', minute:'2-digit'})}
                        </div>
                    )}
                </div>
                
                <div className="flex justify-center">
                    <button onClick={resetKicks} className="text-sm text-gray-400 hover:text-red-500 flex items-center gap-1">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-4 h-4">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" />
                        </svg>
                        تصفير العداد
                    </button>
                </div>
            </div>
        )}

        {/* --- CONTRACTION TIMER TAB --- */}
        {activeTab === 'timer' && (
            <div className="animate-fade-in space-y-4">
                <div className="bg-white rounded-xl shadow-md p-6 text-center border border-gray-100">
                     <h3 className="font-bold text-gray-700 mb-6">مؤقت انقباضات الولادة (الطلق)</h3>
                     
                     <div className={`w-48 h-48 mx-auto rounded-full border-8 flex flex-col items-center justify-center mb-8 shadow-inner transition-colors duration-500 ${isTiming ? 'border-green-400 bg-green-50' : 'border-gray-100 bg-gray-50'}`}>
                         {isTiming ? (
                             <>
                                <span className="text-green-600 font-bold text-xl animate-pulse">جاري الحساب...</span>
                                <span className="text-xs text-green-700 mt-2">تنفسي بعمق 🌬️</span>
                             </>
                         ) : (
                             <span className="text-gray-400 font-bold">جاهز</span>
                         )}
                     </div>

                     <button 
                        onClick={toggleTimer}
                        className={`w-full py-4 rounded-2xl font-bold text-xl shadow-lg transform active:scale-95 transition-all ${isTiming ? 'bg-red-500 hover:bg-red-600 text-white' : 'bg-green-500 hover:bg-green-600 text-white'}`}
                    >
                        {isTiming ? 'إيقاف الطلق 🛑' : 'بدء الطلق 🟢'}
                    </button>
                </div>

                {contractions.length > 0 && (
                    <div className="bg-white rounded-xl shadow-sm overflow-hidden">
                        <table className="w-full text-sm text-right">
                            <thead className="bg-gray-50 text-gray-600">
                                <tr>
                                    <th className="p-3">الوقت</th>
                                    <th className="p-3">المدة</th>
                                    <th className="p-3">الفاصل</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {contractions.map((c, i) => (
                                    <tr key={i}>
                                        <td className="p-3 font-medium">{c.start.toLocaleTimeString('ar-EG', {hour:'2-digit', minute:'2-digit'})}</td>
                                        <td className="p-3 text-green-600 font-bold">{formatDuration(c.duration)}</td>
                                        <td className="p-3 text-gray-500">{c.interval ? `${c.interval} دقيقة` : '-'}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                        <div className="p-3 bg-gray-50 text-center">
                            <button onClick={() => setContractions([])} className="text-xs text-red-500 hover:underline">مسح السجل</button>
                        </div>
                    </div>
                )}
            </div>
        )}

        {/* --- HOSPITAL BAG TAB --- */}
        {activeTab === 'bag' && (
            <div className="animate-fade-in space-y-4">
                <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 mb-4">
                    <p className="text-blue-800 text-sm font-bold flex items-center gap-2">
                        <CheckCircleIcon className="w-5 h-5" />
                        نصيحة: جهزي حقيبتك في بداية الشهر الثامن.
                    </p>
                </div>

                <div className="space-y-4">
                    {/* Mom Section */}
                    <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-pink-100">
                        <div className="bg-pink-50 p-3 font-bold text-pink-700 flex justify-between items-center">
                            <span>👩 للأم</span>
                            <span className="text-xs bg-white px-2 py-1 rounded-full">{bagItems.mom.filter((i:any) => i.checked).length}/{bagItems.mom.length}</span>
                        </div>
                        <div className="p-2">
                            {bagItems.mom.map((item: any) => (
                                <label key={item.id} className="flex items-center p-3 hover:bg-gray-50 rounded-lg cursor-pointer transition-colors">
                                    <input 
                                        type="checkbox" 
                                        checked={item.checked} 
                                        onChange={() => toggleBagItem('mom', item.id)}
                                        className="w-5 h-5 text-pink-500 rounded border-gray-300 focus:ring-pink-500" 
                                    />
                                    <span className={`mr-3 ${item.checked ? 'text-gray-400 line-through' : 'text-gray-700'}`}>{item.label}</span>
                                </label>
                            ))}
                        </div>
                    </div>

                    {/* Baby Section */}
                    <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-blue-100">
                        <div className="bg-blue-50 p-3 font-bold text-blue-700 flex justify-between items-center">
                            <span>👶 للطفل</span>
                            <span className="text-xs bg-white px-2 py-1 rounded-full">{bagItems.baby.filter((i:any) => i.checked).length}/{bagItems.baby.length}</span>
                        </div>
                        <div className="p-2">
                            {bagItems.baby.map((item: any) => (
                                <label key={item.id} className="flex items-center p-3 hover:bg-gray-50 rounded-lg cursor-pointer transition-colors">
                                    <input 
                                        type="checkbox" 
                                        checked={item.checked} 
                                        onChange={() => toggleBagItem('baby', item.id)}
                                        className="w-5 h-5 text-blue-500 rounded border-gray-300 focus:ring-blue-500" 
                                    />
                                    <span className={`mr-3 ${item.checked ? 'text-gray-400 line-through' : 'text-gray-700'}`}>{item.label}</span>
                                </label>
                            ))}
                        </div>
                    </div>

                    {/* Docs Section */}
                    <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-gray-100">
                        <div className="bg-gray-100 p-3 font-bold text-gray-700 flex justify-between items-center">
                            <span>📄 أوراق ومستندات</span>
                            <span className="text-xs bg-white px-2 py-1 rounded-full">{bagItems.docs.filter((i:any) => i.checked).length}/{bagItems.docs.length}</span>
                        </div>
                        <div className="p-2">
                            {bagItems.docs.map((item: any) => (
                                <label key={item.id} className="flex items-center p-3 hover:bg-gray-50 rounded-lg cursor-pointer transition-colors">
                                    <input 
                                        type="checkbox" 
                                        checked={item.checked} 
                                        onChange={() => toggleBagItem('docs', item.id)}
                                        className="w-5 h-5 text-gray-500 rounded border-gray-300 focus:ring-gray-500" 
                                    />
                                    <span className={`mr-3 ${item.checked ? 'text-gray-400 line-through' : 'text-gray-700'}`}>{item.label}</span>
                                </label>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        )}
    </div>
  );
};

export default PregnancyCare;

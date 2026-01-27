


import React, { useState, useEffect } from 'react';
import { ColorMenopauseIcon, CheckCircleIcon, SparklesIcon, PlusIcon, FaceSmileIcon } from './icons';
import { MenopauseLog } from '../types';

interface MenopauseInfoProps {
    log?: MenopauseLog[];
    onLogUpdate?: (count: number) => void;
}

const MenopauseInfo: React.FC<MenopauseInfoProps> = ({ log = [], onLogUpdate }) => {
  const [activeTab, setActiveTab] = useState<'info' | 'tracker' | 'wellness' | 'diet'>('info');

  const today = new Date().toISOString().split('T')[0];
  const todayCount = log.find(l => l.date === today)?.count || 0;
  
  // Sorting log descending by date
  const sortedLog = [...log].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  const totalFlashes = log.reduce((acc, curr) => acc + curr.count, 0);

  const handleIncrement = () => {
      onLogUpdate && onLogUpdate(todayCount + 1);
  };

  const handleDecrement = () => {
      if (todayCount > 0) {
          onLogUpdate && onLogUpdate(todayCount - 1);
      }
  };

  // BMI State
  const [weight, setWeight] = useState('');
  const [height, setHeight] = useState('');
  const [bmiResult, setBmiResult] = useState<{value: number, status: string, color: string} | null>(null);

  const calculateBMI = () => {
      const w = parseFloat(weight);
      const h = parseFloat(height) / 100; // convert cm to m
      if (w > 0 && h > 0) {
          const bmi = w / (h * h);
          let status = '';
          let color = '';
          if (bmi < 18.5) { status = 'نحافة'; color = 'text-blue-500'; }
          else if (bmi < 24.9) { status = 'وزن مثالي'; color = 'text-green-500'; }
          else if (bmi < 29.9) { status = 'زيادة في الوزن'; color = 'text-orange-500'; }
          else { status = 'سمنة'; color = 'text-red-500'; }
          setBmiResult({ value: parseFloat(bmi.toFixed(1)), status, color });
      }
  };

  // Breathing Exercise State
  const [isBreathingActive, setIsBreathingActive] = useState(false);
  const [breathText, setBreathText] = useState('جاهزة؟');

  useEffect(() => {
    let interval: any;
    if (isBreathingActive) {
        let phase = 0; // 0: Inhale, 1: Hold, 2: Exhale
        setBreathText('شهيق (4 ثوانٍ)');
        
        const cycle = () => {
            if (phase === 0) {
                setBreathText('شهيق... 🌬️');
                setTimeout(() => { phase = 1; cycle(); }, 4000);
            } else if (phase === 1) {
                setBreathText('احبسي النفس... 😶');
                setTimeout(() => { phase = 2; cycle(); }, 7000);
            } else if (phase === 2) {
                setBreathText('زفير ببطء... 😌');
                setTimeout(() => { phase = 0; cycle(); }, 8000);
            }
        };
        cycle();
    } else {
        setBreathText('اضغطي للبدء');
    }
    return () => clearTimeout(interval);
  }, [isBreathingActive]);
  
  const formatDate = (dateString: string) => {
      return new Intl.DateTimeFormat('ar-EG', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
      }).format(new Date(dateString));
  };

  return (
    <div className="animate-fade-in pb-20">
        {/* Header */}
        <div className="bg-gradient-to-br from-purple-100 to-pink-100 rounded-2xl p-6 mb-6 shadow-sm border border-purple-100">
            <div className="flex items-center gap-4 mb-4">
                <div className="bg-white p-3 rounded-full shadow-sm">
                    <ColorMenopauseIcon className="w-12 h-12" />
                </div>
                <div>
                    <h2 className="text-2xl font-bold text-gray-800">مرحلة سن الأمل</h2>
                    <p className="text-purple-600 font-medium">مرحلة العطاء والتجدد</p>
                </div>
            </div>
            
            {/* Navigation Tabs */}
            <div className="flex bg-white/60 p-1 rounded-xl overflow-x-auto no-scrollbar gap-1 mt-4">
                <button 
                    onClick={() => setActiveTab('info')}
                    className={`flex-1 py-2 px-4 rounded-lg text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'info' ? 'bg-purple-500 text-white shadow-md' : 'text-gray-600 hover:bg-white'}`}
                >
                    معلومات وهرمونات
                </button>
                <button 
                    onClick={() => setActiveTab('tracker')}
                    className={`flex-1 py-2 px-4 rounded-lg text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'tracker' ? 'bg-purple-500 text-white shadow-md' : 'text-gray-600 hover:bg-white'}`}
                >
                    متابعة الأعراض
                </button>
                <button 
                    onClick={() => setActiveTab('wellness')}
                    className={`flex-1 py-2 px-4 rounded-lg text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'wellness' ? 'bg-purple-500 text-white shadow-md' : 'text-gray-600 hover:bg-white'}`}
                >
                    صحة وراحة
                </button>
                <button 
                    onClick={() => setActiveTab('diet')}
                    className={`flex-1 py-2 px-4 rounded-lg text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'diet' ? 'bg-purple-500 text-white shadow-md' : 'text-gray-600 hover:bg-white'}`}
                >
                    تغذية
                </button>
            </div>
        </div>

        {/* CONTENT: INFO TAB */}
        {activeTab === 'info' && (
            <div className="animate-fade-in">
                <div className="bg-white rounded-xl shadow-md p-6 mb-6 border-l-4 border-l-purple-500">
                    <h3 className="text-xl font-bold text-purple-700 mb-4 flex items-center gap-2">
                        <span className="text-2xl">💊</span>
                        الهرمونات التعويضية (HRT)
                    </h3>
                    <div className="space-y-4 text-gray-700">
                        <p>
                            العلاج التعويضي بالهرمونات يعتبر خياراً فعالاً للتخفيف من أعراض انقطاع الطمث مثل الهبات الساخنة والتعرق الليلي.
                        </p>
                        
                        <div className="bg-green-50 p-4 rounded-lg border border-green-200">
                            <h4 className="font-bold text-green-800 mb-2 flex items-center gap-2">
                                <CheckCircleIcon className="w-5 h-5" />
                                أمان الاستخدام
                            </h4>
                            <p className="text-sm text-green-900 leading-relaxed">
                                أجازت منظمة الغذاء والدواء (FDA) استخدامها. لا يوجد دليل قاطع يثبت أنها تسبب سرطان الثدي عند استخدامها تحت إشراف طبي وللفترات الموصى بها، وفوائدها في حماية العظام والقلب تفوق مخاطرها.
                            </p>
                        </div>
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="bg-purple-50 p-4 rounded-xl">
                        <h4 className="font-bold text-purple-800 mb-2">الفوائد:</h4>
                        <ul className="list-disc list-inside text-sm text-gray-700 space-y-1">
                            <li>تخفيف الهبات الساخنة.</li>
                            <li>الحماية من هشاشة العظام.</li>
                            <li>تحسين المزاج والنوم.</li>
                        </ul>
                    </div>
                    <div className="bg-blue-50 p-4 rounded-xl">
                        <h4 className="font-bold text-blue-800 mb-2">استشيري طبيبك:</h4>
                        <ul className="list-disc list-inside text-sm text-gray-700 space-y-1">
                            <li>إذا كانت الأعراض تؤثر على حياتك.</li>
                            <li>لتحديد الجرعة المناسبة.</li>
                            <li>إذا كان لديك تاريخ مرضي.</li>
                        </ul>
                    </div>
                </div>
            </div>
        )}

        {/* CONTENT: TRACKER TAB */}
        {activeTab === 'tracker' && (
            <div className="animate-fade-in space-y-6">
                <div className="bg-white rounded-2xl shadow-lg p-6 text-center border border-gray-100">
                    <h3 className="text-lg font-bold text-gray-700 mb-2">عداد الهبات الساخنة (اليوم)</h3>
                    <p className="text-gray-500 text-sm mb-6">سجلي عدد المرات لمناقشتها مع طبيبك</p>
                    
                    <div className="flex items-center justify-center gap-8">
                         <button 
                            onClick={handleDecrement}
                            className="w-12 h-12 bg-gray-100 rounded-full text-2xl text-gray-600 hover:bg-gray-200"
                         >
                             -
                         </button>
                         <div className="text-6xl font-bold text-orange-500">
                             {todayCount}
                         </div>
                         <button 
                            onClick={handleIncrement}
                            className="w-12 h-12 bg-orange-100 rounded-full text-2xl text-orange-600 hover:bg-orange-200 border border-orange-200"
                         >
                             +
                         </button>
                    </div>
                    <div className="mt-6 flex justify-center gap-2">
                        <span className="bg-orange-50 text-orange-700 px-3 py-1 rounded-full text-xs font-bold border border-orange-100">
                            🔥 هبة ساخنة
                        </span>
                        <span className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-xs font-bold border border-blue-100">
                            💧 تعرق ليلي
                        </span>
                    </div>
                </div>

                <div className="bg-white rounded-xl shadow p-5">
                    <h3 className="font-bold text-gray-800 mb-3 text-lg border-b pb-2">سجل الهبات الساخنة</h3>
                    
                    {sortedLog.length > 0 ? (
                        <>
                            <div className="overflow-x-auto">
                                <table className="w-full text-sm text-right text-gray-600">
                                    <thead className="bg-gray-50 text-gray-700 font-bold">
                                        <tr>
                                            <th className="px-4 py-3 rounded-tr-lg">التاريخ</th>
                                            <th className="px-4 py-3 rounded-tl-lg">العدد</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                        {sortedLog.map((entry) => (
                                            <tr key={entry.date} className="hover:bg-gray-50 transition-colors">
                                                <td className="px-4 py-3 font-medium">{formatDate(entry.date)}</td>
                                                <td className="px-4 py-3 font-bold text-orange-600">{entry.count}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                    <tfoot className="bg-orange-50 font-bold text-gray-800 border-t-2 border-orange-200">
                                        <tr>
                                            <td className="px-4 py-3">المجموع الكلي</td>
                                            <td className="px-4 py-3 text-orange-700 text-lg">{totalFlashes}</td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                        </>
                    ) : (
                        <p className="text-center text-gray-500 py-4">لا توجد سجلات سابقة.</p>
                    )}
                </div>

                <div className="bg-white rounded-xl shadow p-5">
                    <h3 className="font-bold text-gray-800 mb-3">نصائح للتعامل مع الهبات الساخنة:</h3>
                    <ul className="space-y-2 text-sm text-gray-600">
                        <li className="flex gap-2">
                            <span>❄️</span>
                            <span>ارتدي ملابس قطنية خفيفة (طبقات يمكن خلعها).</span>
                        </li>
                        <li className="flex gap-2">
                            <span>🧊</span>
                            <span>احتفظي بماء بارد بجانبك دائماً.</span>
                        </li>
                        <li className="flex gap-2">
                            <span>☕</span>
                            <span>قللي من الكافيين والأطعمة الحارة والمشروبات الساخنة.</span>
                        </li>
                    </ul>
                </div>
            </div>
        )}

        {/* CONTENT: WELLNESS TAB */}
        {activeTab === 'wellness' && (
            <div className="animate-fade-in space-y-6">
                
                {/* Breathing Exercise */}
                <div className="bg-gradient-to-b from-sky-50 to-white rounded-2xl shadow-md p-6 text-center border border-sky-100 relative overflow-hidden">
                    <h3 className="text-lg font-bold text-sky-800 mb-1">ركن الاسترخاء</h3>
                    <p className="text-sky-600 text-sm mb-6">تمرين التنفس 4-7-8 لتهدئة الأعصاب</p>
                    
                    <div className="relative h-40 flex items-center justify-center mb-6">
                        <div 
                            className={`rounded-full bg-sky-400 absolute transition-all duration-[4000ms] ease-in-out opacity-20 ${isBreathingActive && breathText.includes('شهيق') ? 'w-40 h-40' : 'w-16 h-16'}`}
                        ></div>
                        <div 
                            className={`rounded-full bg-sky-500 absolute transition-all duration-[4000ms] ease-in-out opacity-30 ${isBreathingActive && breathText.includes('شهيق') ? 'w-32 h-32' : 'w-12 h-12'}`}
                        ></div>
                        <button
                            onClick={() => setIsBreathingActive(!isBreathingActive)}
                            className="relative z-10 w-24 h-24 rounded-full bg-white border-4 border-sky-300 flex items-center justify-center shadow-lg text-sky-700 font-bold text-center text-sm p-1 hover:scale-105 transition-transform"
                        >
                            {isBreathingActive ? (breathText.includes('احبسي') ? '✋' : (breathText.includes('شهيق') ? '👃' : '👄')) : 'ابدأ'}
                        </button>
                    </div>
                    <p className="text-xl font-bold text-sky-700 h-8">{isBreathingActive ? breathText : ''}</p>
                </div>

                {/* BMI Calculator */}
                <div className="bg-white rounded-2xl shadow-md p-6 border border-gray-100">
                    <h3 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
                        <span>⚖️</span>
                        مراقبة الوزن (BMI)
                    </h3>
                    <div className="flex gap-4 mb-4">
                        <div className="flex-1">
                            <label className="text-xs font-bold text-gray-500">الوزن (كغم)</label>
                            <input 
                                type="number" 
                                value={weight}
                                onChange={(e) => setWeight(e.target.value)}
                                className="w-full p-2 border rounded-lg bg-gray-50 text-center"
                                placeholder="0"
                            />
                        </div>
                        <div className="flex-1">
                            <label className="text-xs font-bold text-gray-500">الطول (سم)</label>
                            <input 
                                type="number" 
                                value={height}
                                onChange={(e) => setHeight(e.target.value)}
                                className="w-full p-2 border rounded-lg bg-gray-50 text-center"
                                placeholder="0"
                            />
                        </div>
                    </div>
                    <button 
                        onClick={calculateBMI}
                        className="w-full bg-purple-500 text-white py-2 rounded-lg font-bold hover:bg-purple-600 transition-colors"
                    >
                        احسب
                    </button>
                    
                    {bmiResult && (
                        <div className="mt-4 text-center bg-gray-50 p-3 rounded-lg animate-fade-in">
                            <p className="text-sm text-gray-500">مؤشر كتلة الجسم</p>
                            <p className="text-3xl font-bold text-gray-800">{bmiResult.value}</p>
                            <p className={`font-bold ${bmiResult.color}`}>{bmiResult.status}</p>
                        </div>
                    )}
                </div>
            </div>
        )}

        {/* CONTENT: DIET TAB */}
        {activeTab === 'diet' && (
            <div className="animate-fade-in space-y-4">
                <div className="bg-white rounded-xl shadow-sm p-4 border-l-4 border-yellow-400">
                    <h3 className="font-bold text-gray-800 mb-2">🦴 الكالسيوم وفيتامين د</h3>
                    <p className="text-sm text-gray-600 mb-3">لحماية العظام من الهشاشة، احرصي على تناول:</p>
                    <div className="flex gap-3 overflow-x-auto pb-2">
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center text-xl">🥛</div>
                            <span className="text-xs mt-1">حليب/زبادي</span>
                        </div>
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center text-xl">🧀</div>
                            <span className="text-xs mt-1">أجبان</span>
                        </div>
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center text-xl">🐟</div>
                            <span className="text-xs mt-1">سمك</span>
                        </div>
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center text-xl">🥚</div>
                            <span className="text-xs mt-1">بيض</span>
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-xl shadow-sm p-4 border-l-4 border-green-400">
                    <h3 className="font-bold text-gray-800 mb-2">🌿 الإستروجين النباتي</h3>
                    <p className="text-sm text-gray-600 mb-3">أطعمة قد تساعد في تعويض نقص الإستروجين:</p>
                    <div className="flex gap-3 overflow-x-auto pb-2">
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center text-xl">🌱</div>
                            <span className="text-xs mt-1">فول الصويا</span>
                        </div>
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center text-xl">🌰</div>
                            <span className="text-xs mt-1">بذور الكتان</span>
                        </div>
                        <div className="flex flex-col items-center min-w-[70px]">
                            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center text-xl">🥜</div>
                            <span className="text-xs mt-1">مكسرات</span>
                        </div>
                    </div>
                </div>

                <div className="bg-rose-50 p-4 rounded-xl text-center">
                    <p className="font-bold text-rose-800 mb-2">🚫 قللي من:</p>
                    <div className="flex justify-center gap-4 text-sm text-rose-700">
                        <span>☕ الكافيين</span>
                        <span>🧂 الملح الزائد</span>
                        <span>🍬 السكريات</span>
                    </div>
                </div>
            </div>
        )}
    </div>
  );
};

export default MenopauseInfo;

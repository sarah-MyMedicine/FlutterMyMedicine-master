
import React, { useState, useEffect } from 'react';
import { ColorWaterIcon, CupIcon, CheckCircleIcon } from './icons';
import { WaterLog } from '../types';

interface WaterTrackerProps {
  waterLog: WaterLog[];
  onAddWater: (amount: number) => void;
  onRemoveWater: (amount: number) => void;
}

const WaterTracker: React.FC<WaterTrackerProps> = ({ waterLog, onAddWater, onRemoveWater }) => {
  const [dailyGoal, setDailyGoal] = useState(() => {
    return parseInt(localStorage.getItem('waterGoal') || '2000');
  });

  const todayStr = new Date().toISOString().split('T')[0];
  const todayLog = waterLog.find(log => log.date === todayStr);
  const currentAmount = todayLog ? todayLog.amount : 0;
  
  const percentage = Math.min(100, Math.round((currentAmount / dailyGoal) * 100));
  const cupsConsumed = Math.floor(currentAmount / 250);
  const goalCups = Math.ceil(dailyGoal / 250);

  const handleSetGoal = (newGoal: number) => {
      setDailyGoal(newGoal);
      localStorage.setItem('waterGoal', newGoal.toString());
  };

  const dayOfWeekFormatter = new Intl.DateTimeFormat('ar-EG', { weekday: 'short' });

  // Get last 7 days data for chart
  const getLast7DaysData = () => {
      const data = [];
      for (let i = 6; i >= 0; i--) {
          const d = new Date();
          d.setDate(d.getDate() - i);
          const dStr = d.toISOString().split('T')[0];
          const log = waterLog.find(l => l.date === dStr);
          data.push({
              day: dayOfWeekFormatter.format(d),
              amount: log ? log.amount : 0,
              isToday: i === 0
          });
      }
      return data;
  };

  const chartData = getLast7DaysData();

  return (
    <div className="animate-fade-in pb-20">
      {/* Header Card */}
      <div className="bg-gradient-to-br from-blue-400 to-sky-300 rounded-2xl p-6 text-white shadow-lg mb-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full -mt-10 -mr-10"></div>
        <div className="absolute bottom-0 left-0 w-24 h-24 bg-blue-600 opacity-10 rounded-full -mb-8 -ml-8"></div>
        
        <div className="relative z-10 flex items-center justify-between">
            <div>
                <h2 className="text-2xl font-bold mb-1">شرب الماء</h2>
                <p className="text-blue-50 text-sm">سر الحيوية والنشاط</p>
            </div>
            <div className="bg-white/20 p-2 rounded-full backdrop-blur-sm">
                <ColorWaterIcon className="w-12 h-12" />
            </div>
        </div>

        <div className="mt-6 flex flex-col items-center">
             <div className="relative w-40 h-40 flex items-center justify-center">
                 {/* Circular Progress Background */}
                 <svg className="w-full h-full transform -rotate-90">
                     <circle
                        cx="80"
                        cy="80"
                        r="70"
                        stroke="currentColor"
                        strokeWidth="10"
                        fill="transparent"
                        className="text-blue-300/30"
                     />
                     <circle
                        cx="80"
                        cy="80"
                        r="70"
                        stroke="currentColor"
                        strokeWidth="10"
                        fill="transparent"
                        strokeDasharray={440}
                        strokeDashoffset={440 - (440 * percentage) / 100}
                        className="text-white transition-all duration-1000 ease-out"
                        strokeLinecap="round"
                     />
                 </svg>
                 <div className="absolute flex flex-col items-center">
                     <span className="text-3xl font-bold">{currentAmount}</span>
                     <span className="text-xs opacity-80">من {dailyGoal} مل</span>
                 </div>
             </div>
             
             {percentage >= 100 && (
                 <div className="mt-2 bg-white/20 px-3 py-1 rounded-full text-sm font-bold animate-bounce flex items-center gap-1">
                     <CheckCircleIcon className="w-4 h-4" />
                     <span>حققت الهدف!</span>
                 </div>
             )}
        </div>
      </div>

      {/* Controls */}
      <div className="bg-white rounded-xl shadow-md p-6 mb-6">
          <h3 className="font-bold text-gray-800 mb-4 text-center">سجل استهلاكك</h3>
          
          <div className="flex justify-center gap-6 mb-6">
              <button 
                onClick={() => onAddWater(250)}
                className="flex flex-col items-center group"
              >
                  <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center text-blue-500 border border-blue-100 group-hover:bg-blue-500 group-hover:text-white transition-all shadow-sm group-hover:shadow-md transform group-hover:scale-110">
                      <CupIcon className="w-8 h-8" />
                  </div>
                  <span className="text-xs font-bold text-gray-600 mt-2">+250 مل</span>
                  <span className="text-[10px] text-gray-400">كوب</span>
              </button>

              <button 
                onClick={() => onAddWater(500)}
                className="flex flex-col items-center group"
              >
                  <div className="w-16 h-16 bg-sky-50 rounded-full flex items-center justify-center text-sky-500 border border-sky-100 group-hover:bg-sky-500 group-hover:text-white transition-all shadow-sm group-hover:shadow-md transform group-hover:scale-110">
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-8 h-8">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9.75 3.104v5.714a2.25 2.25 0 0 1-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 0 1 4.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0 1 12 15a9.065 9.065 0 0 0-6.23-.693L5 14.5m14.8.8 1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0 1 12 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5" />
                      </svg>
                  </div>
                  <span className="text-xs font-bold text-gray-600 mt-2">+500 مل</span>
                  <span className="text-[10px] text-gray-400">قارورة</span>
              </button>

              <button 
                 onClick={() => onRemoveWater(250)}
                 className="flex flex-col items-center group opacity-60 hover:opacity-100"
              >
                  <div className="w-12 h-12 bg-red-50 rounded-full flex items-center justify-center text-red-400 border border-red-100 group-hover:bg-red-500 group-hover:text-white transition-all">
                      <span className="text-2xl font-bold mb-1">-</span>
                  </div>
                  <span className="text-xs font-bold text-gray-500 mt-2">إنقاص</span>
              </button>
          </div>
          
          {/* Visual Cups Grid */}
          <div className="bg-gray-50 p-4 rounded-lg flex flex-wrap justify-center gap-2">
              {Array.from({ length: Math.max(8, goalCups) }).map((_, i) => (
                  <div key={i} className={`transition-all duration-500 ${i < cupsConsumed ? 'text-blue-500 scale-110' : 'text-gray-300 scale-100'}`}>
                      <CupIcon className="w-8 h-8" />
                  </div>
              ))}
          </div>
      </div>

      {/* Weekly Chart */}
      <div className="bg-white rounded-xl shadow-md p-6">
          <h3 className="font-bold text-gray-800 mb-4">نشاطك الأسبوعي</h3>
          <div className="flex items-end justify-between h-32 gap-2">
              {chartData.map((data, idx) => {
                  const hPercent = Math.min(100, Math.round((data.amount / dailyGoal) * 100));
                  return (
                      <div key={idx} className="flex-1 flex flex-col items-center gap-2 group">
                          <div className="w-full bg-gray-100 rounded-t-lg relative h-full flex items-end overflow-hidden">
                              <div 
                                style={{ height: `${hPercent}%` }} 
                                className={`w-full rounded-t-lg transition-all duration-1000 ${data.isToday ? 'bg-blue-500' : 'bg-blue-300 group-hover:bg-blue-400'}`}
                              ></div>
                          </div>
                          <span className={`text-xs font-bold ${data.isToday ? 'text-blue-600' : 'text-gray-500'}`}>{data.day}</span>
                      </div>
                  )
              })}
          </div>
      </div>
      
      {/* Tips */}
      <div className="mt-6 bg-blue-50 p-4 rounded-xl border border-blue-100 text-sm text-blue-800">
         <p className="font-bold mb-1">💡 هل تعلم؟</p>
         <p>شرب الماء بانتظام يساعد الكلى على تصفية الدم، ويقلل من لزوجة الدم مما يخفف العبء على القلب، وهو ضروري جداً لتنظيم ضغط الدم.</p>
      </div>
    </div>
  );
};

export default WaterTracker;

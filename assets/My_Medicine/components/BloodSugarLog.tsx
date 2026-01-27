
import React from 'react';
import { BloodSugarLog } from '../types';
import { PlusIcon, ChartBarIcon, PrinterIcon } from './icons';

interface BloodSugarLogProps {
  bloodSugarLog: BloodSugarLog[];
  onAddReading: () => void;
  onOpenReport: () => void;
}

const BloodSugarLogComponent: React.FC<BloodSugarLogProps> = ({ bloodSugarLog, onAddReading, onOpenReport }) => {
  const timeFormatter = new Intl.DateTimeFormat('ar-EG', {
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
    numberingSystem: 'arab',
  });

  const groupedLog = bloodSugarLog.reduce((acc, log) => {
    const date = new Date(log.timestamp);
    const dateString = new Intl.DateTimeFormat('ar-EG', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      numberingSystem: 'arab',
    }).format(date);

    if (!acc[dateString]) {
      acc[dateString] = [];
    }
    acc[dateString].push(log);
    return acc;
  }, {} as Record<string, BloodSugarLog[]>);
  
  const getValueColor = (value: number) => {
    if (value > 180) return 'text-red-500'; // High
    if (value < 70) return 'text-[#52a396]'; // Low
    return 'text-blue-500'; // Normal
  };

  return (
    <div>
        <div className="flex justify-end items-center mb-6 gap-2">
            <button 
                onClick={onOpenReport}
                className="flex items-center gap-2 bg-sky-500 hover:bg-sky-600 text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300"
                aria-label="طباعة أو حفظ سجل السكري"
            >
                <PrinterIcon className="w-5 h-5" />
                <span>طباعة</span>
            </button>
            <button 
                onClick={onAddReading}
                className="flex items-center gap-2 bg-[#5fb8a8] hover:bg-[#52a396] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300"
            >
                <PlusIcon className="w-5 h-5" />
                <span>إضافة قراءة</span>
            </button>
        </div>

        {bloodSugarLog.length === 0 ? (
            <div className="text-center py-16 px-4">
                <div className="mx-auto w-24 h-24 text-gray-300">
                    <ChartBarIcon />
                </div>
                <h2 className="text-2xl font-semibold text-gray-600 mt-4">لا توجد قراءات بعد</h2>
                <p className="text-gray-500 mt-2">انقر على زر "إضافة قراءة" لبدء المتابعة.</p>
            </div>
        ) : (
            <div className="space-y-6">
            {Object.entries(groupedLog).map(([dateString, logs]: [string, BloodSugarLog[]]) => (
                <div key={dateString} className="bg-white rounded-xl shadow-md p-5">
                <h3 className="font-bold text-lg text-[#45887e] mb-3 pb-2 border-b">{dateString}</h3>
                <ul className="space-y-3">
                    {logs.map((log) => (
                    <li key={log.id} className="bg-gray-50 p-3 rounded-lg flex justify-between items-center transition-colors hover:bg-[#f0f9f8]">
                        <div>
                            <p className={`font-bold text-2xl ${getValueColor(log.value)}`}>{log.value} <span className="text-sm text-gray-500">ملغ/ديسيلتر</span></p>
                            {log.notes && <p className="text-sm text-gray-600 mt-1">{log.notes}</p>}
                        </div>
                        <div className="text-right">
                            <p className="font-mono text-sm text-gray-600">{timeFormatter.format(new Date(log.timestamp))}</p>
                        </div>
                    </li>
                    ))}
                </ul>
                </div>
            ))}
            </div>
        )}
    </div>
  );
};

export default BloodSugarLogComponent;

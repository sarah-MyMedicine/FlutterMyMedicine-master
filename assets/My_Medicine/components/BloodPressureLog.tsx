
import React from 'react';
import { BloodPressureLog } from '../types';
import { PlusIcon, PrinterIcon, HeartIcon, PencilIcon, TrashIcon } from './icons';

interface BloodPressureLogProps {
  bloodPressureLog: BloodPressureLog[];
  onAddReading: () => void;
  onOpenReport: () => void;
  onEditReading: (reading: BloodPressureLog) => void;
  onDeleteReading: (id: string) => void;
}

const BloodPressureLogComponent: React.FC<BloodPressureLogProps> = ({ bloodPressureLog, onAddReading, onOpenReport, onEditReading, onDeleteReading }) => {
  const timeFormatter = new Intl.DateTimeFormat('ar-EG', {
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
    numberingSystem: 'arab',
  });

  const groupedLog = bloodPressureLog.reduce((acc, log) => {
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
  }, {} as Record<string, BloodPressureLog[]>);
  
  const getStatusColor = (sys: number, dia: number) => {
    // High Stage 2
    if (sys >= 140 || dia >= 90) return 'text-red-600 bg-red-50 border-red-100'; 
    // Elevated / High Stage 1
    if (sys > 120 || dia > 80) return 'text-amber-500 bg-amber-50 border-amber-100'; 
    // Low (Hypotension)
    if (sys < 90 || dia < 60) return 'text-blue-600 bg-blue-50 border-blue-100';
    // Normal (Optimal)
    return 'text-green-600 bg-green-50 border-green-100'; 
  };

  const getStatusText = (sys: number, dia: number) => {
      if (sys >= 140 || dia >= 90) return 'مرتفع';
      if (sys > 120 || dia > 80) return 'مائل للارتفاع';
      if (sys < 90 || dia < 60) return 'منخفض';
      return 'طبيعي';
  };

  return (
    <div className="animate-fade-in pb-20">
        <div className="flex justify-between items-end mb-8">
            <div>
                <h2 className="text-2xl font-bold text-gray-800">سجل ضغط الدم</h2>
                <p className="text-gray-500 text-sm mt-1">تابع صحة قلبك بانتظام (المعدل الطبيعي 120/80)</p>
            </div>
            <div className="flex items-center gap-2">
                 <button 
                    onClick={onOpenReport}
                    className="flex items-center gap-2 bg-white text-gray-600 border border-gray-200 hover:bg-gray-50 hover:text-gray-800 font-bold py-2.5 px-4 rounded-xl transition-all duration-300 shadow-sm"
                    aria-label="طباعة التقرير أو حفظ كملف PDF"
                >
                    <PrinterIcon className="w-5 h-5" />
                    <span className="hidden sm:inline">تقرير PDF / طباعة</span>
                    <span className="sm:hidden">تقرير</span>
                </button>
                <button 
                    onClick={onAddReading}
                    className="flex items-center gap-2 bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2.5 px-4 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
                >
                    <PlusIcon className="w-5 h-5" />
                    <span>إضافة قراءة</span>
                </button>
            </div>
        </div>

        {bloodPressureLog.length === 0 ? (
            <div className="text-center py-16 px-4 bg-white rounded-2xl shadow-sm border border-gray-100 dashed border-2">
                <div className="mx-auto w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mb-4 text-gray-300">
                    <HeartIcon className="w-10 h-10" />
                </div>
                <h2 className="text-xl font-semibold text-gray-600">لا توجد قراءات</h2>
                <p className="text-gray-500 mt-2 max-w-xs mx-auto">ابدأ بتسجيل قراءات ضغط الدم لمتابعة حالتك الصحية.</p>
            </div>
        ) : (
            <div className="space-y-6">
            {Object.entries(groupedLog).map(([dateString, logs]: [string, BloodPressureLog[]]) => (
                <div key={dateString} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    <div className="bg-gray-50 px-5 py-3 border-b border-gray-100 flex items-center justify-between">
                         <h3 className="font-bold text-gray-700">{dateString}</h3>
                         <span className="text-xs bg-white px-2 py-1 rounded text-gray-500 border border-gray-200">{logs.length} قراءات</span>
                    </div>
                    <div className="divide-y divide-gray-50">
                        {logs.map((log) => (
                        <div key={log.id} className="p-4 flex flex-col sm:flex-row justify-between items-start sm:items-center hover:bg-[#fafdfc] transition-colors gap-3 group">
                            <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4 w-full">
                                <div className="flex items-center gap-2">
                                     <div className={`flex flex-col items-center justify-center w-16 h-16 rounded-full border-2 ${getStatusColor(log.systolic, log.diastolic)} bg-opacity-10`}>
                                         <span className="text-lg font-bold leading-none">{log.systolic}</span>
                                         <div className="w-8 h-px bg-current opacity-30 my-0.5"></div>
                                         <span className="text-lg font-bold leading-none">{log.diastolic}</span>
                                     </div>
                                     <div className="flex flex-col">
                                         <span className="text-xs text-gray-400 font-medium">mmHg</span>
                                         <span className={`text-xs font-bold px-2 py-0.5 rounded-full mt-1 w-fit ${getStatusColor(log.systolic, log.diastolic)} bg-opacity-10`}>
                                            {getStatusText(log.systolic, log.diastolic)}
                                         </span>
                                     </div>
                                </div>

                                <div className="flex flex-col sm:border-l sm:pl-4 sm:ml-2 gap-1">
                                    {log.pulse && (
                                        <span className="text-sm text-gray-600 flex items-center gap-1">
                                            <span className="text-gray-400 text-xs">النبض:</span> 
                                            <span className="font-bold">{log.pulse}</span>
                                            <span className="text-xs text-gray-400">bpm</span>
                                        </span>
                                    )}
                                    {log.notes && (
                                        <span className="text-sm text-gray-500 bg-gray-50 px-2 py-1 rounded-md">
                                            {log.notes}
                                        </span>
                                    )}
                                </div>
                            </div>
                            <div className="text-left pl-2 w-full sm:w-auto text-right flex flex-row sm:flex-col items-center sm:items-end justify-between sm:justify-center gap-3">
                                <p className="font-mono text-sm text-gray-400 whitespace-nowrap">
                                    {timeFormatter.format(new Date(log.timestamp))}
                                </p>
                                <div className="flex gap-1 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                                    <button 
                                        onClick={() => onEditReading(log)}
                                        className="p-1.5 text-blue-500 hover:bg-blue-50 rounded-full transition-colors"
                                        title="تعديل القراءة"
                                    >
                                        <PencilIcon className="w-4 h-4" />
                                    </button>
                                    <button 
                                        onClick={() => onDeleteReading(log.id)}
                                        className="p-1.5 text-red-500 hover:bg-red-50 rounded-full transition-colors"
                                        title="حذف القراءة"
                                    >
                                        <TrashIcon className="w-4 h-4" />
                                    </button>
                                </div>
                            </div>
                        </div>
                        ))}
                    </div>
                </div>
            ))}
            </div>
        )}
    </div>
  );
};

export default BloodPressureLogComponent;

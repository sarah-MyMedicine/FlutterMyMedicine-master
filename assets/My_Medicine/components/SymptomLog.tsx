
import React from 'react';
import { SymptomLog, Medication } from '../types';
import { PlusIcon, ExclamationTriangleIcon, ShieldCheckIcon, FaceSmileIcon, FaceMehIcon, FaceFrownIcon, PencilIcon, TrashIcon, PillIcon } from './icons';

interface SymptomLogProps {
  symptomLog: SymptomLog[];
  onAddSymptom: () => void;
  medications: Medication[];
  onEditSymptom: (symptom: SymptomLog) => void;
  onDeleteSymptom: (id: string) => void;
}

const SymptomLogComponent: React.FC<SymptomLogProps> = ({ symptomLog, onAddSymptom, medications, onEditSymptom, onDeleteSymptom }) => {
  const timeFormatter = new Intl.DateTimeFormat('ar-EG', {
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
    numberingSystem: 'arab',
  });

  const groupedLog = symptomLog.reduce((acc, log) => {
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
  }, {} as Record<string, SymptomLog[]>);

  const getSeverityConfig = (severity: 'خفيف' | 'متوسط' | 'شديد') => {
    switch (severity) {
      case 'خفيف':
        return {
          bgClass: 'bg-emerald-50 border-emerald-100 hover:bg-emerald-100',
          textClass: 'text-emerald-800',
          badgeClass: 'bg-emerald-100 text-emerald-700',
          icon: <FaceSmileIcon className="w-10 h-10 text-emerald-500" />
        };
      case 'متوسط':
        return {
          bgClass: 'bg-amber-50 border-amber-100 hover:bg-amber-100',
          textClass: 'text-amber-800',
          badgeClass: 'bg-amber-100 text-amber-700',
          icon: <FaceMehIcon className="w-10 h-10 text-amber-500" />
        };
      case 'شديد':
        return {
          bgClass: 'bg-rose-50 border-rose-100 hover:bg-rose-100',
          textClass: 'text-rose-800',
          badgeClass: 'bg-rose-100 text-rose-700',
          icon: <FaceFrownIcon className="w-10 h-10 text-rose-500" />
        };
      default:
        return {
          bgClass: 'bg-gray-50 border-gray-200 hover:bg-gray-100',
          textClass: 'text-gray-800',
          badgeClass: 'bg-gray-100 text-gray-700',
          icon: <FaceMehIcon className="w-10 h-10 text-gray-400" />
        };
    }
  };
  
  const getMedicationName = (id?: string) => {
      if (!id) return null;
      const med = medications.find(m => m.id === id);
      return med ? med.name : null;
  };

  return (
    <div>
      <div className="flex justify-end items-center mb-6">
        <button 
          onClick={onAddSymptom}
          className="flex items-center gap-2 bg-[#5fb8a8] hover:bg-[#52a396] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300"
        >
          <PlusIcon className="w-5 h-5" />
          <span>تسجيل عرض</span>
        </button>
      </div>

      {symptomLog.length === 0 ? (
        <div className="text-center py-16 px-4">
          <div className="mx-auto w-24 h-24 text-gray-300">
            <ExclamationTriangleIcon />
          </div>
          <h2 className="text-2xl font-semibold text-gray-600 mt-4">لا توجد أعراض مسجلة</h2>
          <p className="text-gray-500 mt-2">انقر على زر "تسجيل عرض" لبدء المتابعة.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {Object.entries(groupedLog).map(([dateString, logs]: [string, SymptomLog[]]) => (
            <div key={dateString} className="bg-white rounded-xl shadow-md p-5">
              <h3 className="font-bold text-lg text-[#45887e] mb-3 pb-2 border-b">{dateString}</h3>
              <ul className="space-y-3">
                {logs.map((log) => {
                  const config = getSeverityConfig(log.severity);
                  return (
                    <li key={log.id} className={`p-4 rounded-xl border flex flex-col sm:flex-row justify-between items-start transition-all duration-200 ${config.bgClass}`}>
                      <div className="flex-1 w-full flex gap-4">
                        <div className="flex-shrink-0 pt-1">
                            {config.icon}
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-3 flex-wrap">
                                <p className={`font-bold text-lg ${config.textClass}`}>{log.symptom}</p>
                                <span className={`px-2 py-0.5 text-xs font-bold rounded-full border border-opacity-20 ${config.badgeClass}`}>
                                {log.severity}
                                </span>
                                {log.isReported && (
                                    <span className="flex items-center gap-1 px-2 py-0.5 text-xs font-bold rounded-full bg-orange-100 text-orange-700 border border-orange-200" title="تم إبلاغ المختصين">
                                        <ShieldCheckIcon className="w-3 h-3" />
                                        <span>تم الإبلاغ</span>
                                    </span>
                                )}
                            </div>
                            
                            {/* Patient Conditions Badges */}
                            {log.patientConditions && (
                                <div className="flex flex-wrap gap-2 mt-2">
                                    {log.patientConditions.hasAllergy && (
                                        <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded-md text-xs font-semibold border border-blue-200">
                                            حساسية
                                        </span>
                                    )}
                                    {log.patientConditions.isSmoker && (
                                        <span className="px-2 py-0.5 bg-gray-200 text-gray-700 rounded-md text-xs font-semibold border border-gray-300">
                                            مدخن
                                        </span>
                                    )}
                                    {log.patientConditions.hasKidneyIssue && (
                                        <span className="px-2 py-0.5 bg-purple-100 text-purple-700 rounded-md text-xs font-semibold border border-purple-200">
                                            أمراض الكلى
                                        </span>
                                    )}
                                    {log.patientConditions.hasLiverIssue && (
                                        <span className="px-2 py-0.5 bg-amber-100 text-amber-700 rounded-md text-xs font-semibold border border-amber-200">
                                            أمراض الكبد
                                        </span>
                                    )}
                                </div>
                            )}

                            {log.relatedMedicationId && (
                                <p className="text-sm mt-2 font-semibold flex items-center gap-2 text-gray-700 bg-white bg-opacity-60 px-2 py-1 rounded w-fit">
                                    <PillIcon className="w-4 h-4 text-[#5fb8a8]" />
                                    <span>مرتبط بالدواء: <span className="text-[#45887e]">{getMedicationName(log.relatedMedicationId) || 'غير معروف'}</span></span>
                                </p>
                            )}
                            
                            {log.notes && <p className="text-sm text-gray-600 mt-2">{log.notes}</p>}
                        </div>
                      </div>
                      <div className="text-right w-full sm:w-auto mt-2 sm:mt-0 sm:ms-4 self-center sm:self-start flex flex-row sm:flex-col items-end gap-2 justify-between sm:justify-start">
                        <p className="font-mono text-sm text-gray-500 bg-white bg-opacity-50 px-2 py-1 rounded-md">{timeFormatter.format(new Date(log.timestamp))}</p>
                        
                        <div className="flex gap-2 bg-white bg-opacity-80 rounded-lg p-1 shadow-sm relative z-10">
                            <button 
                                type="button"
                                onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    onEditSymptom(log);
                                }}
                                className="p-2 text-blue-600 hover:bg-blue-100 rounded-full transition-colors" 
                                title="تعديل"
                            >
                                <PencilIcon className="w-5 h-5" />
                            </button>
                            <button 
                                type="button"
                                onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    onDeleteSymptom(log.id);
                                }} 
                                className="p-2 text-red-600 hover:bg-red-100 rounded-full transition-colors cursor-pointer" 
                                title="حذف"
                            >
                                <TrashIcon className="w-5 h-5" />
                            </button>
                        </div>
                      </div>
                    </li>
                  );
                })}
              </ul>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default SymptomLogComponent;

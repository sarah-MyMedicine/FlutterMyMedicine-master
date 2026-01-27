
import React from 'react';
import { Medication } from '../types';
import { PencilIcon, TrashIcon, ClockIcon, CheckCircleIcon } from './icons';

// Add Restore Icon
const ArrowPathIcon: React.FC<{ className?: string }> = ({ className }) => (
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={className || "w-6 h-6"}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" />
    </svg>
);


interface MedicationItemProps {
  medication: Medication;
  onEdit: (medication: Medication) => void;
  onDelete: (id: string) => void;
  onRestore: (id: string) => void;
  onDoseTaken: (medication: Medication) => void;
  isJustTaken: boolean;
}

const MedicationItem: React.FC<MedicationItemProps> = ({ medication, onEdit, onDelete, onRestore, onDoseTaken, isJustTaken }) => {
  const isArchived = medication.isArchived;

  const getCycleStatus = () => {
    if (!medication.isCyclic || !medication.activeDays || !medication.restDays || typeof medication.cycleStartDate === 'undefined' || isArchived) {
      return null;
    }
    const now = new Date();
    // Set time to noon to avoid timezone issues with date changes
    now.setHours(12, 0, 0, 0);
    const startDate = new Date(medication.cycleStartDate);
    startDate.setHours(12, 0, 0, 0);

    const dayInMillis = 24 * 60 * 60 * 1000;
    const totalCycleDays = medication.activeDays + medication.restDays;
    
    // We need to use the nextDose time to determine the current day, as `now` could be in the future
    const referenceDate = new Date(Math.max(now.getTime(), medication.nextDose));
    referenceDate.setHours(12,0,0,0);
    
    const daysSinceStart = Math.floor((referenceDate.getTime() - startDate.getTime()) / dayInMillis);
    
    if (daysSinceStart < 0) {
      return { isRest: false, text: `الدورة ستبدأ قريباً` };
    }

    const dayInCycle = daysSinceStart % totalCycleDays;

    if (dayInCycle < medication.activeDays) {
      // Active period
      return { isRest: false, text: `اليوم ${dayInCycle + 1} من ${medication.activeDays}` };
    } else {
      // Rest period
      const dayInRest = dayInCycle - medication.activeDays;
      return { isRest: true, text: `فترة راحة (يوم ${dayInRest + 1} من ${medication.restDays})` };
    }
  };
  
  const cycleStatus = getCycleStatus();

  if (isJustTaken) {
    return (
      <div className="bg-white rounded-xl shadow-lg overflow-hidden flex flex-col justify-between transition-transform transform hover:scale-105 duration-300 animate-fade-in">
        <div className="p-5 border-r-8 border-[#5fb8a8] flex flex-col justify-center items-center min-h-[280px]">
            <div className="bg-[#e1f3f0] rounded-full p-4">
                <CheckCircleIcon className="w-16 h-16 text-[#5fb8a8]" />
            </div>
            <h3 className="text-xl font-bold text-gray-800 mt-4">تم بنجاح!</h3>
            <p className="text-gray-600">تم تسجيل جرعة {medication.name}.</p>
        </div>
      </div>
    );
  }

  const nextDoseDate = new Date(medication.nextDose);
  const isPast = !isArchived && nextDoseDate.getTime() < Date.now();
  
  const timeFormatter = new Intl.DateTimeFormat('ar-EG', {
      hour: 'numeric',
      minute: 'numeric',
      hour12: true,
      numberingSystem: 'arab',
  });

  const dateFormatter = new Intl.DateTimeFormat('ar-EG', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    numberingSystem: 'arab',
  });

  const isLow = !isArchived && medication.remainingDoses !== undefined &&
              medication.refillThreshold !== undefined &&
              medication.remainingDoses <= medication.refillThreshold;

  // Visuals for archived state
  const borderColor = isArchived 
    ? 'border-gray-400' 
    : (isPast && (!cycleStatus || !cycleStatus.isRest) ? 'border-amber-400' : 'border-[#5fb8a8]');
  
  const cardOpacity = isArchived ? 'opacity-75 grayscale-[0.5]' : 'opacity-100';

  return (
    <div className={`bg-white rounded-xl shadow-lg overflow-hidden flex flex-col justify-between transition-all duration-300 hover:shadow-xl ${cardOpacity}`}>
      <div className={`p-5 border-r-8 ${borderColor}`}>
        <div className="flex justify-between items-start">
          <div>
            <h3 className="text-xl font-bold text-gray-800">{medication.name}</h3>
            <p className="text-gray-600">{medication.dosage}</p>
          </div>
          <div className="flex space-x-1">
            {isArchived && (
                <button onClick={() => onRestore(medication.id)} className="p-2 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded-full transition-colors duration-200" title="استعادة الدواء للقائمة النشطة">
                    <ArrowPathIcon className="w-5 h-5" />
                </button>
            )}
            {!isArchived && (
                <button onClick={() => onEdit(medication)} className="p-2 text-gray-500 hover:text-blue-600 hover:bg-gray-100 rounded-full transition-colors duration-200" aria-label={`تعديل ${medication.name}`}>
                    <PencilIcon className="w-5 h-5" />
                </button>
            )}
            <button onClick={() => onDelete(medication.id)} className="p-2 text-gray-500 hover:text-red-600 hover:bg-gray-100 rounded-full transition-colors duration-200" title={isArchived ? "حذف نهائي" : "إيقاف / أرشفة"}>
               {isArchived ? <TrashIcon className="w-5 h-5" /> : (
                 <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5 text-amber-600">
                    <path strokeLinecap="round" strokeLinejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0-3-3m3 3 3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
                 </svg>
               )}
            </button>
          </div>
        </div>
        
        {medication.remainingDoses !== undefined && !isArchived && (
          <div className={`mt-4 text-sm font-semibold ${isLow ? 'text-red-500 animate-pulse' : 'text-gray-600'}`}>
            الجرعات المتبقية: {medication.remainingDoses}
          </div>
        )}

        <div className="mt-4 border-t pt-4">
          {isArchived ? (
              <div className="text-center py-4">
                  <p className="text-lg font-bold text-gray-500">تم الإيقاف</p>
                  <p className="text-sm text-gray-400">موجود في السجل</p>
              </div>
          ) : (
            <>
                <div className="flex items-center text-lg">
                    <ClockIcon className="w-6 h-6 me-2 text-[#52a396]" />
                    <span className="font-semibold text-gray-700">{cycleStatus ? 'حالة الدورة:' : 'الجرعة التالية:'}</span>
                </div>
                {cycleStatus ? (
                    <div className="text-center mt-2">
                        <p className={`text-xl font-bold ${cycleStatus.isRest ? 'text-gray-600' : 'text-[#52a396]'}`}>{cycleStatus.text}</p>
                        {!cycleStatus.isRest && (
                        <>
                            <p className={`text-2xl font-bold mt-1 ${isPast ? 'text-amber-500 animate-pulse' : 'text-[#52a396]'}`}>
                            {timeFormatter.format(nextDoseDate)}
                            </p>
                            <p className="text-gray-500 text-sm">{dateFormatter.format(nextDoseDate)}</p>
                        </>
                        )}
                    </div>
                ) : (
                    <>
                    <p className={`text-center text-2xl font-bold mt-2 ${isPast ? 'text-amber-500 animate-pulse' : 'text-[#52a396]'}`}>
                        {timeFormatter.format(nextDoseDate)}
                    </p>
                    <p className="text-center text-gray-500 text-sm mt-1">{dateFormatter.format(nextDoseDate)}</p>
                    </>
                )}
            </>
          )}
        </div>
        
        {medication.notes && (
          <div className="mt-4 bg-gray-50 p-3 rounded-lg">
            <p className="text-sm text-gray-600">{medication.notes}</p>
          </div>
        )}
      </div>
      
       {!isArchived && isPast && (!cycleStatus || !cycleStatus.isRest) && (
        <div className="p-4 bg-gray-50">
            <button 
              onClick={() => onDoseTaken(medication)} 
              className="w-full flex items-center justify-center gap-2 bg-[#5fb8a8] hover:bg-[#52a396] text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition-colors duration-300"
            >
              <CheckCircleIcon className="w-6 h-6" />
              <span>تم أخذها</span>
            </button>
        </div>
      )}
    </div>
  );
};

export default MedicationItem;
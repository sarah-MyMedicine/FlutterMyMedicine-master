
import React, { useState, useMemo } from 'react';
import { UserProfile, BloodPressureLog } from '../types';

interface BloodPressureReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  userProfile: UserProfile;
  bloodPressureLog: BloodPressureLog[];
}

const BloodPressureReportModal: React.FC<BloodPressureReportModalProps> = ({ isOpen, onClose, userProfile, bloodPressureLog }) => {
  const [periodDays, setPeriodDays] = useState<number>(7);

  const { filteredLog, startDate, endDate, stats } = useMemo(() => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - periodDays + 1);
    start.setHours(0, 0, 0, 0);

    const filtered = bloodPressureLog.filter(log => log.timestamp >= start.getTime() && log.timestamp <= end.getTime());
    
    const reportStats = {
      avgSys: 0,
      avgDia: 0,
      count: filtered.length,
    };

    if (reportStats.count > 0) {
      let sumSys = 0;
      let sumDia = 0;
      filtered.forEach(log => {
        sumSys += log.systolic;
        sumDia += log.diastolic;
      });
      reportStats.avgSys = Math.round(sumSys / reportStats.count);
      reportStats.avgDia = Math.round(sumDia / reportStats.count);
    }

    const grouped = filtered.reduce((acc, log) => {
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

    return { filteredLog: grouped, startDate: start, endDate: end, stats: reportStats };
  }, [bloodPressureLog, periodDays]);
  
  const handlePrint = () => {
    window.print();
  };

  if (!isOpen) return null;
  
  const dateFormatter = new Intl.DateTimeFormat('ar-EG', { year: 'numeric', month: 'long', day: 'numeric', numberingSystem: 'arab' });
  const timeFormatter = new Intl.DateTimeFormat('ar-EG', { hour: 'numeric', minute: 'numeric', hour12: true, numberingSystem: 'arab' });

  // Categorization for report
  const getCategoryColor = (sys: number, dia: number) => {
      if (sys >= 140 || dia >= 90) return 'text-red-600';
      if (sys > 120 || dia > 80) return 'text-amber-600';
      if (sys < 90 || dia < 60) return 'text-blue-600';
      return 'text-green-600';
  };

  return (
    <>
    <style>
      {`
        @media print {
          body > *:not(.printable-area) {
            display: none !important;
          }
          .printable-area {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            padding: 20px;
            background-color: white;
            color: black;
          }
          .no-print {
            display: none !important;
          }
          .print-color-adjust {
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
        }
      `}
    </style>
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl flex flex-col w-full max-w-4xl h-[90vh] transform transition-all animate-fade-in-up">
        <div className="no-print p-4 border-b flex justify-between items-center">
          <h2 className="text-xl font-bold text-gray-800">تقرير ضغط الدم</h2>
          <div className="flex items-center gap-4">
             <select value={periodDays} onChange={(e) => setPeriodDays(Number(e.target.value))} className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]">
                <option value={7}>آخر 7 أيام</option>
                <option value={14}>آخر 14 يومًا</option>
                <option value={30}>آخر 30 يومًا</option>
            </select>
            <button onClick={handlePrint} className="bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300">
              طباعة / حفظ كـ PDF
            </button>
            <button onClick={onClose} className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300">
              إغلاق
            </button>
          </div>
        </div>

        <div className="p-8 overflow-y-auto printable-area">
          <header className="text-center border-b pb-4 mb-8">
            <h1 className="text-3xl font-bold text-gray-900">تقرير ضغط الدم</h1>
            <p className="text-lg text-gray-600 mt-2">{userProfile.name}</p>
            <p className="text-md text-gray-500 mt-1">
              الفترة: {dateFormatter.format(startDate)} - {dateFormatter.format(endDate)}
            </p>
          </header>
          
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-[#45887e] border-b-2 border-[#c3e7e2] pb-2 mb-4">ملخص الفترة</h2>
            {stats.count > 0 ? (
              <div className="grid grid-cols-2 gap-4 text-center">
                <div className="bg-blue-50 p-4 rounded-lg">
                  <p className="text-sm text-blue-700 font-bold">متوسط القراءات</p>
                  <p className="text-3xl font-bold text-blue-900" dir="ltr">{stats.avgSys} / {stats.avgDia}</p>
                  <span className="text-xs text-gray-500">mmHg</span>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-700 font-bold">عدد القراءات</p>
                  <p className="text-3xl font-bold text-gray-900">{stats.count}</p>
                </div>
              </div>
            ) : (
              <p className="text-gray-500">لا توجد بيانات كافية لعرض الملخص.</p>
            )}
          </section>

          <section>
            <h2 className="text-2xl font-semibold text-[#45887e] border-b-2 border-[#c3e7e2] pb-2 mb-4">سجل القراءات</h2>
            <div className="space-y-6">
                {Object.keys(filteredLog).length > 0 ? Object.entries(filteredLog).map(([date, logs]: [string, BloodPressureLog[]]) => (
                  <div key={date}>
                      <h3 className="font-bold text-xl text-gray-700 mb-2">{date}</h3>
                      <div className="border-s-4 border-gray-200 ps-4 space-y-2">
                        {logs.map(log => (
                          <div key={log.id} className="flex justify-between items-center bg-gray-50 p-3 rounded-md">
                            <div className="flex-1">
                                <div className="flex items-baseline gap-2">
                                    <span className={`font-bold text-2xl print-color-adjust ${getCategoryColor(log.systolic, log.diastolic)}`}>
                                        {log.systolic}/{log.diastolic}
                                    </span>
                                    <span className="text-sm text-gray-500">mmHg</span>
                                    {log.pulse && <span className="text-sm text-gray-400 border-r pr-2 mr-2">النبض: {log.pulse}</span>}
                                </div>
                                {log.notes && <p className="text-sm text-gray-600 mt-1">{log.notes}</p>}
                            </div>
                            <p className="font-mono text-[#52a396] font-semibold">{timeFormatter.format(new Date(log.timestamp))}</p>
                          </div>
                        ))}
                      </div>
                  </div>
                )) : (
                  <p className="text-gray-500 text-center py-8">لا يوجد سجل لقراءات الضغط في هذه الفترة.</p>
                )}
            </div>
          </section>
          
           <footer className="text-center text-gray-500 text-sm mt-12 pt-4 border-t">
              <p className="font-bold text-red-600 mb-2">تنويه هام: هذا التقرير هو للمتابعة الشخصية ولا يغني عن استشارة الطبيب.</p>
              تم إنشاء هذا التقرير بتاريخ {dateFormatter.format(new Date())}
           </footer>
        </div>
      </div>
    </div>
    </>
  );
};

export default BloodPressureReportModal;

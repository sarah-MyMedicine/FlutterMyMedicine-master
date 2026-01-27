
import React, { useState } from 'react';
import { DoseLog } from '../types';

interface AdherenceLogProps {
  doseLog: DoseLog[];
}

const AdherenceLog: React.FC<AdherenceLogProps> = ({ doseLog }) => {
  const timeFormatter = new Intl.DateTimeFormat('ar-EG', {
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
    numberingSystem: 'arab',
  });

  const groupedDoseLog = doseLog.reduce((acc, log) => {
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
  }, {} as Record<string, DoseLog[]>);

  if (doseLog.length === 0) {
    return (
      <div className="text-center py-16 px-4">
        <div className="mx-auto w-24 h-24 text-gray-300">
           <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1} stroke="currentColor" className="w-24 h-24">
             <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
           </svg>
        </div>
        <h2 className="text-2xl font-semibold text-gray-600 mt-4">لا يوجد سجل بعد</h2>
        <p className="text-gray-500 mt-2">عندما تسجل أخذ جرعة، ستظهر هنا.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {Object.entries(groupedDoseLog).map(([dateString, logs]: [string, DoseLog[]]) => (
        <div key={dateString} className="bg-white rounded-xl shadow-md p-5">
          <h3 className="font-bold text-lg text-[#45887e] mb-3 pb-2 border-b">{dateString}</h3>
          <ul className="space-y-3">
            {logs.map((log) => (
              <li key={log.timestamp} className="bg-gray-50 p-3 rounded-lg flex justify-between items-center transition-colors hover:bg-[#f0f9f8]">
                <div>
                  <p className="font-semibold text-gray-800">{log.medicationName}</p>
                  <p className="text-sm text-gray-500">{log.dosage}</p>
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
  );
};

export default AdherenceLog;

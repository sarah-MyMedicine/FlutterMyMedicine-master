import React from 'react';
import { Medication } from '../types';

interface MedicationInfoModalProps {
  isOpen: boolean;
  onClose: () => void;
  medication: Medication | null;
}

const InfoSection: React.FC<{ title: string; items?: string[] }> = ({ title, items }) => {
    if (!items || items.length === 0) return null;
    return (
        <div>
            <h4 className="text-lg font-bold text-[#45887e] mb-2">{title}</h4>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
                {items.map((item, index) => <li key={index}>{item}</li>)}
            </ul>
        </div>
    );
};


const MedicationInfoModal: React.FC<MedicationInfoModalProps> = ({ isOpen, onClose, medication }) => {
  if (!isOpen || !medication) return null;

  const { info, isFetchingInfo } = medication;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4" onClick={onClose}>
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-lg transform transition-all animate-fade-in-up" onClick={(e) => e.stopPropagation()}>
        <h2 className="text-2xl font-bold mb-2 text-gray-800">{medication.name}</h2>
        <p className="text-gray-600 mb-6 border-b pb-4">{medication.dosage}</p>
        
        {isFetchingInfo && (
            <div className="flex flex-col items-center justify-center h-48">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-[#5fb8a8]"></div>
                <p className="text-gray-600 mt-4">جاري جلب المعلومات...</p>
            </div>
        )}

        {!isFetchingInfo && info && (
            <div className="space-y-6 max-h-80 overflow-y-auto pr-2">
                <InfoSection title="الآثار الجانبية المحتملة" items={info.sideEffects} />
                <InfoSection title="تحذيرات هامة" items={info.warnings} />
            </div>
        )}

        {!isFetchingInfo && !info && (
            <div className="text-center py-10">
                <p className="text-gray-500">لم يتم العثور على معلومات إضافية لهذا الدواء.</p>
            </div>
        )}

        <div className="mt-6 text-center">
            <button type="button" onClick={onClose} className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-6 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300">
              إغلاق
            </button>
        </div>
      </div>
    </div>
  );
};

export default MedicationInfoModal;
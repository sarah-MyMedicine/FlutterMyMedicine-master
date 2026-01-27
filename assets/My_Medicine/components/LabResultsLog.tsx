
import React from 'react';
import { LabResult } from '../types';
import { CameraIcon, TrashIcon, PencilIcon } from './icons';

interface LabResultsLogProps {
  labResults: LabResult[];
  onAddResult: () => void;
  onEditResult: (result: LabResult) => void;
  onDeleteResult: (id: string) => void;
}

const LabResultsLog: React.FC<LabResultsLogProps> = ({ labResults, onAddResult, onEditResult, onDeleteResult }) => {
  const dateFormatter = new Intl.DateTimeFormat('ar-EG', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    numberingSystem: 'arab',
  });

  return (
    <div className="animate-fade-in pb-20">
        <div className="flex justify-between items-end mb-6">
            <div>
                <h2 className="text-2xl font-bold text-gray-800">نتائجي المختبرية</h2>
                <p className="text-gray-500 text-sm mt-1">احتفظ بصور تحاليلك وفحوصاتك في مكان واحد</p>
            </div>
            <button 
                onClick={onAddResult}
                className="flex items-center gap-2 bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2.5 px-4 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
            >
                <CameraIcon className="w-5 h-5" />
                <span>إضافة نتيجة</span>
            </button>
        </div>

        {labResults.length === 0 ? (
            <div className="text-center py-16 px-4 bg-white rounded-2xl shadow-sm border border-gray-100 dashed border-2">
                <div className="mx-auto w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mb-4 text-gray-300">
                    <CameraIcon className="w-10 h-10" />
                </div>
                <h2 className="text-xl font-semibold text-gray-600">لا توجد نتائج محفوظة</h2>
                <p className="text-gray-500 mt-2 max-w-xs mx-auto">اضغط على "إضافة نتيجة" لالتقاط صور التحاليل وحفظها.</p>
            </div>
        ) : (
            <div className="grid grid-cols-1 gap-6">
            {labResults.map((result) => (
                <div key={result.id} className="bg-white rounded-xl shadow-sm overflow-hidden border border-gray-100 hover:shadow-md transition-shadow">
                    <div className="p-4 border-b border-gray-50">
                        <div className="flex justify-between items-start mb-1">
                            <div>
                                <h3 className="font-bold text-gray-800 text-lg">{result.title || "نتيجة تحليل"}</h3>
                                <p className="text-xs text-[#5fb8a8] font-bold">
                                    {dateFormatter.format(new Date(result.timestamp))}
                                </p>
                            </div>
                            <div className="flex gap-1">
                                <button 
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        onEditResult(result);
                                    }}
                                    className="text-gray-400 hover:text-blue-500 hover:bg-blue-50 rounded-full transition-colors p-2"
                                    title="تعديل"
                                >
                                    <PencilIcon className="w-5 h-5" />
                                </button>
                                <button 
                                    onClick={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                        onDeleteResult(result.id);
                                    }}
                                    className="text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-full transition-colors p-2 group"
                                    title="حذف"
                                >
                                    <TrashIcon className="w-5 h-5 group-hover:scale-110 transition-transform" />
                                </button>
                            </div>
                        </div>
                    </div>
                    
                    {/* Images Grid */}
                    <div className={`grid gap-1 bg-gray-50 ${result.images.length === 1 ? 'grid-cols-1' : (result.images.length === 2 ? 'grid-cols-2' : 'grid-cols-3')}`}>
                         {result.images.map((imgSrc, idx) => (
                            <div 
                                key={idx} 
                                className="relative h-48 cursor-pointer group overflow-hidden"
                                onClick={() => {
                                    const w = window.open('about:blank');
                                    if(w) {
                                         const image = new Image();
                                         image.src = imgSrc;
                                         setTimeout(() => w.document.write(image.outerHTML), 0);
                                    }
                                }}
                            >
                                <img 
                                    src={imgSrc} 
                                    alt={`Page ${idx + 1}`} 
                                    className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                                />
                                <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all flex items-center justify-center">
                                    <span className="opacity-0 group-hover:opacity-100 bg-black bg-opacity-60 text-white px-3 py-1 rounded-full text-sm">عرض</span>
                                </div>
                            </div>
                         ))}
                    </div>

                    {result.notes && (
                        <div className="p-4 bg-gray-50 border-t border-gray-100">
                             <p className="text-sm text-gray-600">
                                <span className="font-bold text-gray-700">ملاحظات:</span> {result.notes}
                            </p>
                        </div>
                    )}
                </div>
            ))}
            </div>
        )}
    </div>
  );
};

export default LabResultsLog;

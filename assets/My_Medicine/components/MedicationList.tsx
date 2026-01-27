
import React, { useState } from 'react';
import { Medication } from '../types';
import MedicationItem from './MedicationItem';

interface MedicationListProps {
  medications: Medication[];
  onEdit: (medication: Medication) => void;
  onDelete: (id: string) => void;
  onRestore: (id: string) => void;
  onDoseTaken: (medication: Medication) => void;
  searchQuery: string;
  justTakenMedId: string | null;
}

// Icon component since it's used here and might not be in icons.tsx yet
const ArchiveIcon = ({ className }: { className?: string }) => (
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={className || "w-6 h-6"}>
        <path strokeLinecap="round" strokeLinejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0-3-3m3 3 3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
    </svg>
);

const ActiveIcon = ({ className }: { className?: string }) => (
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={className || "w-6 h-6"}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
    </svg>
);


const MedicationList: React.FC<MedicationListProps> = ({ medications, onEdit, onDelete, onRestore, onDoseTaken, searchQuery, justTakenMedId }) => {
  const [viewMode, setViewMode] = useState<'active' | 'archived'>('active');

  const activeMedications = medications.filter(m => !m.isArchived);
  const archivedMedications = medications.filter(m => m.isArchived);

  const displayedMedications = viewMode === 'active' ? activeMedications : archivedMedications;
  
  // Filter by search query
  const filteredMedications = displayedMedications.filter(med => {
      if (!searchQuery) return true;
      const query = searchQuery.toLowerCase();
      return med.name.toLowerCase().includes(query) || 
             med.dosage.toLowerCase().includes(query) ||
             (med.notes && med.notes.toLowerCase().includes(query));
  });
  
  // Sort: Active by next dose, Archived by name (or you could sort by ID/date added)
  const sortedMedications = [...filteredMedications].sort((a, b) => {
      if (viewMode === 'active') {
          return a.nextDose - b.nextDose;
      }
      return a.name.localeCompare(b.name);
  });

  return (
    <div>
        {/* Tabs */}
        <div className="flex bg-gray-200 rounded-lg p-1 mb-6">
            <button
                onClick={() => setViewMode('active')}
                className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-md transition-all duration-300 ${viewMode === 'active' ? 'bg-white shadow-sm text-[#5fb8a8] font-bold' : 'text-gray-500 hover:text-gray-700'}`}
            >
                <ActiveIcon className="w-5 h-5" />
                <span>الحالية</span>
                <span className="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full ms-1">{activeMedications.length}</span>
            </button>
            <button
                onClick={() => setViewMode('archived')}
                className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-md transition-all duration-300 ${viewMode === 'archived' ? 'bg-white shadow-sm text-[#5fb8a8] font-bold' : 'text-gray-500 hover:text-gray-700'}`}
            >
                <ArchiveIcon className="w-5 h-5" />
                <span>السجل</span>
                <span className="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full ms-1">{archivedMedications.length}</span>
            </button>
        </div>

        {sortedMedications.length === 0 && !justTakenMedId ? (
            <div className="text-center py-16 px-4">
                <div className="mx-auto w-24 h-24 text-gray-300">
                    {viewMode === 'active' ? (
                         <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1" stroke="currentColor" className="w-24 h-24">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
                        </svg>
                    ) : (
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1" stroke="currentColor" className="w-24 h-24">
                             <path strokeLinecap="round" strokeLinejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0-3-3m3 3 3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
                        </svg>
                    )}
                </div>
                <h2 className="text-2xl font-semibold text-gray-600 mt-4">
                    {searchQuery 
                        ? 'لا توجد نتائج' 
                        : (viewMode === 'active' ? 'لا توجد أدوية نشطة حالياً' : 'سجل الأدوية فارغ')}
                </h2>
                <p className="text-gray-500 mt-2">
                    {searchQuery 
                        ? `لم نجد أي دواء يطابق بحثك "${searchQuery}".` 
                        : (viewMode === 'active' ? 'انقر على زر "إضافة دواء" لبدء المتابعة.' : 'الأدوية التي تقوم بإيقافها ستظهر هنا.')}
                </p>
            </div>
        ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {sortedMedications.map(med => (
                <MedicationItem 
                    key={med.id} 
                    medication={med} 
                    onEdit={onEdit} 
                    onDelete={onDelete} 
                    onRestore={onRestore}
                    onDoseTaken={onDoseTaken} 
                    isJustTaken={justTakenMedId === med.id}
                />
            ))}
            </div>
        )}
    </div>
  );
};

export default MedicationList;

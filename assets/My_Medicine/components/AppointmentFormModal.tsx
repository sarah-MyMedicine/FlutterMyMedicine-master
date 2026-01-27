import React, { useState, useEffect } from 'react';
import { Appointment } from '../types';
import { UserDoctorIcon } from './icons';

interface AppointmentFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (appointment: Appointment) => void;
  appointmentToEdit?: Appointment | null;
}

const AppointmentFormModal: React.FC<AppointmentFormModalProps> = ({ isOpen, onClose, onSave, appointmentToEdit }) => {
  const [doctorName, setDoctorName] = useState('');
  const [specialty, setSpecialty] = useState('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (isOpen) {
        if (appointmentToEdit) {
            setDoctorName(appointmentToEdit.doctorName);
            setSpecialty(appointmentToEdit.specialty);
            setDate(appointmentToEdit.date);
            setTime(appointmentToEdit.time);
            setNotes(appointmentToEdit.notes || '');
        } else {
            setDoctorName('');
            setSpecialty('');
            setDate('');
            setTime('');
            setNotes('');
        }
    }
  }, [isOpen, appointmentToEdit]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!doctorName || !date || !time) return;

    onSave({
        id: appointmentToEdit?.id || Date.now().toString(),
        doctorName,
        specialty,
        date,
        time,
        notes
    });
    onClose();
  };

  if (!isOpen) return null;

  const title = appointmentToEdit ? 'تعديل الموعد' : 'إضافة موعد جديد';

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-sm transform transition-all animate-fade-in-up max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">{title}</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-gray-700 text-sm font-bold mb-2">اسم الطبيب</label>
            <div className="relative">
                <input 
                    type="text" 
                    value={doctorName} 
                    onChange={(e) => setDoctorName(e.target.value)} 
                    className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 pl-10 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" 
                    placeholder="د. محمد..."
                    required 
                />
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <UserDoctorIcon className="h-5 w-5 text-gray-400" />
                </div>
            </div>
          </div>
          
          <div className="mb-4">
            <label className="block text-gray-700 text-sm font-bold mb-2">التخصص</label>
            <input 
                type="text" 
                value={specialty} 
                onChange={(e) => setSpecialty(e.target.value)} 
                className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" 
                placeholder="مثال: باطنية، أسنان..."
            />
          </div>

          <div className="flex gap-4 mb-4">
              <div className="flex-1">
                  <label className="block text-gray-700 text-sm font-bold mb-2">التاريخ</label>
                  <input 
                    type="date" 
                    value={date} 
                    onChange={(e) => setDate(e.target.value)} 
                    className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" 
                    required 
                  />
              </div>
              <div className="flex-1">
                  <label className="block text-gray-700 text-sm font-bold mb-2">الوقت</label>
                  <input 
                    type="time" 
                    value={time} 
                    onChange={(e) => setTime(e.target.value)} 
                    className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" 
                    required 
                  />
              </div>
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 text-sm font-bold mb-2">أسئلة للطبيب / ملاحظات</label>
            <textarea 
                value={notes} 
                onChange={(e) => setNotes(e.target.value)} 
                className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8] h-24"
                placeholder="اكتب هنا الأسئلة التي تود طرحها على الطبيب..."
            />
          </div>

          <div className="flex items-center justify-between">
            <button
              type="submit"
              className="bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 transition-colors duration-300"
            >
              حفظ الموعد
            </button>
            <button
              type="button"
              onClick={onClose}
              className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 ms-3 transition-colors duration-300"
            >
              إلغاء
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AppointmentFormModal;
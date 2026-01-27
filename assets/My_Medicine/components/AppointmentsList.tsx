import React from 'react';
import { Appointment } from '../types';
import { UserDoctorIcon, PencilIcon, TrashIcon, ClockIcon, PlusIcon, ColorAppointmentIcon } from './icons';

interface AppointmentsListProps {
  appointments: Appointment[];
  onAddAppointment: () => void;
  onEditAppointment: (appointment: Appointment) => void;
  onDeleteAppointment: (id: string) => void;
}

const AppointmentsList: React.FC<AppointmentsListProps> = ({ appointments, onAddAppointment, onEditAppointment, onDeleteAppointment }) => {
  
  // Sort appointments by date
  const sortedAppointments = [...appointments].sort((a, b) => {
      const dateA = new Date(`${a.date}T${a.time}`);
      const dateB = new Date(`${b.date}T${b.time}`);
      return dateA.getTime() - dateB.getTime();
  });

  const now = new Date();
  const upcomingAppointments = sortedAppointments.filter(app => new Date(`${app.date}T${app.time}`) >= now);
  const pastAppointments = sortedAppointments.filter(app => new Date(`${app.date}T${app.time}`) < now);

  const formatDate = (dateStr: string) => {
      return new Intl.DateTimeFormat('ar-EG', {
          weekday: 'long',
          day: 'numeric',
          month: 'long'
      }).format(new Date(dateStr));
  };
  
  const formatTime = (timeStr: string) => {
      const [hours, minutes] = timeStr.split(':');
      let h = parseInt(hours, 10);
      const ampm = h >= 12 ? 'م' : 'ص';
      h = h % 12;
      h = h ? h : 12; // the hour '0' should be '12'
      return `${h}:${minutes} ${ampm}`;
  };

  const getCountdown = (dateStr: string, timeStr: string) => {
      const target = new Date(`${dateStr}T${timeStr}`);
      const diff = target.getTime() - now.getTime();
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));
      
      if (days === 0) return 'اليوم';
      if (days === 1) return 'غداً';
      return `بعد ${days} يوم`;
  };

  return (
    <div className="animate-fade-in pb-20">
        <div className="flex justify-between items-end mb-6">
            <div>
                <h2 className="text-2xl font-bold text-gray-800">مواعيدي الطبية</h2>
                <p className="text-gray-500 text-sm mt-1">نظم زياراتك الطبية ولا تنس أسئلتك</p>
            </div>
            <button 
                onClick={onAddAppointment}
                className="flex items-center gap-2 bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2.5 px-4 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
            >
                <PlusIcon className="w-5 h-5" />
                <span>موعد جديد</span>
            </button>
        </div>

        {upcomingAppointments.length === 0 && pastAppointments.length === 0 ? (
            <div className="text-center py-16 px-4 bg-white rounded-2xl shadow-sm border border-gray-100 dashed border-2">
                <div className="mx-auto w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mb-4 text-gray-300">
                    <ColorAppointmentIcon className="w-12 h-12" />
                </div>
                <h2 className="text-xl font-semibold text-gray-600">لا توجد مواعيد</h2>
                <p className="text-gray-500 mt-2 max-w-xs mx-auto">أضف مواعيدك القادمة لتذكيرك بها وتدوين أسئلتك للطبيب.</p>
            </div>
        ) : (
            <div className="space-y-6">
                {/* Upcoming Section */}
                {upcomingAppointments.length > 0 && (
                    <div className="space-y-4">
                        <h3 className="font-bold text-gray-700 flex items-center gap-2">
                            <span className="w-2 h-2 bg-green-500 rounded-full"></span>
                            المواعيد القادمة
                        </h3>
                        {upcomingAppointments.map(app => (
                            <div key={app.id} className="bg-white rounded-xl shadow-md border-r-4 border-r-[#5fb8a8] p-5 hover:shadow-lg transition-shadow">
                                <div className="flex justify-between items-start">
                                    <div className="flex gap-4">
                                        <div className="bg-[#f0f9f8] p-3 rounded-xl flex flex-col items-center justify-center min-w-[80px] text-center">
                                            <span className="text-xs text-gray-500 font-bold">{formatDate(app.date).split(' ')[0]}</span>
                                            <span className="text-2xl font-bold text-[#45887e]">{new Date(app.date).getDate()}</span>
                                            <span className="text-xs text-gray-500">{new Date(app.date).toLocaleString('ar-EG', {month: 'short'})}</span>
                                        </div>
                                        <div>
                                            <h4 className="font-bold text-lg text-gray-800 flex items-center gap-2">
                                                <UserDoctorIcon className="w-5 h-5 text-gray-400" />
                                                {app.doctorName}
                                            </h4>
                                            <p className="text-sm text-gray-500 mb-2">{app.specialty}</p>
                                            <div className="flex items-center gap-4 text-sm font-medium text-gray-600 bg-gray-50 px-3 py-1 rounded-lg w-fit">
                                                <span className="flex items-center gap-1">
                                                    <ClockIcon className="w-4 h-4 text-[#5fb8a8]" />
                                                    {formatTime(app.time)}
                                                </span>
                                                <span className="text-gray-300">|</span>
                                                <span className="text-[#5fb8a8] font-bold">{getCountdown(app.date, app.time)}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <button onClick={() => onEditAppointment(app)} className="text-blue-500 hover:bg-blue-50 p-2 rounded-full"><PencilIcon className="w-5 h-5" /></button>
                                        <button onClick={() => onDeleteAppointment(app.id)} className="text-red-500 hover:bg-red-50 p-2 rounded-full"><TrashIcon className="w-5 h-5" /></button>
                                    </div>
                                </div>
                                {app.notes && (
                                    <div className="mt-4 bg-yellow-50 p-3 rounded-lg border border-yellow-100">
                                        <p className="text-xs font-bold text-yellow-700 mb-1">أسئلة / ملاحظات:</p>
                                        <p className="text-sm text-gray-700">{app.notes}</p>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                )}

                {/* Past Section */}
                {pastAppointments.length > 0 && (
                    <div className="space-y-4 pt-4 border-t">
                        <h3 className="font-bold text-gray-500 flex items-center gap-2">
                            <span className="w-2 h-2 bg-gray-400 rounded-full"></span>
                            المواعيد السابقة
                        </h3>
                        {pastAppointments.map(app => (
                            <div key={app.id} className="bg-gray-50 rounded-xl border border-gray-200 p-4 opacity-80">
                                <div className="flex justify-between items-center">
                                    <div>
                                        <h4 className="font-bold text-gray-700">{app.doctorName} <span className="text-xs font-normal text-gray-500">({app.specialty})</span></h4>
                                        <p className="text-sm text-gray-500">{formatDate(app.date)}</p>
                                    </div>
                                    <button onClick={() => onDeleteAppointment(app.id)} className="text-gray-400 hover:text-red-500"><TrashIcon className="w-4 h-4" /></button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        )}
    </div>
  );
};

export default AppointmentsList;
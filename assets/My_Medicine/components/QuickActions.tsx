

import React from 'react';
import { 
  ColorHealthReportIcon, 
  ColorSymptomsIcon, 
  ColorPillsIcon, 
  ColorLogIcon, 
  ColorBloodDropIcon,
  ColorShopIcon,
  ColorPregnantIcon,
  ColorBloodPressureIcon,
  BellAlertIcon,
  ColorLabIcon,
  ColorMenopauseIcon,
  ColorButterflyIcon,
  ColorAppointmentIcon
} from './icons';
import { UserProfile } from '../types';

interface QuickActionsProps {
  onNavigate: (view: 'medications' | 'bloodSugar' | 'symptoms' | 'log' | 'pregnancy' | 'bloodPressure' | 'labResults' | 'menopause' | 'puberty' | 'shop' | 'appointments') => void;
  onOpenHealthReport: () => void;
  onEmergency: () => void;
  userProfile?: UserProfile;
}

const QuickActionButton: React.FC<{
  label: string;
  subLabel?: string;
  icon: React.ReactNode;
  onClick: () => void;
  variant?: 'default' | 'danger';
}> = ({ label, subLabel, icon, onClick, variant = 'default' }) => (
  <button
    onClick={onClick}
    className={`group flex flex-col items-center justify-center p-2 border rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-offset-2 aspect-[4/3] sm:aspect-square h-full w-full overflow-hidden
      ${variant === 'danger' 
        ? 'bg-red-50 border-red-100 hover:bg-red-100 focus:ring-red-500' 
        : 'bg-white border-gray-100 focus:ring-[#5fb8a8]'}`}
    aria-label={label}
  >
    <div className={`transform transition-transform duration-300 group-hover:scale-110 drop-shadow-sm ${subLabel ? 'mb-1' : 'mb-3'}`}>
      {icon}
    </div>
    <span className={`text-sm font-bold transition-colors duration-200 ${variant === 'danger' ? 'text-red-600 group-hover:text-red-700' : 'text-gray-700 group-hover:text-[#5fb8a8]'}`}>
      {label}
    </span>
    {subLabel && (
        <span className={`text-[10px] mt-1 text-center leading-tight px-1 ${variant === 'danger' ? 'text-red-500/80 font-medium' : 'text-gray-400'}`}>
            {subLabel}
        </span>
    )}
  </button>
);

const QuickActions: React.FC<QuickActionsProps> = ({ onNavigate, onOpenHealthReport, onEmergency, userProfile }) => {
  const isFemaleOver48 = userProfile?.gender === 'أنثى' && userProfile.age && parseInt(userProfile.age) >= 48;
  const isFemaleTeen = userProfile?.gender === 'أنثى' && userProfile.age && parseInt(userProfile.age) >= 13 && parseInt(userProfile.age) <= 17;
  // Pregnancy Care appears for Females aged 18+
  const isFemaleAdult = userProfile?.gender === 'أنثى' && userProfile.age && parseInt(userProfile.age) >= 18;

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 mb-8">
      <QuickActionButton
        label="طوارئ"
        subLabel="يرسل تنبيه للمراقب"
        icon={<BellAlertIcon className="w-12 h-12 text-red-500" />}
        onClick={onEmergency}
        variant="danger"
      />

       <QuickActionButton
        label="أدويتي"
        icon={<ColorPillsIcon className="w-14 h-14" />}
        onClick={() => onNavigate('medications')}
      />
      
      <QuickActionButton
        label="مواعيدي الطبية"
        icon={<ColorAppointmentIcon className="w-14 h-14" />}
        onClick={() => onNavigate('appointments')}
      />

      <QuickActionButton
        label="تقرير صحي"
        icon={<ColorHealthReportIcon className="w-14 h-14" />}
        onClick={onOpenHealthReport}
      />
      
      <QuickActionButton
        label="سجل الأعراض"
        icon={<ColorSymptomsIcon className="w-14 h-14" />}
        onClick={() => onNavigate('symptoms')}
      />

      <QuickActionButton
        label="سجل الالتزام"
        icon={<ColorLogIcon className="w-14 h-14" />}
        onClick={() => onNavigate('log')}
      />

      <QuickActionButton
        label="سجل السكر"
        icon={<ColorBloodDropIcon className="w-14 h-14" />}
        onClick={() => onNavigate('bloodSugar')}
      />

      <QuickActionButton
        label="سجل الضغط"
        icon={<ColorBloodPressureIcon className="w-14 h-14" />}
        onClick={() => onNavigate('bloodPressure')}
      />

      <QuickActionButton
        label="نتائجي المختبرية"
        icon={<ColorLabIcon className="w-14 h-14" />}
        onClick={() => onNavigate('labResults')}
      />

      {isFemaleOver48 && (
        <QuickActionButton
            label="مرحلة سن الأمل"
            icon={<ColorMenopauseIcon className="w-14 h-14" />}
            onClick={() => onNavigate('menopause')}
        />
      )}

      {isFemaleTeen && (
        <QuickActionButton
            label="مرحلة البلوغ"
            icon={<ColorButterflyIcon className="w-14 h-14" />}
            onClick={() => onNavigate('puberty')}
        />
      )}

      {isFemaleAdult && (
        <QuickActionButton
            label="رعاية الأم"
            icon={<ColorPregnantIcon className="w-14 h-14" />}
            onClick={() => onNavigate('pregnancy')}
        />
      )}

      <QuickActionButton
        label="المتجر"
        icon={<ColorShopIcon className="w-14 h-14" />}
        onClick={() => onNavigate('shop')}
      />
    </div>
  );
};

export default QuickActions;

import React, { useState, useEffect } from 'react';
import { UserProfile } from '../types';
import { DocumentTextIcon, ShieldCheckIcon, ColorPregnantIcon, HeartIcon } from './icons';

interface ProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (profile: UserProfile) => void;
  userProfile: UserProfile;
  onTestNotification: (pattern: 'default' | 'short' | 'long' | 'pulse') => void;
  onOpenHealthReport: () => void;
}

const conditionsList = [
    { id: 'hypertension', label: 'ارتفاع ضغط الدم' },
    { id: 'diabetes', label: 'السكري' },
    { id: 'cholesterol', label: 'ارتفاع الكوليسترول / الدهون الثلاثية' },
    { id: 'heart_failure', label: 'قصور القلب' },
    { id: 'kidney_disease', label: 'أمراض الكلى' },
    { id: 'liver_disease', label: 'أمراض الكبد' },
    { id: 'epilepsy', label: 'الصرع' },
    { id: 'parkinson', label: 'الباركنسون' },
    { id: 'cancer', label: 'السرطان' },
];

const ProfileModal: React.FC<ProfileModalProps> = ({ isOpen, onClose, onSave, userProfile, onTestNotification, onOpenHealthReport }) => {
  const [name, setName] = useState(userProfile.name);
  const [age, setAge] = useState(userProfile.age || '');
  const [gender, setGender] = useState((userProfile.gender && userProfile.gender !== 'أفضل عدم القول') ? userProfile.gender : 'ذكر');
  const [country, setCountry] = useState(userProfile.country || '');
  const [city, setCity] = useState(userProfile.city || '');
  const [vibration, setVibration] = useState(userProfile.vibrationPattern || 'default');
  const [guardianEnabled, setGuardianEnabled] = useState(userProfile.guardianEnabled || false);
  const [guardianName, setGuardianName] = useState(userProfile.guardianName || '');
  const [isPregnant, setIsPregnant] = useState(userProfile.isPregnant || false);
  const [chronicConditions, setChronicConditions] = useState<string[]>(userProfile.chronicConditions || []);
  const [theme, setTheme] = useState(userProfile.theme || 'default');
  const [ageError, setAgeError] = useState('');

  useEffect(() => {
    if (isOpen) {
      setName(userProfile.name);
      setAge(userProfile.age || '');
      setAgeError('');
      setGender((userProfile.gender && userProfile.gender !== 'أفضل عدم القول') ? userProfile.gender : 'ذكر');
      setCountry(userProfile.country || '');
      setCity(userProfile.city || '');
      setVibration(userProfile.vibrationPattern || 'default');
      setGuardianEnabled(userProfile.guardianEnabled || false);
      setGuardianName(userProfile.guardianName || '');
      setIsPregnant(userProfile.isPregnant || false);
      setChronicConditions(userProfile.chronicConditions || []);
      setTheme(userProfile.theme || 'default');
    }
  }, [userProfile, isOpen]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (age) {
        const ageNum = parseInt(age, 10);
        if (!isNaN(ageNum) && ageNum < 13) {
            setAgeError('يجب أن يكون عمرك 13 عاماً أو أكثر لاستخدام هذا التطبيق.');
            return;
        }
    }
    setAgeError('');

    onSave({ 
        name, 
        age,
        gender,
        country,
        city,
        vibrationPattern: vibration,
        guardianEnabled,
        guardianName,
        isPregnant: gender === 'أنثى' ? isPregnant : false,
        theme,
        chronicConditions
    });
    onClose();
  };
  
  const handleTest = () => {
      onTestNotification(vibration);
  };
  
  const handleCreateReport = () => {
    onOpenHealthReport();
    onClose(); // Close the settings modal
  }
  
  const toggleCondition = (id: string) => {
    setChronicConditions(prev => 
        prev.includes(id) 
            ? prev.filter(c => c !== id) 
            : [...prev, id]
    );
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-2xl p-6 w-full max-w-lg transform transition-all animate-fade-in-up max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">الإعدادات</h2>
        <form onSubmit={handleSubmit}>
          <h3 className="text-xl font-bold mb-4 text-gray-700">الملف الشخصي</h3>
          <div className="mb-4">
            <label htmlFor="profile-name" className="block text-gray-700 text-sm font-bold mb-2">الاسم</label>
            <input type="text" id="profile-name" value={name} onChange={(e) => setName(e.target.value)} className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" required />
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
                <div>
                    <label htmlFor="profile-age" className="block text-gray-700 text-sm font-bold mb-2">العمر</label>
                    <input 
                        type="number" 
                        id="profile-age" 
                        value={age} 
                        onChange={(e) => { setAge(e.target.value); setAgeError(''); }} 
                        className={`shadow-sm appearance-none border ${ageError ? 'border-red-500' : 'border-[#c3e7e2]'} bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]`} 
                    />
                    {ageError && <p className="text-red-500 text-xs mt-1 font-semibold">{ageError}</p>}
                </div>
                <div>
                    <label htmlFor="profile-gender" className="block text-gray-700 text-sm font-bold mb-2">الجنس</label>
                    <select id="profile-gender" value={gender} onChange={(e) => setGender(e.target.value as any)} className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]">
                        <option value="ذكر">ذكر</option>
                        <option value="أنثى">أنثى</option>
                    </select>
                </div>
                <div>
                    <label htmlFor="profile-country" className="block text-gray-700 text-sm font-bold mb-2">البلد</label>
                    <input type="text" id="profile-country" value={country} onChange={(e) => setCountry(e.target.value)} className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" />
                </div>
                <div>
                    <label htmlFor="profile-city" className="block text-gray-700 text-sm font-bold mb-2">المحافظة</label>
                    <input type="text" id="profile-city" value={city} onChange={(e) => setCity(e.target.value)} className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" />
                </div>
          </div>

          <div className="mb-6">
              <label htmlFor="app-theme" className="block text-gray-700 text-sm font-bold mb-2">لون التطبيق (الثيم)</label>
              <div className="grid grid-cols-6 gap-2">
                 {[
                    { id: 'default', color: 'bg-[#5fb8a8]' },
                    { id: 'blue', color: 'bg-blue-500' },
                    { id: 'green', color: 'bg-green-600' },
                    { id: 'pink', color: 'bg-pink-500' },
                    { id: 'purple', color: 'bg-purple-600' },
                    { id: 'yellow', color: 'bg-yellow-500' },
                 ].map(t => (
                    <button
                        key={t.id}
                        type="button"
                        onClick={() => setTheme(t.id as any)}
                        className={`w-10 h-10 rounded-full ${t.color} border-4 transition-transform hover:scale-110 focus:outline-none ${theme === t.id ? 'border-gray-600 scale-110' : 'border-white shadow-md'}`}
                        aria-label={`تغيير اللون إلى ${t.id}`}
                    />
                 ))}
              </div>
          </div>

          {/* Chronic Conditions Section */}
          <div className="border-t pt-6 mb-6">
             <div className="flex items-center gap-2 mb-4">
                 <HeartIcon className="w-6 h-6 text-rose-500" />
                 <h3 className="text-xl font-bold text-gray-700">الأمراض المزمنة</h3>
             </div>
             <p className="text-sm text-gray-600 mb-4">حدد الأمراض التي تعاني منها للحصول على نصائح صحية يومية مخصصة لحالتك.</p>
             <div className="grid grid-cols-1 gap-3">
                 {conditionsList.map(condition => (
                    <label key={condition.id} className={`flex items-center p-3 rounded-lg border cursor-pointer transition-colors ${chronicConditions.includes(condition.id) ? 'bg-rose-50 border-rose-200' : 'bg-white border-gray-200 hover:bg-gray-50'}`}>
                        <input 
                            type="checkbox" 
                            checked={chronicConditions.includes(condition.id)}
                            onChange={() => toggleCondition(condition.id)}
                            className="w-5 h-5 text-rose-500 rounded focus:ring-rose-500 border-gray-300"
                        />
                        <span className="ms-3 font-semibold text-gray-700">{condition.label}</span>
                    </label>
                 ))}
             </div>
          </div>

          {/* Pregnancy Toggle for Females 18+ */}
          {gender === 'أنثى' && age && parseInt(age) >= 18 && (
             <div className="mb-6 bg-pink-50 p-3 rounded-xl border border-pink-100 flex items-center justify-between animate-fade-in border-t pt-6">
                <div className="flex items-center gap-3">
                    <div className="bg-pink-100 p-2 rounded-full text-pink-500">
                        <ColorPregnantIcon className="w-6 h-6" />
                    </div>
                    <div>
                        <label htmlFor="is-pregnant" className="font-bold text-gray-800 block">هل أنتِ حامل؟</label>
                        <span className="text-xs text-gray-500">لتخصيص نصائح يومية لكِ ولطفلك</span>
                    </div>
                </div>
                <div className="relative inline-block w-12 mr-2 align-middle select-none transition duration-200 ease-in">
                    <input 
                        type="checkbox" 
                        name="is-pregnant" 
                        id="is-pregnant" 
                        checked={isPregnant}
                        onChange={(e) => setIsPregnant(e.target.checked)}
                        className="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer"
                    />
                    <label htmlFor="is-pregnant" className="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer"></label>
                </div>
             </div>
          )}

          <div className="border-t pt-6 mb-6">
            <div className="flex items-center gap-3 mb-4">
              <ShieldCheckIcon className="w-8 h-8 text-blue-600" />
              <h3 className="text-xl font-bold text-gray-700">المراقب الدوائي</h3>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              عند تفعيل هذه الميزة، سيتم إرسال تنبيه (بشكل محاكي) إلى المراقب في حال تأخرك عن أخذ الجرعة لأكثر من ساعة.
            </p>
            <div className="flex items-center justify-between bg-blue-50 p-3 rounded-lg">
                <label htmlFor="guardian-enabled" className="font-bold text-blue-800">تفعيل المراقب الدوائي</label>
                <div className="relative inline-block w-12 mr-2 align-middle select-none transition duration-200 ease-in">
                    <input 
                        type="checkbox" 
                        name="guardian-enabled" 
                        id="guardian-enabled" 
                        checked={guardianEnabled}
                        onChange={(e) => setGuardianEnabled(e.target.checked)}
                        className="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer"
                    />
                    <label htmlFor="guardian-enabled" className="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer"></label>
                </div>
            </div>
            {guardianEnabled && (
                <div className="mt-4 space-y-4 animate-fade-in-up">
                    <div>
                        <label htmlFor="guardian-name" className="block text-gray-700 text-sm mb-2">اسم المراقب (مثال: ابني أحمد)</label>
                        <input type="text" id="guardian-name" value={guardianName} onChange={(e) => setGuardianName(e.target.value)} placeholder="اسم المراقب" className="bg-white shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]" required />
                    </div>
                </div>
            )}
            <style>{`
                .toggle-checkbox:checked { right: 0; border-color: #5fb8a8; }
                .toggle-checkbox:checked + .toggle-label { background-color: #5fb8a8; }
            `}</style>
          </div>
          
          <div className="border-t pt-6 mb-6">
            <h3 className="text-xl font-bold mb-4 text-gray-700">إعدادات الإشعارات</h3>
            <div className="grid grid-cols-1 gap-4">
                <div>
                    <label htmlFor="notif-vibration" className="block text-gray-700 text-sm font-bold mb-2">نمط الاهتزاز</label>
                    <select id="notif-vibration" value={vibration} onChange={(e) => setVibration(e.target.value as any)} className="shadow-sm appearance-none border border-[#c3e7e2] bg-[#f0f9f8] rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-[#5fb8a8]">
                        <option value="default">الافتراضي</option>
                        <option value="short">قصير</option>
                        <option value="long">طويل</option>
                        <option value="pulse">نبضات</option>
                    </select>
                </div>
            </div>
            <div className="mt-4 text-right">
                <button type="button" onClick={handleTest} className="bg-sky-500 hover:bg-sky-700 text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline transition-colors duration-300 text-sm">
                    اختبار الإشعار
                </button>
            </div>
          </div>
          
          <div className="border-t pt-6 mb-6">
             <h3 className="text-xl font-bold mb-4 text-gray-700">التقارير الصحية</h3>
             <button
                type="button"
                onClick={handleCreateReport}
                className="w-full flex items-center justify-center gap-3 bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition-colors duration-300 text-md"
              >
                <DocumentTextIcon className="w-6 h-6" />
                <span>إنشاء تقرير صحي</span>
              </button>
          </div>
          
          <div className="mt-8 flex items-center justify-between border-t pt-6">
            <button type="submit" className="bg-[#5fb8a8] hover:bg-[#4a9184] text-white font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 transition-colors duration-300">
              حفظ والإغلاق
            </button>
            <button type="button" onClick={onClose} className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded-full focus:outline-none focus:shadow-outline w-1/2 ms-3 transition-colors duration-300">
              إلغاء
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ProfileModal;

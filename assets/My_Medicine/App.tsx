





import React, { useState, useEffect, useCallback, useRef } from 'react';
import { GoogleGenAI } from "@google/genai";
import { Medication, UserProfile, DoseLog, BloodSugarLog, SymptomLog, BloodPressureLog, LabResult, MenopauseLog, Appointment } from './types';
import Header from './components/Header';
import MedicationList from './components/MedicationList';
import MedicationFormModal from './components/MedicationFormModal';
import ProfileModal from './components/ProfileModal';
import AddOptionModal from './components/AddOptionModal';
import HealthReportModal from './components/HealthReportModal';
import Footer from './components/Footer';
import AdherenceLog from './components/AdherenceLog';
import BloodSugarLogComponent from './components/BloodSugarLog';
import BloodSugarFormModal from './components/BloodSugarFormModal';
import BloodSugarReportModal from './components/BloodSugarReportModal';
import AdBanner from './components/AdBanner';
import SymptomLogComponent from './components/SymptomLog';
import SymptomFormModal from './components/SymptomFormModal';
import QuickActions from './components/QuickActions';
import PregnancyCare from './components/PregnancyCare';
import PharmacistBanner from './components/PharmacistBanner';
import BloodPressureLogComponent from './components/BloodPressureLog';
import BloodPressureFormModal from './components/BloodPressureFormModal';
import BloodPressureReportModal from './components/BloodPressureReportModal';
import PregnancyTipsBanner from './components/PregnancyTipsBanner';
import HealthTipBanner from './components/HealthTipBanner';
import LabResultsLog from './components/LabResultsLog';
import LabResultFormModal from './components/LabResultFormModal';
import MenopauseInfo from './components/MenopauseInfo';
import PubertyInfo from './components/PubertyInfo';
import ShopView from './components/ShopView';
import DoseReminderOverlay from './components/DoseReminderOverlay';
import AppointmentsList from './components/AppointmentsList';
import AppointmentFormModal from './components/AppointmentFormModal';
import { BellAlertIcon } from './components/icons';

// Helper function to convert file to base64
const fileToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve((reader.result as string).split(',')[1]);
    reader.onerror = error => reject(error);
  });
};

// Helper function to convert file to Data URL (includes mime type)
const fileToDataURL = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = error => reject(error);
    });
};

const getThemeColors = (theme?: string) => {
    switch (theme) {
        case 'blue': return 'bg-blue-50';
        case 'green': return 'bg-green-50';
        case 'pink': return 'bg-pink-50';
        case 'purple': return 'bg-purple-50';
        case 'yellow': return 'bg-yellow-50';
        default: return 'bg-gray-50'; // Default gray/teal theme
    }
};

const App: React.FC = () => {
  const [medications, setMedications] = useState<Medication[]>(() => {
    const saved = localStorage.getItem('medications');
    return saved ? JSON.parse(saved) : [];
  });
  const [userProfile, setUserProfile] = useState<UserProfile>(() => {
    const saved = localStorage.getItem('userProfile');
    const defaultProfile: UserProfile = { 
        name: 'زائر',
        age: '',
        gender: 'ذكر',
        country: '',
        city: '',
        vibrationPattern: 'default',
        guardianEnabled: false,
        guardianName: '',
        isPregnant: false,
        theme: 'default'
    };
    if (!saved) return defaultProfile;
    const parsed = JSON.parse(saved);
    return { ...defaultProfile, ...parsed };
  });
  const [doseLog, setDoseLog] = useState<DoseLog[]>(() => {
    const saved = localStorage.getItem('doseLog');
    return saved ? JSON.parse(saved) : [];
  });
  const [bloodSugarLog, setBloodSugarLog] = useState<BloodSugarLog[]>(() => {
    const saved = localStorage.getItem('bloodSugarLog');
    return saved ? JSON.parse(saved) : [];
  });
  const [bloodPressureLog, setBloodPressureLog] = useState<BloodPressureLog[]>(() => {
    const saved = localStorage.getItem('bloodPressureLog');
    return saved ? JSON.parse(saved) : [];
  });
  const [symptomLog, setSymptomLog] = useState<SymptomLog[]>(() => {
    const saved = localStorage.getItem('symptomLog');
    return saved ? JSON.parse(saved) : [];
  });
  const [labResults, setLabResults] = useState<LabResult[]>(() => {
    const saved = localStorage.getItem('labResults');
    if (!saved) return [];
    const parsed = JSON.parse(saved);
    // Migration: Convert single imageUrl to images array if needed
    return parsed.map((r: any) => ({
        ...r,
        images: r.images || (r.imageUrl ? [`data:image/jpeg;base64,${r.imageUrl}`] : [])
    }));
  });
  const [menopauseLog, setMenopauseLog] = useState<MenopauseLog[]>(() => {
    const saved = localStorage.getItem('menopauseLog');
    return saved ? JSON.parse(saved) : [];
  });
  const [appointments, setAppointments] = useState<Appointment[]>(() => {
    const saved = localStorage.getItem('appointments');
    return saved ? JSON.parse(saved) : [];
  });

  const [isMedicationModalOpen, setIsMedicationModalOpen] = useState(false);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);
  const [medicationToEdit, setMedicationToEdit] = useState<Partial<Medication> | null>(null);
  const [isBloodSugarModalOpen, setIsBloodSugarModalOpen] = useState(false);
  const [isBloodSugarReportModalOpen, setIsBloodSugarReportModalOpen] = useState(false);
  const [isBloodPressureModalOpen, setIsBloodPressureModalOpen] = useState(false);
  const [isBloodPressureReportModalOpen, setIsBloodPressureReportModalOpen] = useState(false);
  const [bloodPressureToEdit, setBloodPressureToEdit] = useState<BloodPressureLog | null>(null);

  const [isSymptomModalOpen, setIsSymptomModalOpen] = useState(false);
  const [symptomToEdit, setSymptomToEdit] = useState<SymptomLog | null>(null);
  const [isBirthControlMode, setIsBirthControlMode] = useState(false);

  const [isLabResultModalOpen, setIsLabResultModalOpen] = useState(false);
  const [tempLabResultImages, setTempLabResultImages] = useState<string[]>([]);
  const [labResultToEdit, setLabResultToEdit] = useState<LabResult | null>(null);

  const [isAppointmentModalOpen, setIsAppointmentModalOpen] = useState(false);
  const [appointmentToEdit, setAppointmentToEdit] = useState<Appointment | null>(null);

  const [isAddOptionModalOpen, setIsAddOptionModalOpen] = useState(false);
  const [isProcessingImage, setIsProcessingImage] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const labResultInputRef = useRef<HTMLInputElement>(null);
  
  const [isHealthReportModalOpen, setIsHealthReportModalOpen] = useState(false);
  
  const [isEmergencyActive, setIsEmergencyActive] = useState(false);

  const [activeView, setActiveView] = useState<'home' | 'medications' | 'log' | 'bloodSugar' | 'bloodPressure' | 'symptoms' | 'pregnancy' | 'labResults' | 'menopause' | 'puberty' | 'shop' | 'appointments'>('home');
  const [searchQuery, setSearchQuery] = useState('');
  const [justTakenMedId, setJustTakenMedId] = useState<string | null>(null);
  const [shopInitialProduct, setShopInitialProduct] = useState<string | null>(null);

  // Active Reminder State
  const [activeReminderMedication, setActiveReminderMedication] = useState<Medication | null>(null);


  useEffect(() => {
    localStorage.setItem('medications', JSON.stringify(medications));
  }, [medications]);
  
  useEffect(() => {
    localStorage.setItem('userProfile', JSON.stringify(userProfile));
  }, [userProfile]);

  useEffect(() => {
    localStorage.setItem('doseLog', JSON.stringify(doseLog));
  }, [doseLog]);

  useEffect(() => {
    localStorage.setItem('bloodSugarLog', JSON.stringify(bloodSugarLog));
  }, [bloodSugarLog]);

  useEffect(() => {
    localStorage.setItem('bloodPressureLog', JSON.stringify(bloodPressureLog));
  }, [bloodPressureLog]);

  useEffect(() => {
    localStorage.setItem('symptomLog', JSON.stringify(symptomLog));
  }, [symptomLog]);

  useEffect(() => {
    localStorage.setItem('labResults', JSON.stringify(labResults));
  }, [labResults]);
  
  useEffect(() => {
    localStorage.setItem('menopauseLog', JSON.stringify(menopauseLog));
  }, [menopauseLog]);
  
  useEffect(() => {
    localStorage.setItem('appointments', JSON.stringify(appointments));
  }, [appointments]);

  // Request notification permission on mount
  useEffect(() => {
      if ('Notification' in window) {
          Notification.requestPermission();
      }
  }, []);

  // Check for due medications every minute
  useEffect(() => {
    const checkDoses = () => {
        const now = Date.now();
        // Find a medication that is due (nextDose is in the past or now) and not archived
        if (activeReminderMedication) return;

        const dueMedication = medications.find(m => 
            !m.isArchived && 
            m.nextDose <= now
        );

        if (dueMedication) {
            setActiveReminderMedication(dueMedication);
            
            // Trigger System Notification
            if ('Notification' in window && Notification.permission === 'granted') {
                new Notification(`حان وقت دواء: ${dueMedication.name}`, {
                    body: `الجرعة: ${dueMedication.dosage}. اضغط هنا لتسجيل الجرعة.`,
                    icon: 'https://cdn-icons-png.flaticon.com/512/822/822163.png', // Generic pill icon
                    tag: dueMedication.id // Prevent duplicate notifications
                });
            }
        }
    };

    const intervalId = setInterval(checkDoses, 30000); // Check every 30 seconds
    return () => clearInterval(intervalId);
  }, [medications, activeReminderMedication]);


  const handleSaveMedication = (medication: Medication) => {
    if (medicationToEdit?.id) {
      setMedications(medications.map(m => m.id === medication.id ? medication : m));
    } else {
      setMedications([...medications, medication]);
    }
    setMedicationToEdit(null);
    setIsBirthControlMode(false);
  };

  const handleDeleteMedication = (id: string) => {
      // Soft delete: Archive it
      setMedications(medications.map(m => 
          m.id === id ? { ...m, isArchived: true } : m
      ));
  };
  
  const handleRestoreMedication = (id: string) => {
      setMedications(medications.map(m => 
          m.id === id ? { ...m, isArchived: false } : m
      ));
  };

  const handleEditMedication = (medication: Medication) => {
    setMedicationToEdit(medication);
    setIsBirthControlMode(!!medication.isCyclic);
    setIsMedicationModalOpen(true);
  };

  const handleDoseTaken = (medication: Medication) => {
    const now = Date.now();
    const takenLog: DoseLog = {
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: medication.dosage,
      timestamp: now,
    };
    setDoseLog([takenLog, ...doseLog]);

    // Update medication next dose and remaining doses
    const nextDoseTime = now + (medication.frequency * 60 * 60 * 1000);
    const updatedMedication = {
      ...medication,
      nextDose: nextDoseTime,
      remainingDoses: medication.remainingDoses ? medication.remainingDoses - 1 : undefined,
      lastNotified: undefined, 
      guardianNotified: false
    };
    
    setMedications(medications.map(m => m.id === medication.id ? updatedMedication : m));
    
    // Close overlay if open
    if (activeReminderMedication?.id === medication.id) {
        setActiveReminderMedication(null);
    }

    // Show success feedback
    setJustTakenMedId(medication.id);
    setTimeout(() => setJustTakenMedId(null), 3000);
  };

  const handleSkipDose = (medication: Medication) => {
      const now = Date.now();
      // Move next dose forward without logging it as taken
      const nextDoseTime = now + (medication.frequency * 60 * 60 * 1000);
      const updatedMedication = {
          ...medication,
          nextDose: nextDoseTime,
          // Do NOT decrement remaining doses
      };
      setMedications(medications.map(m => m.id === medication.id ? updatedMedication : m));
      setActiveReminderMedication(null);
  };

  const handleSnoozeDose = (medication: Medication) => {
      // Add 15 minutes to the current nextDose (or make it now + 15m)
      const now = Date.now();
      const snoozedTime = now + (15 * 60 * 1000); // 15 minutes
      
      const updatedMedication = {
          ...medication,
          nextDose: snoozedTime
      };
      setMedications(medications.map(m => m.id === medication.id ? updatedMedication : m));
      setActiveReminderMedication(null);
  };

  const handleSaveProfile = (profile: UserProfile) => {
    setUserProfile(profile);
  };

  // --- Blood Sugar Handlers ---
  const handleSaveBloodSugar = (reading: { value: number; notes?: string }) => {
    const newLog: BloodSugarLog = {
      id: Date.now().toString(),
      timestamp: Date.now(),
      value: reading.value,
      notes: reading.notes,
    };
    setBloodSugarLog([newLog, ...bloodSugarLog]);
    setIsBloodSugarModalOpen(false);
  };

  // --- Blood Pressure Handlers ---
  const handleSaveBloodPressure = (reading: { systolic: number; diastolic: number; pulse?: number; notes?: string }) => {
     if (bloodPressureToEdit) {
         setBloodPressureLog(bloodPressureLog.map(log => log.id === bloodPressureToEdit.id ? { ...log, ...reading } : log));
         setBloodPressureToEdit(null);
     } else {
        const newLog: BloodPressureLog = {
            id: Date.now().toString(),
            timestamp: Date.now(),
            systolic: reading.systolic,
            diastolic: reading.diastolic,
            pulse: reading.pulse,
            notes: reading.notes,
        };
        setBloodPressureLog([newLog, ...bloodPressureLog]);
     }
     setIsBloodPressureModalOpen(false);
  };

  const handleDeleteBloodPressure = (id: string) => {
      if(window.confirm('هل أنت متأكد من حذف هذه القراءة؟')) {
          setBloodPressureLog(bloodPressureLog.filter(l => l.id !== id));
      }
  }

  // --- Symptom Handlers ---
  const handleSaveSymptom = (data: any) => {
    if (symptomToEdit) {
        setSymptomLog(symptomLog.map(s => s.id === symptomToEdit.id ? { ...s, ...data } : s));
        setSymptomToEdit(null);
    } else {
        const newLog: SymptomLog = {
        id: Date.now().toString(),
        timestamp: Date.now(),
        ...data
        };
        setSymptomLog([newLog, ...symptomLog]);
    }
    setIsSymptomModalOpen(false);
  };

  const handleEditSymptom = (symptom: SymptomLog) => {
      setSymptomToEdit(symptom);
      setIsSymptomModalOpen(true);
  }

  const handleDeleteSymptom = (id: string) => {
      if (window.confirm('هل أنت متأكد من حذف هذا العرض؟')) {
        setSymptomLog(symptomLog.filter(s => s.id !== id));
      }
  }

  // --- Lab Results Handlers ---
  const handleCaptureLabResult = () => {
      setLabResultToEdit(null);
      setTempLabResultImages([]);
      if (labResultInputRef.current) {
          labResultInputRef.current.click();
      }
  };
  
  const handleAddMoreImages = () => {
      if (labResultInputRef.current) {
          labResultInputRef.current.click();
      }
  };

  const handleRemoveTempImage = (index: number) => {
      setTempLabResultImages(prev => prev.filter((_, i) => i !== index));
  };

  const handleLabResultFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
      const files = event.target.files;
      if (files && files.length > 0) {
          const newImages: string[] = [];
          for (let i = 0; i < files.length; i++) {
              try {
                  const dataUrl = await fileToDataURL(files[i]);
                  newImages.push(dataUrl);
              } catch (error) {
                  console.error("Error reading file", error);
              }
          }
          setTempLabResultImages(prev => [...prev, ...newImages]);
          if (!isLabResultModalOpen) setIsLabResultModalOpen(true);
      }
      // Reset input
      if (event.target) event.target.value = '';
  };

  const handleEditLabResult = (result: LabResult) => {
      setLabResultToEdit(result);
      setTempLabResultImages(result.images);
      setIsLabResultModalOpen(true);
  };

  const handleSaveLabResult = (data: { title: string; notes: string }) => {
      if (labResultToEdit) {
          // Update existing
          setLabResults(labResults.map(r => 
              r.id === labResultToEdit.id 
              ? { ...r, title: data.title, notes: data.notes, images: tempLabResultImages } 
              : r
          ));
      } else if (tempLabResultImages.length > 0) {
          // Create new
          const newResult: LabResult = {
              id: Date.now().toString(),
              timestamp: Date.now(),
              images: tempLabResultImages,
              title: data.title,
              notes: data.notes
          };
          setLabResults([newResult, ...labResults]);
      }
      
      setLabResultToEdit(null);
      setTempLabResultImages([]);
      setIsLabResultModalOpen(false);
  };

  const handleDeleteLabResult = (id: string) => {
      if (window.confirm('هل أنت متأكد من حذف هذه النتيجة نهائياً؟')) {
          setLabResults(prevResults => prevResults.filter(r => r.id !== id));
      }
  };
  
  // --- Menopause Handlers ---
  const handleUpdateMenopauseLog = (count: number) => {
      const today = new Date().toISOString().split('T')[0];
      const existingEntryIndex = menopauseLog.findIndex(l => l.date === today);
      
      if (existingEntryIndex >= 0) {
          const updatedLog = [...menopauseLog];
          updatedLog[existingEntryIndex] = { ...updatedLog[existingEntryIndex], count };
          setMenopauseLog(updatedLog);
      } else {
          setMenopauseLog([...menopauseLog, { date: today, count }]);
      }
  };

  // --- Appointments Handlers ---
  const handleSaveAppointment = (appointment: Appointment) => {
      if (appointmentToEdit) {
          setAppointments(appointments.map(a => a.id === appointment.id ? appointment : a));
      } else {
          setAppointments([...appointments, appointment]);
      }
      setAppointmentToEdit(null);
      setIsAppointmentModalOpen(false);
  };

  const handleDeleteAppointment = (id: string) => {
      if (window.confirm('هل أنت متأكد من حذف هذا الموعد؟')) {
          setAppointments(appointments.filter(a => a.id !== id));
      }
  };

  const handleEditAppointment = (appointment: Appointment) => {
      setAppointmentToEdit(appointment);
      setIsAppointmentModalOpen(true);
  };


  // --- Image Processing using Gemini ---
  const handleAddWithPhoto = () => {
    setIsAddOptionModalOpen(false);
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setIsProcessingImage(true);
      try {
        const base64Data = await fileToBase64(file);
        
        const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: {
                parts: [
                    { inlineData: { mimeType: file.type || 'image/jpeg', data: base64Data } },
                    { text: 'Analyze this medication image. Extract the medication Brand Name (or Scientific Name if Brand is not clear), the Dosage strength (e.g., 500mg, 10 mg/ml), and recommended Frequency in hours if visible (otherwise default to 8). Output strictly JSON with keys: name, dosage, frequency (number).' }
                ]
            },
            config: {
                responseMimeType: 'application/json'
            }
        });

        if (response.text) {
             const data = JSON.parse(response.text);
             setMedicationToEdit({
                name: data.name || 'دواء غير معروف',
                dosage: data.dosage || '',
                frequency: typeof data.frequency === 'number' ? data.frequency : 8
             });
             setIsMedicationModalOpen(true);
        }
      } catch (error) {
         console.error("AI processing error:", error);
         alert("تعذر استخراج البيانات من الصورة. يرجى المحاولة مرة أخرى أو الإدخال يدوياً.");
      } finally {
        setIsProcessingImage(false);
        // Reset file input to allow selecting the same file again
        if (event.target) event.target.value = '';
      }
    }
  };

  const handleTestNotification = (pattern: 'default' | 'short' | 'long' | 'pulse') => {
      if ('vibrate' in navigator) {
          switch (pattern) {
              case 'short': navigator.vibrate(200); break;
              case 'long': navigator.vibrate(1000); break;
              case 'pulse': navigator.vibrate([200, 100, 200]); break;
              default: navigator.vibrate([500, 200, 500]); break;
          }
      }
      
      if ('Notification' in window && Notification.permission !== 'granted') {
          Notification.requestPermission();
      } else if ('Notification' in window && Notification.permission === 'granted') {
          new Notification('تجربة الإشعار', {
              body: 'هذا مثال على إشعار التذكير بالدواء',
              icon: 'https://cdn-icons-png.flaticon.com/512/822/822163.png'
          });
      }
  };
  
  const handleEmergency = () => {
      if (userProfile.guardianEnabled && userProfile.guardianName) {
          setIsEmergencyActive(true);
          // Simulate sending alert
          setTimeout(() => {
              alert(`تم إرسال تنبيه طوارئ إلى المراقب: ${userProfile.guardianName}`);
              setIsEmergencyActive(false);
          }, 1500);
      } else {
          alert('يرجى تفعيل المراقب الدوائي وتحديد الاسم من الإعدادات لاستخدام زر الطوارئ.');
      }
  };
  
  const handleAdClick = () => {
      setShopInitialProduct('giniwa');
      setActiveView('shop');
  };

  return (
    <div className={`min-h-screen pb-20 font-sans text-gray-900 ${getThemeColors(userProfile.theme)} transition-colors duration-500`}>
      <Header 
        activeView={activeView} 
        onNavigate={(view) => { setActiveView(view); setShopInitialProduct(null); }} 
        userName={userProfile.name} 
        onSearch={activeView === 'medications' ? setSearchQuery : undefined}
        searchQuery={searchQuery}
      />
      
      <main className="container mx-auto px-4 py-6 max-w-lg">
        {activeView === 'home' && (
           <div className="animate-fade-in space-y-6">
              {/* Health Tips Banners */}
              <HealthTipBanner userProfile={userProfile} />
              
              {userProfile.gender === 'أنثى' && userProfile.isPregnant && (
                 <PregnancyTipsBanner userName={userProfile.name} />
              )}
              
              <PharmacistBanner />
              
              <QuickActions 
                 onNavigate={(view) => { setActiveView(view); setShopInitialProduct(null); }} 
                 onOpenHealthReport={() => setIsHealthReportModalOpen(true)}
                 onEmergency={handleEmergency}
                 userProfile={userProfile}
              />
              
              <div className="bg-white rounded-xl shadow-sm p-4 border border-gray-100">
                  <h2 className="text-lg font-bold text-gray-800 mb-3 border-b pb-2">ملخص سريع</h2>
                  <div className="flex justify-between text-center">
                      <div>
                          <p className="text-2xl font-bold text-[#5fb8a8]">{medications.filter(m => !m.isArchived).length}</p>
                          <p className="text-xs text-gray-500">أدوية نشطة</p>
                      </div>
                      <div>
                          <p className="text-2xl font-bold text-blue-500">{doseLog.filter(l => l.timestamp > Date.now() - 86400000).length}</p>
                          <p className="text-xs text-gray-500">جرعات اليوم</p>
                      </div>
                      <div>
                          <p className="text-2xl font-bold text-purple-500">{Math.round(medications.filter(m => !m.isArchived).reduce((acc, m) => acc + (m.remainingDoses || 0), 0) / (medications.filter(m => !m.isArchived && m.remainingDoses).length || 1)) || 0}</p>
                          <p className="text-xs text-gray-500">متوسط المخزون</p>
                      </div>
                  </div>
              </div>

              <AdBanner onNavigateToProduct={handleAdClick} />
           </div>
        )}

        {activeView === 'medications' && (
          <div className="animate-fade-in pb-20">
            {/* Inline Search removed as per request */}
            <MedicationList 
              medications={medications} 
              onEdit={handleEditMedication} 
              onDelete={handleDeleteMedication} 
              onRestore={handleRestoreMedication}
              onDoseTaken={handleDoseTaken}
              searchQuery={searchQuery}
              justTakenMedId={justTakenMedId}
            />
          </div>
        )}

        {activeView === 'log' && (
          <div className="animate-fade-in pb-20">
            <h2 className="text-2xl font-bold mb-6 text-gray-800">سجل الالتزام</h2>
            <AdherenceLog doseLog={doseLog} />
          </div>
        )}

        {activeView === 'bloodSugar' && (
            <div className="animate-fade-in pb-20">
                <h2 className="text-2xl font-bold mb-6 text-gray-800">سجل سكر الدم</h2>
                <BloodSugarLogComponent 
                    bloodSugarLog={bloodSugarLog} 
                    onAddReading={() => setIsBloodSugarModalOpen(true)}
                    onOpenReport={() => setIsBloodSugarReportModalOpen(true)}
                />
            </div>
        )}

        {activeView === 'bloodPressure' && (
            <BloodPressureLogComponent 
                bloodPressureLog={bloodPressureLog}
                onAddReading={() => { setBloodPressureToEdit(null); setIsBloodPressureModalOpen(true); }}
                onEditReading={(reading) => { setBloodPressureToEdit(reading); setIsBloodPressureModalOpen(true); }}
                onDeleteReading={handleDeleteBloodPressure}
                onOpenReport={() => setIsBloodPressureReportModalOpen(true)}
            />
        )}

        {activeView === 'symptoms' && (
            <div className="animate-fade-in pb-20">
                <h2 className="text-2xl font-bold mb-6 text-gray-800">سجل الأعراض</h2>
                <SymptomLogComponent 
                    symptomLog={symptomLog}
                    onAddSymptom={() => { setSymptomToEdit(null); setIsSymptomModalOpen(true); }}
                    onEditSymptom={handleEditSymptom}
                    onDeleteSymptom={handleDeleteSymptom}
                    medications={medications}
                />
            </div>
        )}
        
        {activeView === 'pregnancy' && (
            <div className="animate-fade-in pb-20">
               <PregnancyCare />
            </div>
        )}

        {activeView === 'labResults' && (
            <LabResultsLog 
                labResults={labResults} 
                onAddResult={handleCaptureLabResult}
                onEditResult={handleEditLabResult}
                onDeleteResult={handleDeleteLabResult} 
            />
        )}

        {activeView === 'menopause' && (
            <MenopauseInfo 
                log={menopauseLog}
                onLogUpdate={handleUpdateMenopauseLog}
            />
        )}

        {activeView === 'puberty' && (
            <PubertyInfo />
        )}

        {activeView === 'shop' && (
            <ShopView initialExpandedProduct={shopInitialProduct} />
        )}

        {activeView === 'appointments' && (
            <AppointmentsList 
                appointments={appointments}
                onAddAppointment={() => { setAppointmentToEdit(null); setIsAppointmentModalOpen(true); }}
                onEditAppointment={handleEditAppointment}
                onDeleteAppointment={handleDeleteAppointment}
            />
        )}
      </main>

      <Footer 
        activeView={activeView} 
        onNavigate={(view) => { setActiveView(view); setShopInitialProduct(null); }}
        onAddMedication={() => setIsAddOptionModalOpen(true)}
        onProfileClick={() => setIsProfileModalOpen(true)}
      />

      <MedicationFormModal
        isOpen={isMedicationModalOpen}
        onClose={() => { setIsMedicationModalOpen(false); setMedicationToEdit(null); setIsBirthControlMode(false); }}
        onSave={handleSaveMedication}
        medicationToEdit={medicationToEdit}
        isBirthControlMode={isBirthControlMode}
        userProfile={userProfile}
      />

      <ProfileModal
        isOpen={isProfileModalOpen}
        onClose={() => setIsProfileModalOpen(false)}
        onSave={handleSaveProfile}
        userProfile={userProfile}
        onTestNotification={handleTestNotification}
        onOpenHealthReport={() => setIsHealthReportModalOpen(true)}
      />

      <AddOptionModal
        isOpen={isAddOptionModalOpen}
        onClose={() => setIsAddOptionModalOpen(false)}
        onAddManually={() => { setIsAddOptionModalOpen(false); setMedicationToEdit(null); setIsMedicationModalOpen(true); }}
        onAddWithPhoto={handleAddWithPhoto}
        onAddBirthControl={() => { setIsAddOptionModalOpen(false); setIsBirthControlMode(true); setIsMedicationModalOpen(true); }}
        userProfile={userProfile}
      />
      
      <BloodSugarFormModal 
        isOpen={isBloodSugarModalOpen}
        onClose={() => setIsBloodSugarModalOpen(false)}
        onSave={handleSaveBloodSugar}
      />
      
      <BloodPressureFormModal
        isOpen={isBloodPressureModalOpen}
        onClose={() => { setIsBloodPressureModalOpen(false); setBloodPressureToEdit(null); }}
        onSave={handleSaveBloodPressure}
        readingToEdit={bloodPressureToEdit}
      />

      <SymptomFormModal 
        isOpen={isSymptomModalOpen}
        onClose={() => { setIsSymptomModalOpen(false); setSymptomToEdit(null); }}
        onSave={handleSaveSymptom}
        medications={medications}
        symptomToEdit={symptomToEdit}
      />
      
      <AppointmentFormModal 
        isOpen={isAppointmentModalOpen}
        onClose={() => { setIsAppointmentModalOpen(false); setAppointmentToEdit(null); }}
        onSave={handleSaveAppointment}
        appointmentToEdit={appointmentToEdit}
      />

      <HealthReportModal
        isOpen={isHealthReportModalOpen}
        onClose={() => setIsHealthReportModalOpen(false)}
        userProfile={userProfile}
        medications={medications}
        doseLog={doseLog}
      />
      
      <BloodSugarReportModal
         isOpen={isBloodSugarReportModalOpen}
         onClose={() => setIsBloodSugarReportModalOpen(false)}
         userProfile={userProfile}
         bloodSugarLog={bloodSugarLog}
      />

      <BloodPressureReportModal
         isOpen={isBloodPressureReportModalOpen}
         onClose={() => setIsBloodPressureReportModalOpen(false)}
         userProfile={userProfile}
         bloodPressureLog={bloodPressureLog}
      />

      <LabResultFormModal
          isOpen={isLabResultModalOpen}
          onClose={() => { 
              setIsLabResultModalOpen(false); 
              setTempLabResultImages([]); 
              setLabResultToEdit(null); 
          }}
          onSave={handleSaveLabResult}
          images={tempLabResultImages}
          onAddImage={handleAddMoreImages}
          onRemoveImage={handleRemoveTempImage}
          labResultToEdit={labResultToEdit}
      />
      
      {/* Active Medication Reminder Overlay */}
      {activeReminderMedication && (
          <DoseReminderOverlay 
              medication={activeReminderMedication}
              onTake={() => handleDoseTaken(activeReminderMedication)}
              onSkip={() => handleSkipDose(activeReminderMedication)}
              onSnooze={() => handleSnoozeDose(activeReminderMedication)}
          />
      )}

      {/* Hidden inputs for file uploads */}
      <input 
        type="file" 
        ref={fileInputRef} 
        style={{ display: 'none' }} 
        accept="image/*" 
        onChange={handleFileChange} 
      />
      <input 
        type="file" 
        ref={labResultInputRef} 
        style={{ display: 'none' }} 
        accept="image/*"
        multiple
        onChange={handleLabResultFileChange} 
      />

      {isProcessingImage && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex flex-col justify-center items-center z-[60]">
            <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-b-4 border-white mb-4"></div>
            <p className="text-white text-lg font-bold">جاري معالجة الصورة...</p>
        </div>
      )}
      
      {isEmergencyActive && (
        <div className="fixed inset-0 bg-red-600 bg-opacity-90 flex flex-col justify-center items-center z-[70] animate-pulse">
            <BellAlertIcon className="w-24 h-24 text-white mb-4" />
            <p className="text-white text-2xl font-bold">جاري إرسال التنبيه...</p>
        </div>
      )}
    </div>
  );
};

export default App;
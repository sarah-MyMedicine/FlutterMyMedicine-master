

export interface Medication {
  id: string;
  name: string;
  dosage: string;
  frequency: number; // in hours
  nextDose: number; // timestamp
  notes?: string;
  lastNotified?: number; // timestamp of last notification for the current nextDose
  guardianNotified?: boolean; // flag for guardian notification for the current nextDose

  // Inventory tracking fields
  quantity?: number;
  remainingDoses?: number;
  refillThreshold?: number;
  refillNotified?: boolean;

  // FIX: Add properties for AI-fetched medication information
  info?: {
    sideEffects?: string[];
    warnings?: string[];
  };
  isFetchingInfo?: boolean;

  // Cyclic medication fields (e.g., for birth control)
  isCyclic?: boolean;
  activeDays?: number;
  restDays?: number;
  cycleStartDate?: number; // timestamp

  // Archive status
  isArchived?: boolean;
}

export interface UserProfile {
  name: string;
  age?: string;
  gender?: 'ذكر' | 'أنثى' | 'أفضل عدم القول';
  country?: string;
  city?: string;
  vibrationPattern?: 'default' | 'short' | 'long' | 'pulse';
  // Medication Guardian fields
  guardianName?: string;
  guardianEnabled?: boolean;
  // Pregnancy status for females
  isPregnant?: boolean;
  // App Theme
  theme?: 'default' | 'blue' | 'green' | 'pink' | 'purple' | 'yellow';
  // Chronic Conditions
  chronicConditions?: string[];
}

export interface DoseLog {
  medicationId: string;
  medicationName: string;
  dosage: string;
  timestamp: number;
}

export interface BloodSugarLog {
  id: string;
  timestamp: number;
  value: number;
  notes?: string;
}

export interface BloodPressureLog {
  id: string;
  timestamp: number;
  systolic: number; // Upper number
  diastolic: number; // Lower number
  pulse?: number; // Heart rate
  notes?: string;
}

export interface SymptomLog {
  id: string;
  timestamp: number;
  symptom: string;
  severity: 'خفيف' | 'متوسط' | 'شديد';
  notes?: string;
  // Pharmacovigilance fields
  isReported?: boolean;
  relatedMedicationId?: string;
  // Patient conditions context
  patientConditions?: {
    hasAllergy: boolean;
    isSmoker: boolean;
    hasKidneyIssue: boolean;
    hasLiverIssue: boolean;
  };
}

export interface LabResult {
  id: string;
  timestamp: number;
  images: string[]; // Array of Data URLs (e.g., data:image/jpeg;base64,...)
  title?: string;
  notes?: string;
}

export interface MenopauseLog {
    date: string; // YYYY-MM-DD
    count: number;
}

export interface WaterLog {
    date: string; // YYYY-MM-DD
    amount: number; // in ml
}

export interface Appointment {
    id: string;
    doctorName: string;
    specialty: string;
    date: string; // YYYY-MM-DD
    time: string; // HH:mm
    location?: string;
    notes?: string; // Questions for the doctor
}
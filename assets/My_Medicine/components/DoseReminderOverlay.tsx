
import React, { useEffect, useRef } from 'react';
import { Medication } from '../types';
import { ColorPillsIcon, CheckCircleIcon, XMarkIcon, ClockIcon } from './icons';

interface DoseReminderOverlayProps {
  medication: Medication;
  onTake: () => void;
  onSkip: () => void;
  onSnooze: () => void;
}

const DoseReminderOverlay: React.FC<DoseReminderOverlayProps> = ({ medication, onTake, onSkip, onSnooze }) => {
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    // Play a gentle notification sound if available
    // Note: Browsers block auto-play without interaction, so this works best if user is already interacting
    // or if the app is PWA installed.
    try {
        const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
        audio.volume = 0.5;
        audio.play().catch(e => console.log('Audio play blocked:', e));
        audioRef.current = audio;
    } catch (e) {
        console.error("Audio error", e);
    }
    
    // Vibrate device
    if ('vibrate' in navigator) {
        navigator.vibrate([500, 200, 500, 200, 1000]);
    }

    return () => {
        if (audioRef.current) {
            audioRef.current.pause();
            audioRef.current = null;
        }
    };
  }, [medication.id]);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-80 flex flex-col justify-center items-center z-[100] p-6 backdrop-blur-sm animate-fade-in">
      <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden relative">
        {/* Header / Icon Area */}
        <div className="bg-gradient-to-b from-[#5fb8a8] to-teal-600 p-8 flex flex-col items-center justify-center text-white relative">
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden opacity-20">
                <div className="absolute top-[-20px] right-[-20px] w-32 h-32 bg-white rounded-full blur-2xl"></div>
                <div className="absolute bottom-[-20px] left-[-20px] w-24 h-24 bg-teal-900 rounded-full blur-2xl"></div>
            </div>
            
            <div className="bg-white/20 p-4 rounded-full backdrop-blur-md shadow-inner mb-4 animate-bounce">
                <ColorPillsIcon className="w-20 h-20" />
            </div>
            <h2 className="text-xl font-medium opacity-90">حان وقت الدواء!</h2>
        </div>

        {/* Content */}
        <div className="p-8 text-center">
            <h1 className="text-3xl font-bold text-gray-800 mb-2">{medication.name}</h1>
            <p className="text-xl text-[#5fb8a8] font-semibold mb-6">{medication.dosage}</p>
            
            {medication.notes && (
                <div className="bg-gray-50 p-3 rounded-lg mb-8 text-gray-600 text-sm italic">
                    "{medication.notes}"
                </div>
            )}

            {/* Actions */}
            <div className="space-y-4">
                <button 
                    onClick={onTake}
                    className="w-full bg-[#5fb8a8] hover:bg-[#4a9184] text-white py-4 rounded-xl font-bold text-lg shadow-lg hover:shadow-xl transform hover:-translate-y-1 transition-all flex items-center justify-center gap-3"
                >
                    <div className="bg-white/20 p-1 rounded-full">
                        <CheckCircleIcon className="w-6 h-6" />
                    </div>
                    <span>أخذت الدواء</span>
                </button>

                <div className="grid grid-cols-2 gap-4">
                    <button 
                        onClick={onSnooze}
                        className="bg-amber-100 hover:bg-amber-200 text-amber-800 py-3 rounded-xl font-bold text-base shadow-sm hover:shadow-md transition-all flex items-center justify-center gap-2"
                    >
                        <ClockIcon className="w-5 h-5" />
                        <span>غفوة (15د)</span>
                    </button>
                    <button 
                        onClick={onSkip}
                        className="bg-gray-100 hover:bg-gray-200 text-gray-600 hover:text-red-600 py-3 rounded-xl font-bold text-base shadow-sm hover:shadow-md transition-all flex items-center justify-center gap-2"
                    >
                        <XMarkIcon className="w-5 h-5" />
                        <span>تخطّي</span>
                    </button>
                </div>
            </div>
        </div>
      </div>
    </div>
  );
};

export default DoseReminderOverlay;

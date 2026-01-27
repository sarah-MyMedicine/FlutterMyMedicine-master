
import React, { useMemo } from 'react';
import { ColorPregnantIcon } from './icons';

interface PregnancyTipsBannerProps {
  userName: string;
}

const PregnancyTipsBanner: React.FC<PregnancyTipsBannerProps> = ({ userName }) => {
  const tips = [
    "شرب الماء بكثرة يساعد في الحفاظ على مستوى السائل الأمنيوسي حول الجنين.",
    "أنتِ تقومين بعمل رائع! تذكري أن راحتك هي راحة لجنينك.",
    "حاولي المشي لمدة 20 دقيقة يومياً لتحسين الدورة الدموية وتقليل التوتر.",
    "تناولي وجبات صغيرة ومتكررة لتجنب الغثيان والحفاظ على طاقتك.",
    "النوم على الجانب الأيسر يعزز تدفق الدم والمواد المغذية إلى المشيمة.",
    "استمعي لجسدك، إذا شعرتِ بالتعب، فلا تترددي في أخذ قيلولة.",
    "تناول الأطعمة الغنية بالحديد مثل السبانخ والعدس يحميكِ من فقر الدم.",
    "تحدثي مع طفلك، فهو يبدأ في سماع صوتك وتمييزه في الأشهر الأخيرة.",
    "لا تنسي فيتامينات الحمل، فهي ضرورية لنمو طفلك بشكل سليم.",
    "ابتسامتك وهدوؤك ينتقلان إلى طفلك، حافظي على إيجابيتك.",
    "تورم القدمين طبيعي، حاولي رفعهما عند الجلوس لتقليل الاحتباس.",
    "أنتِ قوية، وكل يوم يمر يقربك أكثر من لحظة اللقاء الأجمل.",
    "الكالسيوم مهم جداً الآن، احرصي على شرب الحليب أو تناول الزبادي.",
    "التنفس العميق والاسترخاء يساعدانك على تجاوز لحظات القلق.",
    "اهتمامك بصحتك اليوم هو أعظم هدية تقدمينها لمستقبل طفلك."
  ];

  // Generate a consistent daily index based on the date
  const tipOfTheDay = useMemo(() => {
    const today = new Date();
    // Use day of year to rotate tips
    const start = new Date(today.getFullYear(), 0, 0);
    const diff = today.getTime() - start.getTime();
    const oneDay = 1000 * 60 * 60 * 24;
    const dayOfYear = Math.floor(diff / oneDay);
    
    return tips[dayOfYear % tips.length];
  }, []);

  return (
    <div className="bg-gradient-to-r from-pink-50 to-rose-50 border border-pink-100 rounded-2xl p-5 mb-6 shadow-sm relative overflow-hidden animate-fade-in group hover:shadow-md transition-shadow">
      
      {/* Decorative floral/soft elements */}
      <div className="absolute top-0 right-0 w-24 h-24 bg-pink-200 opacity-20 rounded-full -mt-10 -mr-10 blur-xl"></div>
      <div className="absolute bottom-0 left-0 w-20 h-20 bg-rose-200 opacity-20 rounded-full -mb-8 -ml-8 blur-xl"></div>

      <div className="flex flex-row items-start gap-4 relative z-10">
        <div className="bg-white p-2 rounded-full shadow-sm border border-pink-100 text-pink-500 shrink-0">
            <ColorPregnantIcon className="w-8 h-8" />
        </div>
        
        <div className="flex-1">
            <h3 className="font-bold text-gray-800 text-sm mb-1">
               {userName ? `صباح الخير يا ${userName} 🌸` : 'نصيحة اليوم لكِ ولطفلك 🌸'}
            </h3>
            <p className="text-gray-700 text-base leading-relaxed font-medium">
                "{tipOfTheDay}"
            </p>
             <div className="mt-2 flex items-center gap-1">
                <span className="h-1 w-1 bg-pink-400 rounded-full"></span>
                <span className="text-[10px] text-pink-500 font-semibold">نحن نهتم بكِ</span>
            </div>
        </div>
      </div>
    </div>
  );
};

export default PregnancyTipsBanner;

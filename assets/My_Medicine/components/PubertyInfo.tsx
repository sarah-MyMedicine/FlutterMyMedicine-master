
import React from 'react';
import { ColorButterflyIcon, CheckCircleIcon, SparklesIcon } from './icons';

const PubertyInfo: React.FC = () => {
  return (
    <div className="animate-fade-in pb-20">
        <div className="bg-gradient-to-br from-pink-50 to-rose-100 rounded-2xl p-6 mb-6 shadow-sm border border-pink-100">
            <div className="flex items-center gap-4 mb-4">
                <div className="bg-white p-3 rounded-full shadow-sm">
                    <ColorButterflyIcon className="w-12 h-12" />
                </div>
                <div>
                    <h2 className="text-2xl font-bold text-gray-800">مرحلة البلوغ: زهرة العمر</h2>
                    <p className="text-pink-600 font-medium">خطواتك الأولى نحو الأنوثة والنضج</p>
                </div>
            </div>
            <p className="text-gray-700 leading-relaxed">
                مرحلة البلوغ هي فترة انتقالية طبيعية وجميلة تحدث فيها تغيرات جسدية ونفسية. هذه التغيرات دليل على أن جسمك ينمو ويصبح أكثر صحة وقوة. لا تقلقي، فكل ما تمرين به هو جزء من رحلتك لتصبحي شابة رائعة.
            </p>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 mb-6 border-l-4 border-l-pink-400">
            <h3 className="text-xl font-bold text-pink-700 mb-4 flex items-center gap-2">
                <span className="text-2xl">🛁</span>
                النظافة الشخصية والعناية بالجسم
            </h3>
            <div className="space-y-4 text-gray-700">
                <p>
                    مع تغير الهرمونات، قد تلاحظين زيادة في التعرق أو ظهور حب الشباب. الاهتمام بالنظافة ليس فقط للصحة، بل لتعزيز ثقتك بنفسك.
                </p>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-2">
                    <div className="bg-blue-50 p-4 rounded-lg">
                        <h4 className="font-bold text-blue-800 mb-2">روتين يومي مقترح:</h4>
                        <ul className="list-disc list-inside text-sm text-gray-700 space-y-1">
                            <li>الاستحمام اليومي بالماء والصابون اللطيف.</li>
                            <li>استخدام مزيل عرق طبيعي وآمن.</li>
                            <li>غسل الوجه مرتين يومياً (صباحاً ومساءً) لتجنب الحبوب.</li>
                            <li>تبديل الملابس الداخلية يومياً واختيار الأنواع القطنية.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 mb-6 border-l-4 border-l-rose-500">
            <h3 className="text-xl font-bold text-rose-700 mb-4 flex items-center gap-2">
                <span className="text-2xl">🌸</span>
                الدورة الشهرية واستخدام الفوط الصحية
            </h3>
            <p className="text-gray-600 mb-4">
                الدورة الشهرية هي علامة صحة ونضج. العناية الصحيحة خلال هذه الأيام تحميكِ من الالتهابات وتشعرك بالراحة.
            </p>

            <div className="bg-rose-50 p-4 rounded-lg border border-rose-100 mb-4">
                 <h4 className="font-bold text-rose-800 mb-3 flex items-center gap-2">
                    <CheckCircleIcon className="w-5 h-5" />
                    قواعد ذهبية لاستخدام الفوط الصحية:
                 </h4>
                 <ul className="space-y-3 text-gray-700 text-sm">
                    <li className="flex gap-2 items-start bg-white p-2 rounded-md shadow-sm">
                        <span className="text-rose-500 font-bold">1.</span>
                        <span><strong>التغيير المستمر:</strong> يجب تغيير الفوطة الصحية كل 4 إلى 6 ساعات كحد أقصى، حتى لو لم تكن ممتلئة، لمنع نمو البكتيريا والروائح الكريهة.</span>
                    </li>
                    <li className="flex gap-2 items-start bg-white p-2 rounded-md shadow-sm">
                        <span className="text-rose-500 font-bold">2.</span>
                        <span><strong>النظافة عند التغيير:</strong> اغسلي يديكِ جيداً قبل وبعد تغيير الفوطة. عند التنظيف الشخصي، امسحي دائماً من الأمام إلى الخلف (وليس العكس) لمنع انتقال الجراثيم.</span>
                    </li>
                    <li className="flex gap-2 items-start bg-white p-2 rounded-md shadow-sm">
                        <span className="text-rose-500 font-bold">3.</span>
                        <span><strong>اختيار النوع المناسب:</strong> اختاري فوطاً قطنية ناعمة لتجنب الحساسية، واستخدمي الحجم المناسب لغزارة الدورة (فوط ليلية للنوم، وعادية للنهار).</span>
                    </li>
                 </ul>
            </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-5 border border-gray-100">
            <h3 className="font-bold text-gray-800 mb-3 text-lg flex items-center gap-2">
                <SparklesIcon className="w-5 h-5 text-yellow-500" />
                نصائح لتعزيز ثقتك بنفسك
            </h3>
            <ul className="space-y-3 text-gray-600">
                <li className="flex gap-2 items-start">
                    <span className="text-pink-500">♥</span>
                    <span>أحبي شكلك الجديد وتقبلي التغيرات، فهي تجعل منكِ شخصاً مميزاً.</span>
                </li>
                <li className="flex gap-2 items-start">
                    <span className="text-pink-500">♥</span>
                    <span>لا تقارني نفسك بالأخريات، فلكل فتاة توقيت خاص لنموها.</span>
                </li>
                <li className="flex gap-2 items-start">
                    <span className="text-pink-500">♥</span>
                    <span>تحدثي مع والدتك أو أختك الكبرى عن أي تساؤلات، فلا خجل في العلم والصحة.</span>
                </li>
            </ul>
        </div>
    </div>
  );
};

export default PubertyInfo;

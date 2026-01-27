
import React, { useState, useEffect } from 'react';
import { CapsuleIcon, SparklesIcon, ShieldCheckIcon, ExclamationTriangleIcon, PlusIcon, CheckCircleIcon } from './icons';

interface ShopViewProps {
    initialExpandedProduct?: string | null;
}

const ShopView: React.FC<ShopViewProps> = ({ initialExpandedProduct }) => {
  const [expandedProduct, setExpandedProduct] = useState<string | null>(null);

  useEffect(() => {
    if (initialExpandedProduct) {
        setExpandedProduct(initialExpandedProduct);
        // Scroll to the product if needed (simple implementation)
        const element = document.getElementById(`product-${initialExpandedProduct}`);
        if (element) {
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }
  }, [initialExpandedProduct]);

  const toggleDetails = (productId: string) => {
    if (expandedProduct === productId) {
        setExpandedProduct(null);
    } else {
        setExpandedProduct(productId);
    }
  };

  return (
    <div className="animate-fade-in pb-20">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-800">المتجر الصحي</h2>
        <p className="text-gray-500 text-sm mt-1">مكملات غذائية ومنتجات مختارة بعناية لصحتك</p>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {/* Giniwa Product Card */}
        <div id="product-giniwa" className={`bg-white rounded-xl shadow-md overflow-hidden border transition-all duration-300 ${expandedProduct === 'giniwa' ? 'ring-2 ring-pink-300 shadow-xl' : 'border-gray-100 hover:shadow-lg'}`}>
          <div className="relative h-48 bg-pink-50 flex items-center justify-center p-4">
             {/* Image Placeholder or Actual Image */}
             <div className="w-full h-full flex items-center justify-center bg-white rounded-lg shadow-sm overflow-hidden">
                <img src="https://www.giniwa.es/wp-content/uploads/2021/04/Giniwa-V-14-capsulas-3D-1.png" alt="Giniwa" className="max-h-full max-w-full object-contain" onError={(e) => {
                    (e.target as HTMLImageElement).src = 'https://placehold.co/400x300/pink/white?text=Giniwa';
                    (e.target as HTMLImageElement).style.display = 'none';
                    (e.target as HTMLImageElement).parentElement!.innerHTML = '<svg class="w-16 h-16 text-pink-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0l-3-3m3 3l3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" /></svg>';
                }} />
             </div>
             <div className="absolute top-2 right-2 bg-pink-500 text-white text-xs font-bold px-2 py-1 rounded-full z-10 shadow-sm">
                لصحة المرأة
             </div>
          </div>
          <div className="p-5">
            <h3 className="font-bold text-xl text-gray-800 mb-1">Giniwa V</h3>
            <p className="text-gray-500 text-sm mb-3">فيتامينات وبروبايوتك لصحة المهبل والمسالك البولية</p>
            
            <div className="flex flex-wrap gap-2 mb-4">
                <span className="bg-gray-100 text-gray-600 text-xs px-2 py-1 rounded-md border border-gray-200">14 كبسولة</span>
                <span className="bg-gray-100 text-gray-600 text-xs px-2 py-1 rounded-md border border-gray-200">كبسولة يومياً</span>
            </div>

            <div className="space-y-2 mb-4">
                <div className="flex items-center gap-2 text-sm text-gray-700">
                    <ShieldCheckIcon className="w-4 h-4 text-green-500" />
                    <span>حماية من الالتهابات المتكررة</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-700">
                    <CheckCircleIcon className="w-4 h-4 text-[#5fb8a8]" />
                    <span>خالي من الغلوتين واللاكتوز</span>
                </div>
                 <div className="flex items-center gap-2 text-sm text-red-500 bg-red-50 p-2 rounded-lg">
                    <ExclamationTriangleIcon className="w-4 h-4" />
                    <span className="font-bold">غير مناسب للحوامل</span>
                </div>
            </div>

            <button 
                onClick={() => toggleDetails('giniwa')}
                className="w-full text-left bg-pink-50 hover:bg-pink-100 p-3 rounded-lg text-pink-800 text-sm font-bold flex justify-between items-center transition-colors mb-3"
            >
                <span>المكونات والفوائد (التفاصيل)</span>
                <span className={`transform transition-transform ${expandedProduct === 'giniwa' ? 'rotate-180' : ''}`}>▼</span>
            </button>

            {expandedProduct === 'giniwa' && (
                <div className="mt-3 space-y-3 bg-gray-50 p-3 rounded-lg text-sm text-gray-700 animate-fade-in border border-gray-100 mb-3">
                    <p className="text-xs text-gray-600 mb-2">
                        تركيبة فريدة تعتمد على اللاكتوباسيلوس والمكونات الطبيعية لاستعادة التوازن الطبيعي.
                    </p>
                    <div>
                        <strong className="text-pink-700 block">🦠 اللاكتوباسيلوس (Lactobacillus)</strong>
                        <span className="text-xs">بكتيريا نافعة تساعد في الحفاظ على بيئة مهبلية صحية ومنع نمو البكتيريا الضارة.</span>
                    </div>
                    <div>
                        <strong className="text-pink-700 block">🌺 الكركديه (Hibiscus)</strong>
                        <span className="text-xs">يحتوي على مركبات الفينول التي تساعد في منع التهابات المسالك البولية.</span>
                    </div>
                    <div>
                        <strong className="text-pink-700 block">🐝 البروبوليس (Propolis)</strong>
                        <span className="text-xs">مضاد حيوي طبيعي وفطري يساعد في تعزيز المناعة الموضعية.</span>
                    </div>
                    <div>
                        <strong className="text-pink-700 block">🥕 فيتامين A</strong>
                        <span className="text-xs">يساهم في الحفاظ على صحة الأغشية المخاطية والجهاز المناعي.</span>
                    </div>
                </div>
            )}

            <div className="flex justify-between items-center mt-4 pt-4 border-t border-gray-50">
                <span className="text-xl font-bold text-[#5fb8a8]">0 د.ع</span>
                <button className="bg-[#5fb8a8] text-white px-4 py-2 rounded-lg font-bold hover:bg-[#4a9184] transition-colors flex items-center gap-2">
                    <PlusIcon className="w-5 h-5" />
                    <span>أضف للسلة</span>
                </button>
            </div>
          </div>
        </div>

        {/* Biofreeze Product Card */}
        <div className="bg-white rounded-xl shadow-md overflow-hidden border border-gray-100 hover:shadow-lg transition-shadow">
          <div className="h-48 bg-gradient-to-br from-blue-400 to-cyan-300 relative group overflow-hidden flex items-center justify-center">
             <div className="text-white opacity-90 transform group-hover:scale-110 transition-transform duration-500">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-24 h-24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 14.25v2.25m3-4.5v4.5m3-6.75v6.75m3-9v9M6 20.25h12A2.25 2.25 0 0 0 20.25 18V6A2.25 2.25 0 0 0 18 3.75H6A2.25 2.25 0 0 0 3.75 6v12A2.25 2.25 0 0 0 6 20.25Z" />
                </svg>
             </div>
             <div className="absolute bottom-0 left-0 w-full h-1/3 bg-gradient-to-t from-blue-900/40 to-transparent"></div>
             <div className="absolute top-2 right-2 bg-white/20 backdrop-blur-md text-white text-xs font-bold px-2 py-1 rounded-full z-10 border border-white/30">
                مسكن آلام
             </div>
          </div>
          <div className="p-5">
            <h3 className="font-bold text-xl text-gray-800 mb-1">Biofreeze Gel</h3>
            <p className="text-gray-500 text-sm mb-4">جل موضعي لتسكين الآلام بتقنية التبريد</p>
            
            <div className="space-y-3 mb-4 bg-blue-50 p-4 rounded-lg border border-blue-100 text-sm text-gray-700">
                <div>
                    <h4 className="font-bold text-blue-800 text-xs mb-1 uppercase tracking-wider">دواعي الاستعمال:</h4>
                    <p className="leading-relaxed">فعال لتخفيف آلام العضلات والمفاصل، آلام الظهر والكتف، التهاب المفاصل، والالتواءات.</p>
                </div>
                <div className="w-full h-px bg-blue-200/50"></div>
                <div>
                    <h4 className="font-bold text-blue-800 text-xs mb-1 uppercase tracking-wider">طريقة العمل:</h4>
                    <p className="leading-relaxed">يمتص بسرعة ويعمل عبر تقنية التبريد (المنثول) لتهدئة مستقبلات الألم فورياً.</p>
                </div>
                 <div className="w-full h-px bg-blue-200/50"></div>
                <div>
                    <h4 className="font-bold text-blue-800 text-xs mb-1 uppercase tracking-wider">أماكن الاستخدام:</h4>
                    <p className="leading-relaxed">اليدين، المعصم، الكوع، القدمين، الكاحل، الركبة، الورك، الظهر، الرقبة، والكتفين.</p>
                </div>
            </div>

            <div className="flex justify-between items-center mt-4 pt-4 border-t border-gray-50">
                <span className="text-xl font-bold text-[#5fb8a8]">0 د.ع</span>
                <button className="bg-[#5fb8a8] text-white px-4 py-2 rounded-lg font-bold hover:bg-[#4a9184] transition-colors flex items-center gap-2">
                    <PlusIcon className="w-5 h-5" />
                    <span>أضف للسلة</span>
                </button>
            </div>
          </div>
        </div>

        {/* Magniplex Product Card */}
        <div id="product-neuro" className="bg-white rounded-xl shadow-md overflow-hidden border border-gray-100 hover:shadow-lg transition-shadow">
          <div className="h-48 bg-gradient-to-br from-emerald-600 to-teal-500 relative group overflow-hidden flex items-center justify-center">
             <div className="text-white opacity-90 transform group-hover:scale-110 transition-transform duration-500">
                {/* Brain Icon */}
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-24 h-24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418" />
                </svg>
             </div>
             <div className="absolute top-2 right-2 bg-white/20 backdrop-blur-md text-white text-xs font-bold px-2 py-1 rounded-full z-10 border border-white/30">
                للذاكرة والطاقة
             </div>
          </div>
          <div className="p-5">
            <h3 className="font-bold text-xl text-gray-800 mb-1">Magniplex</h3>
            <p className="text-gray-500 text-sm mb-3">تركيبة متكاملة لدعم الذاكرة، الأعصاب، والمناعة</p>
            
            <div className="flex flex-wrap gap-2 mb-3">
                <span className="bg-emerald-50 text-emerald-700 text-xs font-bold px-2 py-1 rounded-md border border-emerald-100 flex items-center gap-1">
                    <CheckCircleIcon className="w-3 h-3" />
                    كبسولة مرتين يومياً بعد الأكل
                </span>
            </div>

            <button 
                onClick={() => toggleDetails('neuro')}
                className="w-full text-left bg-emerald-50 hover:bg-emerald-100 p-3 rounded-lg text-emerald-800 text-sm font-bold flex justify-between items-center transition-colors"
            >
                <span>المكونات والفوائد</span>
                <span className={`transform transition-transform ${expandedProduct === 'neuro' ? 'rotate-180' : ''}`}>▼</span>
            </button>

            {expandedProduct === 'neuro' && (
                <div className="mt-3 space-y-3 bg-gray-50 p-3 rounded-lg text-sm text-gray-700 animate-fade-in border border-gray-100">
                    <div>
                        <strong className="text-emerald-700 block">🍃 خلاصة الجنكة بيلوبا (Ginkgo Biloba)</strong>
                        <span className="text-xs">تحسن الذاكرة وتدفق الدم للدماغ والجسم، وتحسن النظر.</span>
                    </div>
                    <div>
                        <strong className="text-emerald-700 block">⚡ سيترات المغنيسيوم (Magnesium Citrate)</strong>
                        <span className="text-xs">يريح عضلات القلب، يقوي العظام، يساعد في الهضم وضبط السكر.</span>
                    </div>
                    <div>
                        <strong className="text-emerald-700 block">🧬 مجموعة فيتامين B المركبة</strong>
                        <ul className="list-disc list-inside text-xs space-y-1 mt-1 pl-1 text-gray-600">
                            <li><strong>B1, B2, B3, B5:</strong> لإنتاج الطاقة، صحة الأعصاب، والنمو.</li>
                            <li><strong>B6, B9, B12:</strong> لتكوين كريات الدم، تحسين المزاج والذاكرة، وصحة القلب.</li>
                            <li><strong>B7 (بيوتين):</strong> لصحة الشعر، الجلد، والأظافر.</li>
                        </ul>
                    </div>
                    <div>
                        <strong className="text-emerald-700 block">🛡️ معادن ومضادات أكسدة</strong>
                        <ul className="list-disc list-inside text-xs space-y-1 mt-1 pl-1 text-gray-600">
                            <li><strong>الزنك (Zinc):</strong> يعزز المناعة والنمو.</li>
                            <li><strong>فيتامين C:</strong> يقوي المناعة، يحسن امتصاص الحديد، وبناء الأنسجة.</li>
                            <li><strong>فيتامين E:</strong> مضاد أكسدة يحمي الخلايا والأنسجة من التلف.</li>
                        </ul>
                    </div>
                </div>
            )}

            <div className="flex justify-between items-center mt-4 pt-4 border-t border-gray-50">
                <span className="text-xl font-bold text-[#5fb8a8]">0 د.ع</span>
                <button className="bg-[#5fb8a8] text-white px-4 py-2 rounded-lg font-bold hover:bg-[#4a9184] transition-colors flex items-center gap-2">
                    <PlusIcon className="w-5 h-5" />
                    <span>أضف للسلة</span>
                </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};

export default ShopView;

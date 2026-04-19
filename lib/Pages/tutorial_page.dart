import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  Widget _sectionTitle(String text, {required TextDirection textDirection, required TextAlign textAlign}) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F766E),
      ),
      textDirection: textDirection,
      textAlign: textAlign,
    );
  }

  Widget _line(
    String text, {
    bool bullet = false,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    final prefix = bullet ? '• ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$prefix$text',
        style: const TextStyle(fontSize: 15, height: 1.5),
        textDirection: textDirection,
        textAlign: textAlign,
      ),
    );
  }

  Widget _warningBox(
    List<String> lines, {
    required String title,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line(title, bullet: false, textDirection: textDirection, textAlign: textAlign),
          for (final line in lines)
            _line(line, bullet: true, textDirection: textDirection, textAlign: textAlign),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final isArabic = sp.language == 'ar';
        final dir = isArabic ? TextDirection.rtl : TextDirection.ltr;
        final align = isArabic ? TextAlign.right : TextAlign.left;

        String t(String ar, String en) => isArabic ? ar : en;

        return Directionality(
          textDirection: dir,
          child: Scaffold(
            backgroundColor: const Color(0xFFF0F9F8),
            appBar: AppBar(
              title: Text(t('كيف استخدم تطبيق دوائي', 'How To Use My Medicine')),
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _card([
                    _sectionTitle(
                      t('إضافة الأدوية والالتزام بها', 'Adding Medication And Staying Adherent'),
                      textDirection: dir,
                      textAlign: align,
                    ),
                    const SizedBox(height: 10),
                    _line(t('1. اضغط على "أدويتي"', '1. Tap "My Medications".'), textDirection: dir, textAlign: align),
                    _line(t('2. اختر "إضافة دواء"', '2. Choose "Add Medication".'), textDirection: dir, textAlign: align),
                    _line(t('3. أدخل بيانات الدواء:', '3. Enter medication details:'), textDirection: dir, textAlign: align),
                    _line(
                      t(
                        'اسم الدواء (يمكن الاضافه يدويا او عن طريق ادخال صورة الدواء)',
                        'Medication name (you can add it manually or by medication image).',
                      ),
                      bullet: true,
                      textDirection: dir,
                      textAlign: align,
                    ),
                    _line(t('عدد الجرعات يوميًا', 'Number of doses per day.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('اسم الطبيب', 'Doctor name.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('4. بعد الحفظ، سيتم إنشاء جدول تلقائي للجرعات', '4. After saving, a dose schedule is created automatically.'), textDirection: dir, textAlign: align),
                    _line(t('5. ستصلك تنبيهات في وقت كل جرعة', '5. You will receive alerts at each dose time.'), textDirection: dir, textAlign: align),
                    _line(t('6. راقب جرعاتك من قسم "سجل الالتزام"', '6. Track your doses from the "Adherence Log" section.'), textDirection: dir, textAlign: align),
                    _line(t('7. تأكد من عدم تفويت أي جرعة', '7. Make sure you do not miss any dose.'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 8),
                    _warningBox(
                      [
                        t('عدّل الدواء فقط عند تغيير وصفة الطبيب', 'Edit medication only when the doctor changes the prescription.'),
                        t('لا تتجاهل التنبيهات لضمان فعالية العلاج', 'Do not ignore alerts to ensure treatment effectiveness.'),
                      ],
                      title: t('⚠️ ملاحظات مهمة', '⚠️ Important Notes'),
                      textDirection: dir,
                      textAlign: align,
                    ),
                    const SizedBox(height: 10),
                    _line(t('🎯 هدفنا: مساعدتك على الالتزام بعلاجك بسهولة وأمان', '🎯 Our goal: Help you stick to treatment safely and easily.'), textDirection: dir, textAlign: align),
                  ]),
                  _card([
                    _sectionTitle(t('سجل الضغط / السكر', 'Blood Pressure / Sugar Log'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 10),
                    _line(
                      t('أدخل الرقم المطلوب الوصول إليه لكل مستخدم (يختلف حسب الحالة الطبية)', 'Enter each user\'s target value (varies by medical condition).'),
                      bullet: true,
                      textDirection: dir,
                      textAlign: align,
                    ),
                    _line(t('هذا الرقم يساعدنا في مقارنة قراءاتك وتحليلها بدقة', 'This number helps us compare and analyze your readings accurately.'), bullet: true, textDirection: dir, textAlign: align),
                    const SizedBox(height: 6),
                    _line(t('ولإضافة قراءة جديدة:', 'To add a new reading:'), textDirection: dir, textAlign: align),
                    _line(t('اضغط على زر (+) الموجود اسفل الصفحه في جهة اليسار لإدخال قراءة جديدة', 'Tap the (+) button at the bottom-left to add a new reading.'), textDirection: dir, textAlign: align),
                    _line(t('سيتم طلب إدخال:', 'You will be asked to enter:'), textDirection: dir, textAlign: align),
                    _line(t('قيمة الضغط أو السكر', 'Blood pressure or blood sugar value.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('ثم اضغط حفظ لحفظ القراءة ووقتها تلقائيا داخل التطبيق', 'Then tap Save to store the reading and time automatically in the app.'), textDirection: dir, textAlign: align),
                  ]),
                  _card([
                    _sectionTitle(t('التقرير الصحي', 'Health Report'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 10),
                    _line(
                      t(
                        'يتم إنشاء تقرير صحي تلقائي لاخر (اسبوع, شهر, 3 اشهر) بناءً التزامك بالادوية وعلى قراءاتك (اذا كنت مريض ضغط او سكر).',
                        'A health report is generated automatically for the last (week, month, 3 months) based on your medication adherence and readings (for pressure/sugar patients).',
                      ),
                      textDirection: dir,
                      textAlign: align,
                    ),
                    _line(t('ويشمل:', 'It includes:'), textDirection: dir, textAlign: align),
                    _line(t('متوسط القراءات التي تم تسجيلها بشكل مرتب حسب التاريخ والوقت', 'Average recorded readings ordered by date and time.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('مقارنة مع الهدف الصحي', 'Comparison with your health target.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('نسبة التزامك الحقيقي باخذ الادويه', 'Your actual medication adherence rate.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('ويتم انشاء التقرير عن طريق الضغط على صورة الفايل باعلى الشاشه على جهة اليسار واختيار المده المراد انشاء التقرير عنها.', 'Create the report by tapping the file icon at the top-left and selecting the desired period.'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 8),
                    _warningBox(
                      [
                        t('هذا النظام يساعدك على المتابعة فقط، ولا يغني عن استشارة الطبيب عند الحاجة', 'This system helps with follow-up only and does not replace medical consultation when needed.'),
                      ],
                      title: t('⚠️ ملاحظة مهمة', '⚠️ Important Note'),
                      textDirection: dir,
                      textAlign: align,
                    ),
                  ]),
                  _card([
                    _sectionTitle(t('المواعيد الطبيه', 'Medical Appointments'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 10),
                    _line(t('هذه الخاصيه تحفظ لك مواعيدك الطبية بعد ان يتم ادخالها من قبلك ومن ثم يرسل لك تذكير قبل الموعد بيوم.', 'This feature saves your appointments and sends a reminder one day before the appointment.'), textDirection: dir, textAlign: align),
                    _line(t('عند النقر على:', 'When you tap:'), textDirection: dir, textAlign: align),
                    _line(t('(اضافة موعد جديد)', '(Add New Appointment).'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('ادخل اسم الطبيب والتخصص', 'Enter doctor name and specialty.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('تاريخ الموعد ووقته', 'Appointment date and time.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('الملاحضات المهمه ان وجدت مثل الاسئله التي تود سؤالها للطبيب', 'Important notes if any, such as questions you want to ask your doctor.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('اضغط على حفظ الموعد', 'Tap Save Appointment.'), bullet: true, textDirection: dir, textAlign: align),
                  ]),
                  _card([
                    _sectionTitle(t('نتائج المختبر', 'Lab Results'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 10),
                    _line(t('هذه الخاصيه تحفظ لك نتائج تحاليلك المختبرية ويمكنك الرجوع اليها في اي وقت:', 'This feature saves your lab test results and lets you return to them any time.'), textDirection: dir, textAlign: align),
                    _line(t('اضغط على علامة + في اسفل الشاشه على جهة اليسار لالتقاط صورة للتحاليل او اختيار صورة من معرض الصور في هاتفك', 'Tap + at the bottom-left to capture or select a lab result image from your gallery.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('بعدها سيظهر لك صندوق وصف لاضافة ملاحضاتك الشخصية وتاريخها', 'Then a description box appears to add personal notes and date.'), bullet: true, textDirection: dir, textAlign: align),
                    _line(t('اضغط على زر (حفظ)', 'Tap (Save).'), bullet: true, textDirection: dir, textAlign: align),
                  ]),
                  _card([
                    _sectionTitle(t('الملف الشخصي', 'Profile'), textDirection: dir, textAlign: align),
                    const SizedBox(height: 10),
                    _line(
                      t(
                        'لمليء بيانات الملف الشخصي فاضغط على مجسم الوجه في الصفحه الرئيسية في اسفل الشاشة على جهة اليسار ثم ادخل البيانات الشخصيه مثل الاسم العمر الجنس والبلد وايضا اذا كنت تعاني من الامراض المزمنه.',
                        'To fill profile data, tap the face icon on the home page at the bottom-left, then enter personal data such as name, age, gender, country, and chronic diseases if any.',
                      ),
                      textDirection: dir,
                      textAlign: align,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

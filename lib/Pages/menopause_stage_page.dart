import 'package:flutter/material.dart';

class MenopauseStageInfoPage extends StatelessWidget {
  const MenopauseStageInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مرحلة سن الأمل'),
          backgroundColor: const Color(0xFF1EBEA6),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.shield_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.location_on_outlined), onPressed: () {}),
          ],
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main card with HRT information
              _buildInfoCard(
                icon: Icons.favorite,
                iconColor: const Color(0xFFE91E63),
                title: 'الهرمونات التعويضية (HRT)',
                content:
                    'العلاج التعويضي بالهرمونات يعتبر حلاً فعالاً للتخفيف من أعراض انقطاع الطمث مثل الهبات الساخنة والتعرق الليلي.',
                subtitle: 'أمان الاستخدام',
                subContent:
                    'أثبتت معظم الدراسات والهيئة (FDA) أنه عند استخدامها! لا يوجد دليل قاطع سببت أي تأثير سرطان الثدي عند استخدامها تحت اشراف طبي. ثبتت التحليلات الحديثة أن استخدامها في جرعات منخفضة أو منتظمة تعتبر آمنة بها ولم يثبت وجودها في تصعيد الحالات والأطباء تنوه بمخاطرها.',
                benefitsList: [
                  'تخفيف الهبات الساخنة.',
                  'الحماية من هشاشة العظام.',
                  'تحسين المزاج والتوى.',
                ],
                consultList: [
                  'إذا كانت الأعراض تؤثر على حياتك.',
                  'تحديد الجرعة المناسبة.',
                  'إذا كان لديك تاريخ مرضي.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? subtitle,
    String? subContent,
    List<String>? benefitsList,
    List<String>? consultList,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
          if (subtitle != null && subContent != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFF1976D2), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subContent,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
          if (benefitsList != null) ...[
            const SizedBox(height: 16),
            const Text(
              'الفوائد:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...benefitsList.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (consultList != null) ...[
            const SizedBox(height: 16),
            const Text(
              'استشيري طبيبتك:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...consultList.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

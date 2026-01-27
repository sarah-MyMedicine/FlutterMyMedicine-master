import 'package:flutter/material.dart';

class PubertyStageInfoPage extends StatelessWidget {
  const PubertyStageInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مرحلة البلوغ'),
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
              // Header section with butterfly
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE6F0), Color(0xFFFFF0F7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحلة البلوغ: زهرة العمر',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD81B60),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'خطواتك الأولى نحو الأنوثة والنضج',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFD81B60),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.flutter_dash,
                          size: 48,
                          color: Color(0xFFD81B60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مرحلة البلوغ هي فترة انتقالية طبيعية وجميلة تحدث فيها تغيرات جسدية ونفسية. هذه التغيرات دليل على أن جسمك ينمو ويصبح أكثر نضجاً. وتفسير هذه التغيرات يساعدك على فهم جسدك بشكل أفضل، مما يمنعك من الشعور بالقلق. كل ما تمرين به هو جزء من رحلتك لتصبحي شابة واثقة.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal hygiene section
              _buildInfoCard(
                icon: Icons.self_improvement,
                iconColor: const Color(0xFF42A5F5),
                title: 'النظافة الشخصية والعناية بالجسم',
                content:
                    'مع تغير الهرمونات، قد تلاحظين زيادة في التعرق أو ظهور حب الشباب. الاهتمام بالنظافة ليس فقط للصحة، بل لتعزز بثقتك بنفسك.',
                subtitle: 'روتين يومي مقترح:',
                bulletPoints: [
                  'الاستحمام اليومي بالماء والصابون اللطيف',
                  'استخدام مزيل عرق طبيعي وآمن',
                  'تبديل الملابس الداخلية يومياً واختيار الأنواع القطنية',
                ],
              ),
              const SizedBox(height: 16),

              // Nutrition section
              _buildInfoCard(
                icon: Icons.restaurant,
                iconColor: const Color(0xFFEC407A),
                title: 'الدورة الشهرية واستخدام الفوط الصحية',
                content:
                    'الدورة الشهرية هي علامة صحة وتحمل العناية الصحيحة خلالها ه.ذه الأيام تعدمل من الالتهابات وتشعرك بالراحة.',
                subtitle: 'قواعد ذهبية لاستخدام الفوط الصحية:',
                bulletPoints: [
                  'التغيير المستمر: يجب تغيير الفوطة الصحية كل 4 أو 6 ساعات كحد أقصى، حتى لو لم تكن ممتلئة، لمنع نمو البكتيريا والروائح الكريهة.',
                  'النظافة عند التغيير: اغسلي يديك جيداً قبل وبعد تغيير الفوطة. عند التنظيف، امسحي دائماً من الأمام إلى الخلف (وليس العكس) لمنع انتقال الجراثيم.',
                  'اختيار النوع المناسب: اختاري فوطاً مطنية وناعمة لتجنب الحساسية. واستخدمي الحجم المناسب لغزارة الدورة (نوط لليلة للنوم وحماية طويلة).',
                ],
              ),
              const SizedBox(height: 16),

              // Tips section
              _buildTipsCard(),
              const SizedBox(height: 24),
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
    List<String>? bulletPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE91E63), width: 2),
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
                    color: Color(0xFFD81B60),
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
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (bulletPoints != null) ...[
                    const SizedBox(height: 12),
                    ...bulletPoints.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  point,
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Text(
                '👏',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 8),
              Text(
                'نصائح لتعزيز ثقتك بنفسك',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6F00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('💖', 'أحبي شكلك الحديث وتقبلي التغيرات، فهي تجعل منك شخصاً مميزاً!'),
          const SizedBox(height: 12),
          _buildTipItem('💖', 'لا تقارني نفسك بالأخريات. كل ما تمرين به هو جزء من رحلتك.'),
          const SizedBox(height: 12),
          _buildTipItem('💖', 'تحدثي مع والديك أو أخناك الكبير عن أي تساؤلات، فلا حرج في العلم والصحة.'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

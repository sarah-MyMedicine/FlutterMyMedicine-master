import 'package:flutter/material.dart';

class MenopauseStageInfoPage extends StatefulWidget {
  const MenopauseStageInfoPage({super.key});

  @override
  State<MenopauseStageInfoPage> createState() => _MenopauseStageInfoPageState();
}

class _MenopauseStageInfoPageState extends State<MenopauseStageInfoPage> {
  int _selectedTab = 0;
  int _hotflashCount = 0;
  int _nightSweatsCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        title: const Text(
          'مرحلة سن الأمل',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF5DABA8),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header card with tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD946A6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.favorite, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text(
                  'مرحلة سن الأمل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'معك في كل خطوة من رحلتك',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Tab buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabButton('متابعة الأعراض', 0),
                      _buildTabButton('صحة وراحة', 1),
                      _buildTabButton('معلومات وهرمونات', 2),
                      _buildTabButton('تغذية', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Progress indicator
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.25,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Content area
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD946A6) : Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildSymptomTrackingTab();
      case 1:
        return _buildHealthComfortTab();
      case 2:
        return _buildInformationTab();
      case 3:
        return _buildNutritionTab();
      default:
        return _buildSymptomTrackingTab();
    }
  }

  Widget _buildSymptomTrackingTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'متابعة الأعراض اليومية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'سجلي أعراضك اليومية لمساعدتك على فهم نمط الأعراض بشكل أفضل.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Hot flashes counter
            _buildSymptomCounter('🔥 عداد الهبات الساخنة (اليوم)', _hotflashCount, () {
              setState(() => _hotflashCount++);
            }, () {
              setState(() {
                if (_hotflashCount > 0) _hotflashCount--;
              });
            }, () {
              setState(() => _hotflashCount = 0);
            }),
            const SizedBox(height: 20),
            // Night sweats counter
            _buildSymptomCounter('💦 عداد التعرق الليلي (الليلة)', _nightSweatsCount, () {
              setState(() => _nightSweatsCount++);
            }, () {
              setState(() {
                if (_nightSweatsCount > 0) _nightSweatsCount--;
              });
            }, () {
              setState(() => _nightSweatsCount = 0);
            }),
            const SizedBox(height: 24),
            // Health tips section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD84315), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Color(0xFFD84315), size: 24),
                      Text(
                        '💡 نصائح مفيدة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD84315),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('البقاء رطبة: اشربي الماء بكثرة خلال اليوم'),
                  _buildTipItem('الملابس الخفيفة: اختاري ملابس قطنية فضفاضة'),
                  _buildTipItem('تجنبي المحفزات: قللي الكافيين والتوابل الحارة'),
                  _buildTipItem('النوم المريح: حاولي النوم في غرفة باردة'),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCounter(
    String title,
    int count,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
    VoidCallback onReset,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD946A6),
            ),
          ),
          const SizedBox(height: 16),
          // Increment and Decrement buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: onDecrement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD946A6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '−',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onIncrement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD946A6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onReset,
            child: const Text(
              '↻ إعادة تعيين',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF333333)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthComfortTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3), width: 1),
              ),
              child: const Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اعتني بنفسك وتقبلي هذه المرحلة من حياتك',
                      style: TextStyle(color: Color(0xFF2196F3), fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              '⚙️ إدارة الأعراض',
              'هناك عدة طرق للتعامل مع أعراض سن الأمل وتحسين جودة الحياة خلال هذه المرحلة.',
              benefitsList: [
                'ممارسة التمارين المنتظمة',
                'الحصول على قسط كافٍ من النوم',
                'تقنيات الاسترخاء والتأمل',
                'دعم الأسرة والأصدقاء',
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              '🏃‍♀️ النشاط البدني',
              'التمارين المنتظمة تساعد في تحسين الصحة العامة والعقلية.',
              benefitsList: [
                'تحسين صحة القلب والأوعية الدموية',
                'تقوية العظام والعضلات',
                'تحسين المزاج والنوم',
                'السيطرة على الوزن',
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildInfoCard(
              '💊 الهرمونات والعلاج الهرموني',
              'العلاج الهرموني يمكن أن يساعد في تخفيف الأعراض المرتبطة بسن الأمل.',
              subtitle: 'ملاحظة مهمة',
              subContent:
                  'تحدثي مع طبيبك قبل بدء أي علاج هرموني لفهم الفوائد والمخاطر المحتملة.',
              benefitsList: [
                'تقليل الهبات الساخنة والتعرق الليلي',
                'تحسين جودة النوم والمزاج',
                'تقليل الجفاف وتحسين صحة الجلد',
                'دعم صحة العظام',
              ],
              consultList: [
                'ما إذا كان العلاج الهرموني مناسباً لك',
                'أي تأثيرات جانبية محتملة',
                'الجرعات والمدة المناسبة للعلاج',
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Nutrition info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '🍽️ التغذية والصحة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'التغذية السليمة تلعب دوراً مهماً في صحتك خلال هذه المرحلة',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Calcium and Magnesium section
            _buildNutritionSection(
              '🥛 الكالسيوم والماغنيسيوم',
              ['🥛', '🧀', '🥦', '🥕', '🍌', '🌰'],
              [
                'اللبن والجبن',
                'الخضروات الورقية',
                'المكسرات',
                'الأسماك',
                'الحبوب الكاملة',
                'البذور'
              ],
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            // Phytoestrogen section
            _buildNutritionSection(
              '🌿 الاستروجين النباتي',
              ['🫘', '🌾', '🥬', '🍎', '🥔', '🫐'],
              [
                'الفول والعدس',
                'منتجات الصويا',
                'البذور',
                'الفواكه',
                'الحبوب الكاملة',
                'المكسرات'
              ],
              const Color(0xFF8BC34A),
            ),
            const SizedBox(height: 16),
            // Heart health section
            _buildNutritionSection(
              '❤️ قلبي معافى',
              ['🐟', '🫒', '🥗', '❤️', '🍇', '🥑'],
              [
                'الأسماك الدهنية',
                'الزيوت الصحية',
                'الخضروات',
                'الفواكه',
                'المكسرات',
                'البذور'
              ],
              const Color(0xFFE91E63),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection(
    String title,
    List<String> emojis,
    List<String> labels,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      emojis[index],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content, {
    String? subtitle,
    String? subContent,
    List<String>? benefitsList,
    List<String>? consultList,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFF1976D2), size: 20),
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
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            ...benefitsList.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
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
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            ...consultList.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
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

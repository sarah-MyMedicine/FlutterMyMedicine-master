import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

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
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFE8F5F3),
            appBar: AppBar(
              title: Text(
                AppTranslations.translate('menopause_stage_title', lang),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              backgroundColor: sp.themeColor,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
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
                    gradient: LinearGradient(
                      colors: [sp.themeColor, Color.lerp(sp.themeColor, Colors.black, 0.15) ?? sp.themeColor],
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
                      Text(
                        AppTranslations.translate('menopause_stage_title', lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppTranslations.translate('with_you_every_step', lang),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Tab buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTabButton(AppTranslations.translate('symptom_tracking', lang), 0),
                            _buildTabButton(AppTranslations.translate('health_comfort', lang), 1),
                            _buildTabButton(AppTranslations.translate('info_hormones', lang), 2),
                            _buildTabButton(AppTranslations.translate('nutrition', lang), 3),
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
                          alignment: lang == 'ar' ? Alignment.centerRight : Alignment.centerLeft,
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
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    final sp = Provider.of<SettingsProvider>(context, listen: false);
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
            color: isSelected ? sp.themeColor : Colors.white,
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
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
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
              child: Column(
                crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate('daily_symptom_tracking', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.translate('log_daily_symptoms', lang),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Hot flashes counter
            _buildSymptomCounter(
              AppTranslations.translate('hot_flashes_counter_today', lang),
              _hotflashCount,
              () {
                setState(() => _hotflashCount++);
              },
              () {
                setState(() {
                  if (_hotflashCount > 0) _hotflashCount--;
                });
              },
              () {
                setState(() => _hotflashCount = 0);
              },
            ),
            const SizedBox(height: 20),
            // Night sweats counter
            _buildSymptomCounter(
              AppTranslations.translate('night_sweats_counter_tonight', lang),
              _nightSweatsCount,
              () {
                setState(() => _nightSweatsCount++);
              },
              () {
                setState(() {
                  if (_nightSweatsCount > 0) _nightSweatsCount--;
                });
              },
              () {
                setState(() => _nightSweatsCount = 0);
              },
            ),
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
                crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (lang == 'en') const Icon(Icons.lightbulb_outline, color: Color(0xFFD84315), size: 24),
                      Text(
                        AppTranslations.translate('useful_tips', lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD84315),
                        ),
                      ),
                      if (lang == 'ar') const Icon(Icons.lightbulb_outline, color: Color(0xFFD84315), size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(AppTranslations.translate('stay_hydrated', lang)),
                  _buildTipItem(AppTranslations.translate('light_clothing', lang)),
                  _buildTipItem(AppTranslations.translate('avoid_triggers', lang)),
                  _buildTipItem(AppTranslations.translate('comfortable_sleep', lang)),
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
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
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
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: sp.themeColor,
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
                  backgroundColor: sp.themeColor,
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
                  backgroundColor: sp.themeColor,
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
            child: Text(
              AppTranslations.translate('reset_counter', lang),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF333333)),
              textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthComfortTab() {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
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
              child: Row(
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTranslations.translate('take_care_accept_stage', lang),
                      style: const TextStyle(color: Color(0xFF2196F3), fontSize: 13),
                      textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              AppTranslations.translate('symptom_management', lang),
              AppTranslations.translate('symptom_management_desc', lang),
              benefitsList: [
                AppTranslations.translate('regular_exercise', lang),
                AppTranslations.translate('adequate_sleep', lang),
                AppTranslations.translate('relaxation_meditation', lang),
                AppTranslations.translate('family_support', lang),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              AppTranslations.translate('physical_activity', lang),
              AppTranslations.translate('physical_activity_desc', lang),
              benefitsList: [
                AppTranslations.translate('improve_heart_health', lang),
                AppTranslations.translate('strengthen_bones_muscles', lang),
                AppTranslations.translate('improve_mood_sleep', lang),
                AppTranslations.translate('weight_control', lang),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationTab() {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildInfoCard(
              AppTranslations.translate('hormones_hrt', lang),
              AppTranslations.translate('hormones_hrt_desc', lang),
              subtitle: AppTranslations.translate('important_note', lang),
              subContent: AppTranslations.translate('important_note_desc', lang),
              benefitsList: [
                AppTranslations.translate('reduce_hot_flashes', lang),
                AppTranslations.translate('improve_sleep_mood', lang),
                AppTranslations.translate('reduce_dryness', lang),
                AppTranslations.translate('support_bone_health', lang),
              ],
              consultList: [
                AppTranslations.translate('hrt_suitable', lang),
                AppTranslations.translate('potential_side_effects', lang),
                AppTranslations.translate('dosage_duration', lang),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTab() {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
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
              child: Column(
                crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate('nutrition_health', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.translate('nutrition_health_desc', lang),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Calcium and Magnesium section
            _buildNutritionSection(
              AppTranslations.translate('calcium_magnesium', lang),
              ['🥛', '🧀', '🥦', '🥕', '🍌', '🌰'],
              [
                AppTranslations.translate('milk_cheese', lang),
                AppTranslations.translate('leafy_vegetables', lang),
                AppTranslations.translate('nuts', lang),
                AppTranslations.translate('fish', lang),
                AppTranslations.translate('whole_grains', lang),
                AppTranslations.translate('seeds', lang)
              ],
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            // Phytoestrogen section
            _buildNutritionSection(
              AppTranslations.translate('phytoestrogen', lang),
              ['🫘', '🌾', '🥬', '🍎', '🥔', '🫐'],
              [
                AppTranslations.translate('beans_lentils', lang),
                AppTranslations.translate('soy_products', lang),
                AppTranslations.translate('seeds', lang),
                AppTranslations.translate('fruits', lang),
                AppTranslations.translate('whole_grains', lang),
                AppTranslations.translate('nuts', lang)
              ],
              const Color(0xFF8BC34A),
            ),
            const SizedBox(height: 16),
            // Heart health section
            _buildNutritionSection(
              AppTranslations.translate('healthy_heart', lang),
              ['🐟', '🫒', '🥗', '❤️', '🍇', '🥑'],
              [
                AppTranslations.translate('fatty_fish', lang),
                AppTranslations.translate('healthy_oils', lang),
                AppTranslations.translate('vegetables', lang),
                AppTranslations.translate('fruits', lang),
                AppTranslations.translate('nuts', lang),
                AppTranslations.translate('seeds', lang)
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
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
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
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final lang = sp.language;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
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
                crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (lang == 'en') const Icon(Icons.error_outline, color: Color(0xFF1976D2), size: 20),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      if (lang == 'ar') const Icon(Icons.error_outline, color: Color(0xFF1976D2), size: 20),
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
            Text(
              AppTranslations.translate('benefits', lang),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 8),
            ...benefitsList.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
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
            Text(
              AppTranslations.translate('consult_doctor', lang),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 8),
            ...consultList.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
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

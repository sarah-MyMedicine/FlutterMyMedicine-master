import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class MotherFetusCarePanel extends StatefulWidget {
  const MotherFetusCarePanel({super.key});

  @override
  State<MotherFetusCarePanel> createState() => _MotherFetusCarePanelState();
}

class _MotherFetusCarePanelState extends State<MotherFetusCarePanel> {
  int _selectedTab = 0;
  int _fetalMovementCount = 0;
  DateTime? _pregnancyStartDate;

  // Mother care checklist state
  final Map<String, bool> _motherChecklist = {
    'روب يوم مريح (مفضل للراحة)': false,
    'ملابس داخلية قطنية': false,
    'فوط صحية (حجم كبير)': false,
    'حمالات صدر للرضاعة': false,
    'أدوات العناية الشخصية (فرشاة، شامبو...)': false,
    'ملابس الخروج من المستشفى': false,
  };

  // Child care checklist state
  final Map<String, bool> _childChecklist = {
    'ملابس داخلية (الوِعي) عدد 3': false,
    'أطقم خارجية كاملة عدد 3': false,
    'قبعات وجوارب وقفازات': false,
    'بطانية ناعمة': false,
    'حقاضات مقاس مواليد جديد': false,
    'مناديل مبللة (Wipes)': false,
  };

  // Supplies checklist state
  final Map<String, bool> _suppliesChecklist = {
    'بطاقة الهوية / الإقامة': false,
    'بطاقة التأمين': false,
    'ملف متابعة الحمل والتحاليل': false,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        return Scaffold(
          backgroundColor: const Color(0xFFE8F5F3),
          appBar: AppBar(
            title: Text(
              AppTranslations.translate('mother_fetus_care_title', lang),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            backgroundColor: const Color(0xFF5DABA8),
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
              // Pink header card with tabs
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E7A), Color(0xFFF06292)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.pregnant_woman, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.translate('mother_fetus_care_title', lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppTranslations.translate('support_throughout_journey', lang),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // Tab buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabButton(AppTranslations.translate('pregnancy_summary', lang), 0, lang),
                        _buildTabButton(AppTranslations.translate('fetal_movement', lang), 1, lang),
                        _buildTabButton(AppTranslations.translate('delivery_bag', lang), 2, lang),
                      ],
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
                      widthFactor: 0.5,
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
              Expanded(child: _buildTabContent(lang)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index, String lang) {
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
            color: isSelected ? const Color(0xFFE91E7A) : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String lang) {
    switch (_selectedTab) {
      case 0:
        return _buildPregnancySummaryTab(lang);
      case 1:
        return _buildFetalMovementTab(lang);
      case 2:
        return _buildHealthTab(lang);
      default:
        return _buildPregnancySummaryTab(lang);
    }
  }

  Widget _buildPregnancySummaryTab(String lang) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Pregnancy date input section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppTranslations.translate('enter_last_period_date', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Year dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showYearPicker(lang),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_drop_down, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  _pregnancyStartDate?.year.toString() ?? AppTranslations.translate('year', lang),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Month dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showMonthPicker(lang),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_drop_down, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  _pregnancyStartDate != null
                                      ? _getMonthName(_pregnancyStartDate!.month, lang)
                                      : AppTranslations.translate('month_dropdown', lang),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Day dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showDayPicker(lang),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_drop_down, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  _pregnancyStartDate?.day.toString() ?? AppTranslations.translate('day_label', lang),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      AppTranslations.translate('will_calculate_delivery', lang),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (_pregnancyStartDate != null) ...[
              const SizedBox(height: 16),
              // Pregnancy summary section
              _buildPregnancySummary(lang),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection(String title, Map<String, bool> items, String lang) {
    int checkedCount = items.values.where((v) => v).length;
    int totalCount = items.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$checkedCount/$totalCount',
                  style: const TextStyle(
                    color: Color(0xFFE91E7A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                ),
              ],
            ),
          ),
          // Checklist items
          ...items.entries.map((entry) {
            return CheckboxListTile(
              value: entry.value,
              onChanged: (bool? value) {
                setState(() {
                  items[entry.key] = value ?? false;
                });
              },
              title: Text(
                entry.key,
                style: const TextStyle(fontSize: 14),
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFE91E7A),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFetalMovementTab(String lang) {
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
                    AppTranslations.translate('fetal_movement_counter', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.translate('count_10_kicks', lang),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Counter display
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$_fetalMovementCount',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E7A),
                    ),
                  ),
                  Text(
                    AppTranslations.translate('kicks_today', lang),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  // Record button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _fetalMovementCount++;
                      });
                    },
                    icon: const Icon(Icons.phone_android, color: Colors.white),
                    label: Text(
                      AppTranslations.translate('record_kick', lang),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E7A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _fetalMovementCount = 0;
                      });
                    },
                    child: Text(
                      AppTranslations.translate('reset_counter_kicks', lang),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTab(String lang) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info banner at top
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
                      AppTranslations.translate('tip_prepare_bag', lang),
                      style: const TextStyle(color: Color(0xFF2196F3), fontSize: 13),
                      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mother care checklist
            _buildChecklistSection(AppTranslations.translate('for_mother', lang), _motherChecklist, lang),
            const SizedBox(height: 16),
            // Child care checklist
            _buildChecklistSection(AppTranslations.translate('for_baby', lang), _childChecklist, lang),
            const SizedBox(height: 16),
            // Documents checklist
            _buildChecklistSection(AppTranslations.translate('documents', lang), _suppliesChecklist, lang),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month, String lang) {
    if (lang == 'ar') {
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      return months[month - 1];
    } else {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return months[month - 1];
    }
  }

  void _showYearPicker(String lang) {
    showDialog(
      context: context,
      builder: (context) {
        final currentYear = DateTime.now().year;
        return AlertDialog(
          title: Text(
            AppTranslations.translate('choose_year', lang),
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 5,
              itemBuilder: (context, index) {
                final year = currentYear - index;
                return ListTile(
                  title: Text(year.toString(), textAlign: TextAlign.center),
                  onTap: () {
                    setState(() {
                      if (_pregnancyStartDate == null) {
                        _pregnancyStartDate = DateTime(year, 1, 1);
                      } else {
                        _pregnancyStartDate = DateTime(
                          year,
                          _pregnancyStartDate!.month,
                          _pregnancyStartDate!.day,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker(String lang) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppTranslations.translate('choose_month', lang),
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                return ListTile(
                  title: Text(_getMonthName(month, lang), textAlign: TextAlign.center),
                  onTap: () {
                    setState(() {
                      if (_pregnancyStartDate == null) {
                        _pregnancyStartDate = DateTime(DateTime.now().year, month, 1);
                      } else {
                        _pregnancyStartDate = DateTime(
                          _pregnancyStartDate!.year,
                          month,
                          _pregnancyStartDate!.day,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDayPicker(String lang) {
    showDialog(
      context: context,
      builder: (context) {
        final year = _pregnancyStartDate?.year ?? DateTime.now().year;
        final month = _pregnancyStartDate?.month ?? 1;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        return AlertDialog(
          title: Text(
            AppTranslations.translate('choose_day', lang),
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.left,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                return ListTile(
                  title: Text(day.toString(), textAlign: TextAlign.center),
                  onTap: () {
                    setState(() {
                      if (_pregnancyStartDate == null) {
                        _pregnancyStartDate = DateTime(DateTime.now().year, 1, day);
                      } else {
                        _pregnancyStartDate = DateTime(
                          _pregnancyStartDate!.year,
                          _pregnancyStartDate!.month,
                          day,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPregnancySummary(String lang) {
    final today = DateTime.now();
    final daysSinceStart = today.difference(_pregnancyStartDate!).inDays;
    final weeks = daysSinceStart ~/ 7;
    final days = daysSinceStart % 7;
    final expectedDelivery = _pregnancyStartDate!.add(const Duration(days: 280));

    // Fetal size comparison based on weeks
    String fetusComparison;
    if (weeks < 4) {
      fetusComparison = AppTranslations.translate('size_poppy_seed', lang);
    } else if (weeks < 5) {
      fetusComparison = AppTranslations.translate('size_sesame_seed', lang);
    } else if (weeks < 6) {
      fetusComparison = AppTranslations.translate('size_lentil', lang);
    } else if (weeks < 7) {
      fetusComparison = AppTranslations.translate('size_blueberry', lang);
    } else if (weeks < 8) {
      fetusComparison = AppTranslations.translate('size_kidney_bean', lang);
    } else if (weeks < 9) {
      fetusComparison = AppTranslations.translate('size_grape', lang);
    } else if (weeks < 10) {
      fetusComparison = AppTranslations.translate('size_olive', lang);
    } else if (weeks < 11) {
      fetusComparison = AppTranslations.translate('size_fig', lang);
    } else if (weeks < 12) {
      fetusComparison = AppTranslations.translate('size_lemon', lang);
    } else if (weeks < 13) {
      fetusComparison = AppTranslations.translate('size_peach', lang);
    } else if (weeks < 14) {
      fetusComparison = AppTranslations.translate('size_large_lemon', lang);
    } else if (weeks < 16) {
      fetusComparison = AppTranslations.translate('size_apple', lang);
    } else if (weeks < 18) {
      fetusComparison = AppTranslations.translate('size_avocado', lang);
    } else if (weeks < 20) {
      fetusComparison = AppTranslations.translate('size_mango', lang);
    } else if (weeks < 22) {
      fetusComparison = AppTranslations.translate('size_banana', lang);
    } else if (weeks < 24) {
      fetusComparison = AppTranslations.translate('size_corn', lang);
    } else if (weeks < 26) {
      fetusComparison = AppTranslations.translate('size_lettuce', lang);
    } else if (weeks < 28) {
      fetusComparison = AppTranslations.translate('size_cauliflower', lang);
    } else if (weeks < 30) {
      fetusComparison = AppTranslations.translate('size_cabbage', lang);
    } else if (weeks < 32) {
      fetusComparison = AppTranslations.translate('size_coconut', lang);
    } else if (weeks < 34) {
      fetusComparison = AppTranslations.translate('size_pineapple', lang);
    } else if (weeks < 36) {
      fetusComparison = AppTranslations.translate('size_butternut_squash', lang);
    } else if (weeks < 38) {
      fetusComparison = AppTranslations.translate('size_pumpkin', lang);
    } else {
      fetusComparison = AppTranslations.translate('size_watermelon', lang);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: lang == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Current pregnancy week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Text(
                AppTranslations.translate('first_trimester', lang),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.pink.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppTranslations.translate('current_pregnancy_age', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: lang == 'ar' ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                lang == 'ar' 
                  ? '$weeks أسبوع و $days يوم'
                  : '$weeks weeks and $days days',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Expected delivery date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  lang == 'ar'
                    ? '${expectedDelivery.day} ${_getMonthName(expectedDelivery.month, lang)} ${expectedDelivery.year}'
                    : '${_getMonthName(expectedDelivery.month, lang)} ${expectedDelivery.day}, ${expectedDelivery.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                AppTranslations.translate('delivery_date', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Fetus size comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  fetusComparison,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
              Text(
                AppTranslations.translate('baby_size', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Re-calculate button
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _pregnancyStartDate = null;
                });
              },
              child: Text(
                AppTranslations.translate('recalculate_date', lang),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

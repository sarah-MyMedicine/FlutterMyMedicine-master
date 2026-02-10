import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        title: const Text(
          'رعاية الأم والجنين',
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
                const Text(
                  'رعاية الأم والجنين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'رصدك للأم طوال مراحل الرحلة',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Tab buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('ملخص الحمل', 0),
                    _buildTabButton('حركة الجنين', 1),
                    _buildTabButton('حقيبة الولادة', 2),
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
            color: isSelected ? const Color(0xFFE91E7A) : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPregnancySummaryTab();
      case 1:
        return _buildFetalMovementTab();
      case 2:
        return _buildHealthTab();
      default:
        return _buildPregnancySummaryTab();
    }
  }

  Widget _buildPregnancySummaryTab() {
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
                  const Text(
                    'أدخلي تاريخ أول يوم من آخر دورة شهرية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Year dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showYearPicker(),
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
                                  _pregnancyStartDate?.year.toString() ?? 'السنة',
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
                          onTap: () => _showMonthPicker(),
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
                                      ? _getMonthName(_pregnancyStartDate!.month)
                                      : 'الشهر',
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
                          onTap: () => _showDayPicker(),
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
                                  _pregnancyStartDate?.day.toString() ?? 'اليوم',
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
                  const Center(
                    child: Text(
                      'ستقوم بحساب الموعد المتوقع للولادة وعمر الحمل',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (_pregnancyStartDate != null) ...[
              const SizedBox(height: 16),
              // Pregnancy summary section
              _buildPregnancySummary(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection(String title, Map<String, bool> items) {
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
                textAlign: TextAlign.right,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFE91E7A),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFetalMovementTab() {
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
                    'عداد ركلات الجنين',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'يوصى بحساب 10 ركلات خلال ساعتين في فترات النشاط. إذا كانت الحركة أقل، اتصلي بطبيبك.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.right,
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
                  const Text(
                    'ركلات اليوم',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    label: const Text(
                      'سجلي ركلة',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
                    child: const Text(
                      '↻ تصفير العداد',
                      style: TextStyle(color: Colors.grey),
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

  Widget _buildHealthTab() {
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'نصيحة: جهّزي حقيبتك في بداية الشهر الثامن',
                      style: TextStyle(color: Color(0xFF2196F3), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mother care checklist
            _buildChecklistSection('للأم 🍼', _motherChecklist),
            const SizedBox(height: 16),
            // Child care checklist
            _buildChecklistSection('للطفل 👶', _childChecklist),
            const SizedBox(height: 16),
            // Documents checklist
            _buildChecklistSection('أوراق ومستندات 📋', _suppliesChecklist),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSection(String title, List<String> items) {
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
                const Text(
                  '0/6',
                  style: TextStyle(
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
                ),
              ],
            ),
          ),
          // List items
          ...items.map((item) {
            return ListTile(
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(
                item,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.right,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
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
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) {
        final currentYear = DateTime.now().year;
        return AlertDialog(
          title: const Text('اختر السنة', textAlign: TextAlign.right),
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

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر الشهر', textAlign: TextAlign.right),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                return ListTile(
                  title: Text(_getMonthName(month), textAlign: TextAlign.center),
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

  void _showDayPicker() {
    showDialog(
      context: context,
      builder: (context) {
        final year = _pregnancyStartDate?.year ?? DateTime.now().year;
        final month = _pregnancyStartDate?.month ?? 1;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        return AlertDialog(
          title: const Text('اختر اليوم', textAlign: TextAlign.right),
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

  Widget _buildPregnancySummary() {
    final today = DateTime.now();
    final daysSinceStart = today.difference(_pregnancyStartDate!).inDays;
    final weeks = daysSinceStart ~/ 7;
    final days = daysSinceStart % 7;
    final expectedDelivery = _pregnancyStartDate!.add(const Duration(days: 280));

    // Fetal size comparison based on weeks
    String fetusComparison;
    if (weeks < 4) {
      fetusComparison = 'حجم بذرة الخشخاش';
    } else if (weeks < 5) {
      fetusComparison = 'حجم بذرة السمسم';
    } else if (weeks < 6) {
      fetusComparison = 'حجم حبة العدس';
    } else if (weeks < 7) {
      fetusComparison = 'حجم حبة التوت';
    } else if (weeks < 8) {
      fetusComparison = 'حجم حبة الفاصوليا';
    } else if (weeks < 9) {
      fetusComparison = 'حجم حبة العنب';
    } else if (weeks < 10) {
      fetusComparison = 'حجم حبة الزيتون';
    } else if (weeks < 11) {
      fetusComparison = 'حجم حبة التين';
    } else if (weeks < 12) {
      fetusComparison = 'حجم حبة الليمون';
    } else if (weeks < 13) {
      fetusComparison = 'حجم حبة الخوخ';
    } else if (weeks < 14) {
      fetusComparison = 'حجم حبة الليمون الكبيرة';
    } else if (weeks < 16) {
      fetusComparison = 'حجم التفاحة';
    } else if (weeks < 18) {
      fetusComparison = 'حجم حبة الأفوكادو';
    } else if (weeks < 20) {
      fetusComparison = 'حجم حبة المانجو';
    } else if (weeks < 22) {
      fetusComparison = 'حجم الموزة';
    } else if (weeks < 24) {
      fetusComparison = 'حجم حبة الذرة';
    } else if (weeks < 26) {
      fetusComparison = 'حجم الخس';
    } else if (weeks < 28) {
      fetusComparison = 'حجم القرنبيط';
    } else if (weeks < 30) {
      fetusComparison = 'حجم الكرنب';
    } else if (weeks < 32) {
      fetusComparison = 'حجم جوز الهند';
    } else if (weeks < 34) {
      fetusComparison = 'حجم الأناناس';
    } else if (weeks < 36) {
      fetusComparison = 'حجم البطيخ الأخضر';
    } else if (weeks < 38) {
      fetusComparison = 'حجم اليقطين';
    } else {
      fetusComparison = 'حجم البطيخ';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Current pregnancy week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الثلث الأول',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.pink.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'عمر الحمل الحالي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$weeks أسبوع و $days يوم',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Expected delivery date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${expectedDelivery.day} ${_getMonthName(expectedDelivery.month)} ${expectedDelivery.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                'موعد الولادة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Fetus size comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),
              ),
              const Text(
                'حجم الطفل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              child: const Text(
                'إعادة حساب التاريخ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

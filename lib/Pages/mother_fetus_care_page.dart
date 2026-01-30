import 'package:flutter/material.dart';

class MotherFetusCarePanel extends StatefulWidget {
  const MotherFetusCarePanel({super.key});

  @override
  State<MotherFetusCarePanel> createState() => _MotherFetusCarePanelState();
}

class _MotherFetusCarePanelState extends State<MotherFetusCarePanel> {
  int _selectedTab = 0;
  int _fetalMovementCount = 0;

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
                    _buildTabButton('الصحية', 2),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF5DABA8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 40),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'الاعدادات',
                  style: TextStyle(color: Color(0xFF5DABA8)),
                ),
              ),
              const SizedBox(width: 40),
              const Text(
                'إضافة دواء',
                style: TextStyle(color: Color(0xFF5DABA8)),
              ),
            ],
          ),
        ),
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
            // Info banner
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
            // Mother checklist
            _buildChecklistSection('للأم 🍼', _motherChecklist),
            const SizedBox(height: 16),
            // Child checklist
            _buildChecklistSection('للطفل 👶', _childChecklist),
            const SizedBox(height: 16),
            // Supplies checklist
            _buildChecklistSection('أوراق ومستندات 📋', _suppliesChecklist),
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
            // Mother care recommendations
            _buildHealthSection('للأم 🍼', [
              'روب يوم مريح (مفضل للراحة)',
              'ملابس داخلية قطنية',
              'فوط صحية (حجم كبير)',
              'حمالات صدر للرضاعة',
              'أدوات العناية الشخصية (فرشاة، شامبو...)',
              'ملابس الخروج من المستشفى',
            ]),
            const SizedBox(height: 16),
            // Child care recommendations
            _buildHealthSection('للطفل 👶', [
              'ملابس داخلية (الوِعي) عدد 3',
              'أطقم خارجية كاملة عدد 3',
              'قبعات وجوارب وقفازات',
              'بطانية ناعمة',
              'حقاضات مقاس مواليد جديد',
              'مناديل مبللة (Wipes)',
            ]),
            const SizedBox(height: 16),
            // Documents
            _buildHealthSection('أوراق ومستندات 📋', [
              'بطاقة الهوية / الإقامة',
              'بطاقة التأمين',
              'ملف متابعة الحمل والتحاليل',
            ]),
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
}

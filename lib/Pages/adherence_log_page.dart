import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/adherence_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class AdherenceLogPage extends StatelessWidget {
  const AdherenceLogPage({super.key});

  String _formatDate(DateTime date, String lang) {
    // Format as "اليوم DD شهر" in Arabic or "Day DD Month" in English
    final daysAr = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final daysEn = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    final dayName = lang == 'ar' ? daysAr[date.weekday % 7] : daysEn[date.weekday % 7];
    final day = date.day;
    final month = lang == 'ar' ? monthsAr[date.month - 1] : monthsEn[date.month - 1];
    
    return '$dayName $day $month';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, child) {
        final lang = sp.language;
        
        return Directionality(
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppTranslations.translate('adherence_log_title', lang)),
              backgroundColor: sp.themeColor,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            backgroundColor: const Color(0xFFF5F5F5),
            body: Consumer<AdherenceProvider>(
              builder: (context, adherence, _) {
                final records = adherence.records;

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          AppTranslations.translate('no_records_yet', lang),
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.translate('medications_taken_here', lang),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final medicationName = record['medicationName'] ?? '';
                    final dose = record['dose'] ?? '';
                    final timestamp = DateTime.tryParse(record['timestamp'] ?? '') ?? DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(timestamp, lang),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: sp.themeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      medicationName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dose,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${lang == 'ar' ? 'م' : ''} ${_formatTime(timestamp)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

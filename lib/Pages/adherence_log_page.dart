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

  String _filterLabel(String lang, String filter) {
    if (filter == 'taken') {
      return AppTranslations.translate('taken', lang);
    }
    if (filter == 'not_taken') {
      return lang == 'ar' ? 'غير مأخوذ' : 'Not taken';
    }
    return lang == 'ar' ? 'الكل' : 'All';
  }

  List<AdherenceLog> _applyFilter(List<AdherenceLog> logs, String filter) {
    if (filter == 'taken') {
      return logs.where((log) => log.taken).toList();
    }
    if (filter == 'not_taken') {
      return logs.where((log) => !log.taken).toList();
    }
    return logs;
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _AdherenceLogBody(
              lang: lang,
              themeColor: sp.themeColor,
              formatDate: _formatDate,
              formatTime: _formatTime,
              filterLabel: _filterLabel,
              applyFilter: _applyFilter,
            ),
          ),
        );
      },
    );
  }
}

class _AdherenceLogBody extends StatefulWidget {
  final String lang;
  final Color themeColor;
  final String Function(DateTime, String) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(String, String) filterLabel;
  final List<AdherenceLog> Function(List<AdherenceLog>, String) applyFilter;

  const _AdherenceLogBody({
    required this.lang,
    required this.themeColor,
    required this.formatDate,
    required this.formatTime,
    required this.filterLabel,
    required this.applyFilter,
  });

  @override
  State<_AdherenceLogBody> createState() => _AdherenceLogBodyState();
}

class _AdherenceLogBodyState extends State<_AdherenceLogBody> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AdherenceProvider>(
      builder: (context, adherence, _) {
        final allRecords = adherence.logs;
        final records = widget.applyFilter(allRecords, _selectedFilter);

        if (allRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.translate('no_records_yet', widget.lang),
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.translate('medications_taken_here', widget.lang),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildFilterChip(context, 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'taken'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'not_taken'),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Text(
                        widget.lang == 'ar'
                            ? 'لا توجد نتائج لهذا الفلتر'
                            : 'No results for this filter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final theme = Theme.of(context);
                        final onSurface = theme.colorScheme.onSurface;
                        final isDark = theme.brightness == Brightness.dark;
                        final record = records[index];
                        final medicationName = record.medicationName;
                        final dose = record.dose;
                        final timestamp = record.when;
                        final isTaken = record.taken;
                        final statusColor = isTaken ? Colors.green : Colors.orange;
                        final statusText = isTaken
                            ? AppTranslations.translate('taken', widget.lang)
                            : (widget.lang == 'ar' ? 'غير مأخوذ' : 'Not taken');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                                          widget.formatDate(timestamp, widget.lang),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: widget.themeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          medicationName,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: onSurface,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          dose,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.textTheme.bodySmall?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF232832) : const Color(0xFFF8F8F8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${widget.lang == 'ar' ? 'م' : ''} ${widget.formatTime(timestamp)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: onSurface,
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
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String value) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(widget.filterLabel(widget.lang, value)),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: widget.themeColor.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? widget.themeColor : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

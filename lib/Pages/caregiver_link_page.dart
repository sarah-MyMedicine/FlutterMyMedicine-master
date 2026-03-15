import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../utils/translations.dart';
import 'dart:async';

class CaregiverLinkPage extends StatefulWidget {
  const CaregiverLinkPage({super.key});

  @override
  _CaregiverLinkPageState createState() => _CaregiverLinkPageState();
}

class _CaregiverLinkPageState extends State<CaregiverLinkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _generatedCode;
  Timer? _codeExpiryTimer;
  List<Map<String, dynamic>> _pendingInvitations = [];
  List<Map<String, dynamic>> _linkedPatients = [];
  List<Map<String, dynamic>> _caregiverAlerts = [];
  Map<String, dynamic>? _linkedCaregiver;
  bool _isLoading = false;
  final _codeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _codeExpiryTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiService = ApiService();
    
    try {
      if (userProvider.isCaregiver) {
        _pendingInvitations = await apiService.getPendingInvitations(userProvider.username!);
        _linkedPatients = await apiService.getLinkedPatients(userProvider.username!);
        _caregiverAlerts = await apiService.getCaregiverAlerts(userProvider.username!);
      } else {
        _linkedCaregiver = await apiService.getLinkedCaregiver(userProvider.username!);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _generateInvitation() async {
    setState(() => _isLoading = true);
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiService = ApiService();
    
    try {
      final response = await apiService.generateInvitation(userProvider.username!);
      
      // Cancel existing timer if any
      _codeExpiryTimer?.cancel();
      
      setState(() {
        _generatedCode = response['invitationCode'];
        _isLoading = false;
      });
      
      // Auto-expire after 24 hours
      _codeExpiryTimer = Timer(const Duration(hours: 24), () {
        if (mounted) {
          setState(() => _generatedCode = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('انتهت صلاحية رمز الدعوة')),
          );
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء رمز الدعوة: $_generatedCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنشاء رمز الدعوة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _acceptInvitation(String code) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiService = ApiService();
    
    final success = await apiService.acceptInvitation(
      invitationCode: code,
      caregiverUsername: userProvider.username!,
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الدعوة بنجاح')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل قبول الدعوة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _rejectInvitation(String code) async {
    final apiService = ApiService();
    final success = await apiService.rejectInvitation(code);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض الدعوة')),
        );
        _loadData();
      }
    }
  }
  
  Future<void> _enterCode() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiService = ApiService();
    
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز الدعوة')),
      );
      return;
    }
    
    final success = await apiService.acceptInvitation(
      invitationCode: _codeController.text.toUpperCase().trim(),
      caregiverUsername: userProvider.username!,
    );
    
    if (mounted) {
      if (success) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الربط بنجاح')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رمز الدعوة غير صحيح أو منتهي الصلاحية'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _unlinkCaregiver() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiService = ApiService();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إلغاء الربط'),
        content: const Text('هل أنت متأكد من إلغاء ربط مقدم الرعاية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true && _linkedCaregiver != null) {
      try {
        await apiService.unlinkCaregiver(
          patientUsername: userProvider.username!,
          caregiverUsername: _linkedCaregiver!['username'],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء الربط')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل إلغاء الربط'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final sp = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقدم الرعاية'),
        backgroundColor: sp.themeColor,
        foregroundColor: Colors.white,
        bottom: userProvider.isCaregiver
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'الدعوات'),
                  Tab(text: 'المرضى'),
                  Tab(text: 'الإشعارات'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProvider.isPatient
              ? _buildPatientView(sp)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvitationsTab(sp),
                    _buildLinkedPatientsTab(sp),
                    _buildNotificationsTab(sp),
                  ],
                ),
    );
  }
  
  Widget _buildPatientView(SettingsProvider sp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Invitation generation card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2, size: 80, color: sp.themeColor),
                  const SizedBox(height: 16),
                  const Text(
                    'دعوة مقدم رعاية',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أنشئ رمز دعوة وشاركه مع مقدم الرعاية الخاص بك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (_generatedCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color.lerp(sp.themeColor, Colors.white, 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sp.themeColor, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _generatedCode!,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: sp.themeColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'صالح لمدة 24 ساعة',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _generatedCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ الرمز')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('نسخ الرمز'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sp.themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _generatedCode = null);
                              _codeExpiryTimer?.cancel();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('رمز جديد'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: sp.themeColor,
                              side: BorderSide(color: sp.themeColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    ElevatedButton.icon(
                      onPressed: _generateInvitation,
                      icon: const Icon(Icons.add),
                      label: const Text('إنشاء رمز دعوة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sp.themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Linked caregiver card
          if (_linkedCaregiver != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: sp.themeColor,
                          child: const Icon(Icons.person, size: 35, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مقدم الرعاية المرتبط',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _linkedCaregiver!['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${_linkedCaregiver!['username']}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _unlinkCaregiver,
                      icon: const Icon(Icons.link_off),
                      label: const Text('إلغاء الربط'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.person_add_disabled, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'لم يتم ربط مقدم رعاية بعد',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInvitationsTab(SettingsProvider sp) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Manual code entry
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدخال رمز الدعوة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخل الرمز الذي حصلت عليه من المريض',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'رمز الدعوة',
                        hintText: 'مثال: ABC123',
                        prefixIcon: const Icon(Icons.vpn_key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _enterCode,
                      icon: const Icon(Icons.link),
                      label: const Text('ربط الحساب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sp.themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pending invitations
            if (_pendingInvitations.isEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد دعوات معلقة',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الدعوات المعلقة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._pendingInvitations.map((invitation) => Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.person_add, color: Colors.white, size: 30),
                      ),
                      title: Text(
                        invitation['patientName'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        'رمز الدعوة: ${invitation['invitationCode']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                            onPressed: () => _acceptInvitation(invitation['invitationCode']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                            onPressed: () => _rejectInvitation(invitation['invitationCode']),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLinkedPatientsTab(SettingsProvider sp) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _linkedPatients.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لم يتم ربط أي مرضى بعد',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _linkedPatients.length,
              itemBuilder: (context, index) {
                final patient = _linkedPatients[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: sp.themeColor,
                      child: const Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    title: Text(
                      patient['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '@${patient['username']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to patient details
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('عرض تفاصيل المريض - قريباً')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
  
  Widget _buildNotificationsTab(SettingsProvider sp) {
    final lang = sp.language;

    if (_caregiverAlerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppTranslations.translate('missed_doses_notification_desc', lang),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'ستظهر هنا أيضاً تنبيهات الطوارئ المصنفة كصفارة إنذار',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _caregiverAlerts.length,
        itemBuilder: (context, index) {
          final alert = _caregiverAlerts[index];
          final classification = (alert['classification']?.toString() ?? '').toLowerCase();
          final isSiren = classification == 'siren';
          final isUnread = (alert['status']?.toString() ?? 'unread') == 'unread';
          final patientName = alert['patientName']?.toString() ?? alert['patientUsername']?.toString() ?? '-';
          final message = alert['message']?.toString() ?? '';

          DateTime? createdAt;
          final createdAtRaw = alert['createdAt']?.toString();
          if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
            createdAt = DateTime.tryParse(createdAtRaw);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: isSiren ? Colors.red.shade50 : Colors.orange.shade50,
                child: Icon(
                  isSiren ? Icons.warning_amber_rounded : Icons.notification_important,
                  color: isSiren ? Colors.red : Colors.orange,
                ),
              ),
              title: Text(
                patientName,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSiren
                        ? AppTranslations.translate('siren_classification', lang)
                        : 'Classification: ${classification.isEmpty ? 'high' : classification}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSiren ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
              trailing: isUnread
                  ? TextButton(
                      onPressed: () async {
                        final alertId = alert['_id']?.toString();
                        if (alertId == null || alertId.isEmpty) return;

                        try {
                          await ApiService().markEmergencyAlertAsRead(alertId);
                          if (!mounted) return;
                          await _loadData();
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('فشل تحديث حالة التنبيه'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(AppTranslations.translate('mark_as_read', lang)),
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}

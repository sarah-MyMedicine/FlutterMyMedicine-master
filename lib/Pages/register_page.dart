import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/patient_data_sync_service.dart';
import '../utils/translations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const String _usernameExistsBackendMessage = 'Username already exists';
  static const String _emailExistsBackendMessage = 'Email already exists';

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedUserType = 'patient';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _localizedRegisterError(String? rawMessage, String language) {
    if (rawMessage == _usernameExistsBackendMessage) {
      return AppTranslations.translate('username_exists_bilingual', language);
    }
    if (rawMessage == _emailExistsBackendMessage) {
      return AppTranslations.translate('email_exists_bilingual', language);
    }

    return rawMessage ?? 'فشل التسجيل. تحقق من البيانات وحاول مرة أخرى';
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء ملء جميع الحقول'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.translate('please_enter_valid_email', Provider.of<SettingsProvider>(context, listen: false).language)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمات المرور غير متطابقة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lang = Provider.of<SettingsProvider>(context, listen: false).language;
    if (_selectedUserType == 'caregiver') {
      _showComingSoon(
        '${AppTranslations.translate('caregiver', lang)} - ${AppTranslations.translate('coming_soon', lang)}',
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.register(
      username: _usernameController.text.trim(),
      email: email,
      password: _passwordController.text,
      name: _nameController.text.trim(),
      userType: _selectedUserType,
    );
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (success) {
      try {
        await PatientDataSyncService()
            .syncAfterAuthentication(
              context: context,
              username:
                  userProvider.username ?? _usernameController.text.trim().toLowerCase(),
            )
          .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[Register] Post-auth sync skipped due timeout/error: $e');
        await PatientDataSyncService().reloadProvidersFromLocal(context);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final language = Provider.of<SettingsProvider>(context, listen: false).language;
      final errorMessage = _localizedRegisterError(userProvider.lastError, language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: sp.themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User type selection cards
            const Text(
              'نوع الحساب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedUserType = 'patient');
                    },
                    child: Card(
                      elevation: _selectedUserType == 'patient' ? 8 : 2,
                      color: _selectedUserType == 'patient' ? sp.themeColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: sp.themeColor,
                          width: _selectedUserType == 'patient' ? 3 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person,
                              size: 50,
                              color: _selectedUserType == 'patient' ? Colors.white : sp.themeColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'مريض',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedUserType == 'patient' ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final lang = Provider.of<SettingsProvider>(context, listen: false).language;
                      _showComingSoon(
                        '${AppTranslations.translate('caregiver', lang)} - ${AppTranslations.translate('coming_soon', lang)}',
                      );
                    },
                    child: Card(
                      elevation: _selectedUserType == 'caregiver' ? 8 : 2,
                      color: _selectedUserType == 'caregiver' ? sp.themeColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: sp.themeColor,
                          width: _selectedUserType == 'caregiver' ? 3 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: 50,
                              color: _selectedUserType == 'caregiver' ? Colors.white : sp.themeColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'مقدم رعاية',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedUserType == 'caregiver' ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: const Icon(Icons.account_circle),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'مثال: ahmed123',
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppTranslations.translate('email', sp.language),
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'example@email.com',
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sp.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إنشاء الحساب', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'لديك حساب؟ سجل الدخول',
                style: TextStyle(color: sp.themeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

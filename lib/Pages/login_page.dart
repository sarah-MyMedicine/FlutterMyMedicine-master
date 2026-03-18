import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/patient_data_sync_service.dart';
import '../utils/translations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _invalidCredentialsMessage =
      'Either the username or password is wrong. Please try again';

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _localizedLoginError(String? rawMessage, String language) {
    if (rawMessage == _invalidCredentialsMessage) {
      return AppTranslations.translate('invalid_login_credentials', language);
    }

    return rawMessage ?? AppTranslations.translate('login_failed_check_data', language);
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    final language = Provider.of<SettingsProvider>(context, listen: false).language;

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.translate('please_enter_username_password', language)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
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
        debugPrint('[Login] Post-auth sync skipped due timeout/error: $e');
        await PatientDataSyncService().reloadProvidersFromLocal(context);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final errorMessage = _localizedLoginError(userProvider.lastError, language);
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
    final lang = sp.language;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [sp.themeColor, Color.lerp(sp.themeColor, Colors.black, 0.3)!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, size: 80, color: sp.themeColor),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.translate('app_name', lang),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.translate('login', lang),
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: AppTranslations.translate('username', lang),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: AppTranslations.translate('password', lang),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sp.themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                AppTranslations.translate('login', lang),
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        AppTranslations.translate('dont_have_account_register', lang),
                        style: TextStyle(color: sp.themeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

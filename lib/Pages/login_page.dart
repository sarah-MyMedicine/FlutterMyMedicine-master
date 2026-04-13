import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  'Either the username/email or password is wrong. Please try again';

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _isValidEmail(String value) {
    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

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
          content: Text(AppTranslations.translate('please_enter_username_or_email_password', language)),
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      try {
        await PatientDataSyncService()
            .syncAfterAuthentication(
              context: context,
              username: userProvider.username ?? '',
            )
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[GoogleLogin] Post-auth sync skipped due timeout/error: $e');
        await PatientDataSyncService().reloadProvidersFromLocal(context);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final language = Provider.of<SettingsProvider>(context, listen: false).language;
      final errorMessage = userProvider.lastError ?? AppTranslations.translate('google_sign_in_failed', language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final language = settings.language;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final emailController = TextEditingController();

    final usernameInput = _usernameController.text.trim();
    if (_isValidEmail(usernameInput)) {
      emailController.text = usernameInput;
    }

    bool isRequesting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return AlertDialog(
              title: Text(AppTranslations.translate('reset_password', language)),
              content: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppTranslations.translate('email', language),
                  hintText: AppTranslations.translate('please_enter_valid_email', language),
                  helperText: AppTranslations.translate(
                    'password_reset_email_note',
                    language,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppTranslations.translate('cancel', language)),
                ),
                ElevatedButton(
                  onPressed: isRequesting
                      ? null
                      : () async {
                          final email = emailController.text.trim().toLowerCase();
                          if (!_isValidEmail(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.translate('please_enter_valid_email', language),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isRequesting = true);
                          final sent = await userProvider.requestPasswordReset(email: email);
                          if (!mounted) return;
                          Navigator.of(dialogContext).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                sent
                                    ? AppTranslations.translate('password_reset_email_sent', language)
                                    : (userProvider.lastError ??
                                        AppTranslations.translate('password_reset_email_failed', language)),
                              ),
                              backgroundColor: sent ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                  child: isRequesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppTranslations.translate('send', language)),
                ),
              ],
            );
          },
        );
      },
    );
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
                        hintText: AppTranslations.translate('username_or_email', lang),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _showResetPasswordDialog,
                        child: Text(
                          AppTranslations.translate('forgot_password', lang),
                          style: TextStyle(color: sp.themeColor),
                        ),
                      ),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppTranslations.translate('or', lang),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 18,
                          color: Color(0xFFDB4437),
                        ),
                        label: Text(AppTranslations.translate('continue_with_google', lang)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

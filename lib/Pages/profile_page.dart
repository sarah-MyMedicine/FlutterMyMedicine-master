import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class ProfilePage extends StatefulWidget {
  final String password;

  const ProfilePage({
    super.key,
    required this.password,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isPasswordVisible = false;
  bool _isAuthenticating = false;
  String? _authError;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometryAvailability();
  }

  Future<void> _checkBiometryAvailability() async {
    try {
      final canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;

      setState(() {
        _canUseBiometrics = canAuthenticateWithBiometrics;
      });
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  Future<void> _authenticateAndShowPassword() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to view your password',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        setState(() {
          _isPasswordVisible = true;
          _authError = null;
        });

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.translate('password_verified', 'ar'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _authError = AppTranslations.translate('auth_cancelled', 'ar');
        });
      }
    } on Exception catch (e) {
      setState(() {
        _authError = AppTranslations.translate('auth_failed', 'ar');
        _isPasswordVisible = false;
      });
      debugPrint('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    // For production, use flutter_clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTranslations.translate('copied_to_clipboard', 'ar'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _hidePassword() {
    setState(() {
      _isPasswordVisible = false;
      _authError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, SettingsProvider>(
      builder: (context, userProvider, settingsProvider, _) {
        final lang = settingsProvider.language;
        final isRtl = lang == 'ar';

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: Text(AppTranslations.translate('profile', lang)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 1,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade100,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Username Field
                          Text(
                            AppTranslations.translate('username', lang),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              userProvider.username ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Section
                  Text(
                    AppTranslations.translate('account_security', lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.translate('password', lang),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Password Display Area
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isPasswordVisible
                                    ? Colors.blue.shade300
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _isPasswordVisible
                                        ? widget.password
                                        : '••••••••',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _isPasswordVisible
                                          ? Colors.black87
                                          : Colors.grey,
                                      letterSpacing: _isPasswordVisible ? 0 : 4,
                                    ),
                                  ),
                                ),
                                if (_isPasswordVisible)
                                  GestureDetector(
                                    onTap: () =>
                                        _copyToClipboard(widget.password),
                                    child: Icon(
                                      Icons.content_copy,
                                      size: 20,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Action Buttons
                          if (!_isPasswordVisible)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _canUseBiometrics
                                    ? _authenticateAndShowPassword
                                    : null,
                                icon: _isAuthenticating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.lock_open),
                                label: Text(
                                  _isAuthenticating
                                      ? AppTranslations.translate(
                                          'authenticating', lang)
                                      : AppTranslations.translate(
                                          'verify_identity', lang),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _hidePassword,
                                icon: const Icon(Icons.lock),
                                label: Text(
                                  AppTranslations.translate('hide_password', lang),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                          // Error Message
                          if (_authError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _authError!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Security Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppTranslations.translate('biometric_security_info', lang),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Feature info - biometric available or not
                  if (!_canUseBiometrics)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppTranslations.translate('no_biometric_available', lang),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

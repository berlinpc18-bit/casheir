import 'package:flutter/material.dart';
import 'license_manager.dart';
import 'license_activation_screen.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'main.dart';

class LicenseWrapper extends StatefulWidget {
  const LicenseWrapper({super.key});

  @override
  State<LicenseWrapper> createState() => _LicenseWrapperState();
}

class _LicenseWrapperState extends State<LicenseWrapper> {
  bool _isChecking = true;
  bool _isLicenseValid = false;
  bool _isLoggedIn = false;
  String _errorMessage = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    try {
      final licenseManager = LicenseManager();
      final status = await licenseManager.checkStoredLicense();
      
      // فحص حالة تسجيل الدخول بعد التحقق من الترخيص
      bool loggedIn = false;
      if (status == LicenseStatus.valid) {
        loggedIn = await _authService.isLoggedIn();
      }
      
      setState(() {
        _isChecking = false;
        _isLoggedIn = loggedIn;
        switch (status) {
          case LicenseStatus.valid:
            _isLicenseValid = true;
            break;
          case LicenseStatus.notActivated:
            _errorMessage = 'يجب تفعيل الترخيص أولاً';
            break;
          case LicenseStatus.expired:
            _errorMessage = 'انتهت صلاحية الترخيص';
            break;
          case LicenseStatus.wrongDevice:
            _errorMessage = 'الترخيص غير صالح لهذا الجهاز';
            break;
          default:
            _errorMessage = 'خطأ في التحقق من الترخيص';
        }
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMessage = 'فشل في التحقق من الترخيص';
      });
    }
  }

  Future<void> _showActivationScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LicenseActivationScreen(),
        fullscreenDialog: true,
      ),
    );
    
    if (result == true) {
      // تم التفعيل بنجاح، إعادة فحص الترخيص
      _checkLicense();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // شاشة تحميل أثناء فحص الترخيص
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'جاري التحقق من الترخيص...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLicenseValid) {
      // شاشة خطأ الترخيص مع زر التفعيل
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // خطأ أيقونة
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_outlined,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // رسالة الخطأ
                  Text(
                    'غير مفعل',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // زر التفعيل
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showActivationScreen,
                      icon: const Icon(Icons.vpn_key_rounded, color: Colors.white),
                      label: const Text(
                        'تفعيل الترخيص',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // زر إعادة الفحص
                  TextButton.icon(
                    onPressed: _checkLicense,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    label: const Text(
                      'إعادة الفحص',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // الترخيص صالح، فحص حالة تسجيل الدخول
    if (_isLoggedIn) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'license_manager.dart';
import 'sound_service.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _licenseController = TextEditingController();
  final LicenseManager _licenseManager = LicenseManager();
  
  bool _isActivating = false;
  String? _deviceId;
  String _statusMessage = '';
  Color _statusColor = Colors.grey;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDeviceId();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await _licenseManager.getDeviceIdForDisplay();
    setState(() {
      _deviceId = deviceId;
    });
  }

  Future<void> _activateLicense() async {
    if (_licenseController.text.trim().isEmpty) {
      _showStatus('يرجى إدخال رمز الترخيص', Colors.orange);
      SoundService().playError();
      return;
    }

    setState(() {
      _isActivating = true;
      _statusMessage = 'جاري التحقق من الترخيص...';
      _statusColor = Colors.blue;
    });

    try {
      final status = await _licenseManager.validateLicense(_licenseController.text.trim());
      
      switch (status) {
        case LicenseStatus.valid:
          _showStatus('تم تفعيل الترخيص بنجاح! 🎉', Colors.green);
          SoundService().playSuccess();
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
          break;
        case LicenseStatus.invalid:
          _showStatus('رمز الترخيص غير صحيح', Colors.red);
          SoundService().playError();
          break;
        case LicenseStatus.expired:
          _showStatus('انتهت صلاحية الترخيص', Colors.red);
          SoundService().playError();
          break;
        case LicenseStatus.wrongDevice:
          _showStatus('هذا الترخيص غير صالح لهذا الجهاز', Colors.red);
          SoundService().playError();
          break;
        case LicenseStatus.tampered:
          _showStatus('رمز الترخيص معدل أو تالف', Colors.red);
          SoundService().playError();
          break;
        default:
          _showStatus('حدث خطأ في التحقق من الترخيص', Colors.red);
          SoundService().playError();
      }
    } catch (e) {
      _showStatus('خطأ في الاتصال أو التحقق', Colors.red);
      SoundService().playError();
    }

    setState(() {
      _isActivating = false;
    });
  }

  void _showStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
  }

  void _copyDeviceId() {
    if (_deviceId != null) {
      Clipboard.setData(ClipboardData(text: _deviceId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ معرف الجهاز'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      SoundService().playClick();
    }
  }

  // فتح رقم الهاتف
  Future<void> _openPhone() async {
    const phoneNumber = '07710093498';
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    
    try {
      await launchUrl(phoneUri);
      SoundService().playClick();
    } catch (e) {
      // في حالة فشل فتح التطبيق، انسخ الرقم
      Clipboard.setData(const ClipboardData(text: phoneNumber));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ رقم الهاتف: 07710093498'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // فتح حساب الانستغرام
  Future<void> _openInstagram() async {
    const username = 'QO_OP';
    final Uri instagramUri = Uri.parse('https://instagram.com/$username');
    
    try {
      await launchUrl(instagramUri, mode: LaunchMode.externalApplication);
      SoundService().playClick();
    } catch (e) {
      // في حالة فشل فتح التطبيق، انسخ اسم المستخدم
      Clipboard.setData(const ClipboardData(text: username));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ معرف الانستغرام: QO_OP'),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  // Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'تفعيل الترخيص',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'أدخل رمز الترخيص لتفعيل التطبيق',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Device ID Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.computer,
                              color: Colors.white.withOpacity(0.8),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'معرف الجهاز',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _deviceId ?? 'جاري التحميل...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _copyDeviceId,
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white70,
                              ),
                              tooltip: 'نسخ معرف الجهاز',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أرسل هذا المعرف للحصول على رمز الترخيص',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // License Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _licenseController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'أدخل رمز الترخيص',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(
                          Icons.vpn_key_rounded,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => _activateLicense(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Status Message
                  if (_statusMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusColor == Colors.green
                                ? Icons.check_circle
                                : _statusColor == Colors.red
                                    ? Icons.error
                                    : Icons.info,
                            color: _statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Activate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isActivating ? null : _activateLicense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isActivating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'تفعيل الترخيص',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'للحصول على رمز الترخيص، تواصل معنا:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // Phone Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openPhone,
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  '07710093498',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Instagram Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openInstagram,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  'QO_OP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE4405F),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'اضغط على الأزرار للتواصل المباشر',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
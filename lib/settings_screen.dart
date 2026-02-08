import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'license_wrapper.dart';
import 'custom_category_screen.dart';
import 'financial_reports_screen.dart';
import 'debts_screen.dart';
import 'prices_settings_screen.dart';
import 'device_management_screen.dart';
import 'sound_service.dart';
import 'api_client.dart';
import 'api_sync_manager.dart';
import 'app_logger.dart';
import 'printer_settings_screen.dart';
import 'license_manager.dart';
import 'backup_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // متحكمات أسعار الطلبات
  final TextEditingController _shishaPriceController = TextEditingController();
  final TextEditingController _hotDrinksPriceController = TextEditingController();
  final TextEditingController _coldDrinksPriceController = TextEditingController();
  final TextEditingController _juicesPriceController = TextEditingController();
  final TextEditingController _snacksPriceController = TextEditingController();
  final TextEditingController _gamesPriceController = TextEditingController();
  
  // API Server Configuration
  late TextEditingController _apiServerController;
  bool _useApiData = true; // Toggle to use API or local Hive data

  // إعدادات النظام
  bool _autoStart = true;
  bool _autoSave = true;
  bool _soundNotifications = false;
  bool _soundEffects = true;

  // إعدادات الطابعات
  bool _printKitchenReceipts = true;
  bool _printBaristaReceipts = true;
  bool _printCashierReceipts = true;
  String? _currentUser;



  @override
  void initState() {
    super.initState();
    _loadCurrentPrices();
    _apiServerController = TextEditingController(text: ApiClient().baseUrl);
    _soundEffects = SoundService().soundEnabled;
    _useApiData = ApiSyncManager().isApiEnabled; // Load current API setting
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final username = await AuthService().getLoggedInUsername();
    if (mounted) {
      setState(() {
        _currentUser = username;
      });
    }
  }



  void _loadCurrentPrices() {
    // تحميل أسعار الطلبات (قيم افتراضية)
    _shishaPriceController.text = '5.0';
    _hotDrinksPriceController.text = '2.0';
    _coldDrinksPriceController.text = '1.5';
    _juicesPriceController.text = '2.5';
    _snacksPriceController.text = '3.0';
    _gamesPriceController.text = '1.0';
  }

  @override
  void dispose() {
    _shishaPriceController.dispose();
    _hotDrinksPriceController.dispose();
    _coldDrinksPriceController.dispose();
    _juicesPriceController.dispose();
    _snacksPriceController.dispose();
    _gamesPriceController.dispose();
    _apiServerController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded, 
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'الإعدادات',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد تسجيل الخروج'),
                    content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('لا'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('نعم', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ?? false;

                if (shouldLogout) {
                  // تسجيل الخروج من AuthService
                  final authService = AuthService();
                  await authService.logout();
                  
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LicenseWrapper(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),


            // إعدادات خادم API
            _buildApiServerSection(),
            const SizedBox(height: 24),

            // معلومات الترخيص (تظهر للجميع)
            _buildLicenseSection(),
            const SizedBox(height: 24),

            if (_currentUser == 'super_admin') ...[
              // إعدادات الأسعار
              _buildPricesSection(),
              const SizedBox(height: 24),
              
              // إعدادات الطابعات
              _buildPrintersButtonSection(),
              const SizedBox(height: 24),
              
              // إدارة الأجهزة
              _buildDeviceManagementSection(),
              const SizedBox(height: 24),
              
              // إدارة النسخ الاحتياطية
              _buildBackupManagementSection(),
              const SizedBox(height: 24),
              
              // تعديل أسعار الطلبات
              _buildOrderPricesSection(),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: const Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // التقارير المالية
              _buildFinancialReportsSection(),
              const SizedBox(height: 24),
              
              // إدارة الديون
              _buildDebtsSection(),
              const SizedBox(height: 24),
              
              // إعدادات الصوت
              _buildSoundSection(),
              const SizedBox(height: 24),
              
              // سجل النظام
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_edu, color: Colors.brown),
                ),
                title: const Text('سجل النظام (Debug Logs)'),
                subtitle: const Text('عرض سجلات الأخطاء والعمليات'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LogViewerScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),

              // حول التطبيق
              _buildAboutSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricesSection() {
    return InkWell(
      onTap: _showPricesDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.attach_money_rounded, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات الأسعار',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تعديل أسعار الأجهزة والخدمات',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.green,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black, 
              fontSize: 16
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              suffixText: subtitle,
              suffixStyle: TextStyle(color: Colors.green.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintersButtonSection() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrinterSettingsScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.print_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعدادات الطابعات',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'إدارة طابعات المطبخ والباريستا والكاشير',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPrinterStatusChip('المطبخ', Colors.orange, _printKitchenReceipts),
                      const SizedBox(width: 8),
                      _buildPrinterStatusChip('الباريستا', Colors.brown, _printBaristaReceipts),
                      const SizedBox(width: 8),
                      _buildPrinterStatusChip('الكاشير', Colors.green, _printCashierReceipts),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.purple,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterStatusChip(String name, Color color, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? color : Colors.grey,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: isEnabled ? color : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceManagementSection() {
    return InkWell(
      onTap: _showDeviceManagementScreen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.devices_rounded, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إدارة الأجهزة',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إضافة وحذف وتعديل الأجهزة',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showPricesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PricesSettingsScreen(),
      ),
    );
  }

  Future<void> _saveApiServerUrl() async {
    final newUrl = _apiServerController.text.trim();
    
    // التحقق من صحة الـ URL
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ يرجى إدخال عنوان خادم صحيح'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // التحقق من أن الـ URL يبدأ بـ http:// أو https://
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ يجب أن يبدأ العنوان بـ http:// أو https://'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      // تحديث الـ API client
      ApiClient().setBaseUrl(newUrl);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ عنوان الخادم: $newUrl'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في تحديث العنوان: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _resetApiServerUrl() async {
    const defaultUrl = 'http://localhost:8080';
    _apiServerController.text = defaultUrl;
    ApiClient().setBaseUrl(defaultUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('↻ تم إعادة تعيين عنوان الخادم إلى الافتراضي'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testApiConnection() async {
    final url = _apiServerController.text.trim();
    AppLogger().info('User initiated connection test to: $url', 'SETTINGS');
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ يرجى إدخال عنوان خادم'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // عرض loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'اختبار الاتصال بالخادم...',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // تحديث الـ URL مؤقتاً للاختبار
      final originalUrl = ApiClient().baseUrl;
      ApiClient().setBaseUrl(url);
      
      // محاولة جلب البيانات من الخادم
      final available = await ApiClient().isServerAvailable();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق loading dialog

      if (available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ الخادم يعمل بشكل صحيح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // إعادة الـ URL الأصلي
        ApiClient().setBaseUrl(originalUrl);
        _apiServerController.text = originalUrl;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ الخادم لا يستجيب. تم إعادة العنوان السابق'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في الاتصال: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showDeviceManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeviceManagementScreen(),
      ),
    );
  }

  Widget _buildBackupManagementSection() {
    return InkWell(
      onTap: _showBackupManagementScreen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.backup_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة النسخ الاحتياطية',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تنظيف وإدارة ملفات النسخ الاحتياطية الطارئة',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupManagementScreen(),
      ),
    );
  }

  Widget _buildOrderPricesSection() {
    return InkWell(
      onTap: _showOrderPricesMenu,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.purple, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تعديل أسعار الطلبات',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة الأقسام المخصصة والأصناف',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.purple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderPricesMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderPricesMenuDialog();
      },
    );
  }

  Widget _buildFinancialReportsSection() {
    return InkWell(
      onTap: _openFinancialReports,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التقارير الشهرية',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإيرادات والمصروفات الشهرية وصافي الربح',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.orange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsSection() {
    return InkWell(
      onTap: _openDebtsScreen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet, color: Color(0xFFE91E63), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الديون',
                    style: TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة ديون الزبائن والمبالغ المستحقة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFE91E63),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDebtsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebtsScreen(),
      ),
    );
  }

  void _openFinancialReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinancialReportsScreen()),
    );
  }

  Widget _buildSoundSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'إعدادات الصوت',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _soundEffects ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _soundEffects ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المؤثرات الصوتية',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تشغيل الأصوات عند النقر والحفظ والطباعة',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _soundEffects,
                  onChanged: (value) {
                    setState(() {
                      _soundEffects = value;
                    });
                    SoundService().setSoundEnabled(value);
                    if (value) {
                      SoundService().playClick(); // تشغيل صوت تجريبي
                    }
                  },
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildApiServerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'إعدادات خادم API',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'عنوان الخادم',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiServerController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: http://localhost:8080',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: const Icon(Icons.language, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveApiServerUrl,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetApiServerUrl,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة تعيين'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testApiConnection,
              icon: const Icon(Icons.cloud_queue_rounded),
              label: const Text('اختبار الاتصال'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تغيير عنوان الخادم سيتم تطبيقه فوراً',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Toggle: Use API or Local Data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _useApiData ? Icons.cloud_rounded : Icons.storage_rounded,
                  color: _useApiData ? Colors.blue : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مصدر البيانات',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _useApiData 
                            ? '☁️ جلب البيانات من الخادم (API)'
                            : '💾 جلب البيانات من الذاكرة المحلية (Hive)',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useApiData,
                  onChanged: (value) {
                    setState(() {
                      _useApiData = value;
                      // Apply the setting to ApiSyncManager
                      ApiSyncManager().setApiEnabled(value);
                    });
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value 
                              ? '☁️ سيتم جلب البيانات من الخادم'
                              : '💾 سيتم جلب البيانات من الذاكرة المحلية'
                        ),
                        backgroundColor: value ? Colors.blue : Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withOpacity(0.3),
                  inactiveThumbColor: Colors.orange,
                  inactiveTrackColor: Colors.orange.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: LicenseManager().getLicenseInfo(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'معلومات الترخيص',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasData && snapshot.data != null) ...[
                _buildLicenseInfo(snapshot.data!),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'لم يتم تفعيل الترخيص',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLicenseInfo(Map<String, dynamic> licenseData) {
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(licenseData['expires']);
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft <= 30;
    
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.person_rounded,
          title: 'العميل',
          value: licenseData['customer'] ?? 'غير محدد',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.computer_rounded,
          title: 'معرف الجهاز',
          value: (licenseData['device'] ?? '').toString().substring(0, 8).toUpperCase(),
          color: Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.calendar_today_rounded,
          title: 'ينتهي في',
          value: '$daysLeft يوم',
          color: isExpiringSoon ? Colors.orange : Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.verified_rounded,
          title: 'الحالة',
          value: daysLeft > 0 ? 'نشط' : 'منتهي الصلاحية',
          color: daysLeft > 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.black87,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return InkWell(
      onTap: _showAboutDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حول التطبيق',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'معلومات المطور وحقوق النشر',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.blue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.42,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // رأس النافذة
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'حول التطبيق',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // المحتوى
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // أيقونة التطبيق
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.point_of_sale,
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // اسم التطبيق
                        const Text(
                          'تطبيق الكاشير',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // نسخة التطبيق
                        Text(
                          'الإصدار 1.0.0',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // معلومات المطور
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'معلومات المطور',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // اسم المطور
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'المطور: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'ZORO',
                                    style: TextStyle(
                                      color: Colors.blue.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // البريد الإلكتروني
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'البريد: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'LAY86281@GMAIL.COM',
                                      style: TextStyle(
                                        color: Colors.blue.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // الإنستغرام
                              Row(
                                children: [
                                  const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'إنستغرام: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _openInstagramProfile,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '@qo_op',
                                            style: TextStyle(
                                              color: Colors.blue.withOpacity(0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.open_in_new,
                                            color: Colors.blue.withOpacity(0.7),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // حقوق النشر
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Text(
                            '© 2025 جميع الحقوق محفوظة لـ ZORO\nتم تطوير هذا التطبيق لإدارة أنظمة نقاط البيع',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('إغلاق', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openInstagramProfile() async {
    const String instagramUrl = 'https://www.instagram.com/qo_op/';
    final Uri uri = Uri.parse(instagramUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // في حالة فشل فتح الرابط، نسخ اسم المستخدم إلى الحافظة
        await Clipboard.setData(const ClipboardData(text: '@qo_op'));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم نسخ اسم المستخدم إلى الحافظة: @qo_op'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // في حالة حدوث خطأ، نسخ اسم المستخدم إلى الحافظة
      await Clipboard.setData(const ClipboardData(text: '@qo_op'));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ اسم المستخدم إلى الحافظة: @qo_op'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class OrderPricesMenuDialog extends StatefulWidget {
  @override
  State<OrderPricesMenuDialog> createState() => _OrderPricesMenuDialogState();
}

class _OrderPricesMenuDialogState extends State<OrderPricesMenuDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // رأس النافذة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'تعديل أسعار الطلبات',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                child: Consumer<AppState>(
                  builder: (context, appState, child) {
                    final customCategories = appState.customCategories;
                    return Column(
                      children: [
                        // الأقسام الافتراضية

                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildAddCategoryButton(),
                            ),
                          ],
                        ),
                        
                        // عرض الأقسام المخصصة إذا كانت موجودة
                        if (customCategories.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'الأقسام المخصصة',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // عرض الأقسام المخصصة في صفوف
                          ...List.generate(
                            (customCategories.length / 2).ceil(),
                            (rowIndex) {
                              final startIndex = rowIndex * 2;
                              final endIndex = (startIndex + 2).clamp(0, customCategories.length);
                              final rowCategories = customCategories.keys.toList().sublist(startIndex, endIndex);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildCustomCategoryCard(
                                        categoryName: rowCategories[0],
                                        itemCount: customCategories[rowCategories[0]]?.length ?? 0,
                                        appState: appState,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: rowCategories.length > 1
                                          ? _buildCustomCategoryCard(
                                              categoryName: rowCategories[1],
                                              itemCount: customCategories[rowCategories[1]]?.length ?? 0,
                                              appState: appState,
                                            )
                                          : Container(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickablePriceField({
    required String title,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.purple,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return InkWell(
      onTap: _showAddCategoryDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إضافة قسم',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'قسم جديد',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'إضافة قسم جديد',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اسم القسم:',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryNameController,
                autofocus: true,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'مثال: أقسام مخصصة',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : const Color(0xFF666666),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF666666),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final categoryName = categoryNameController.text.trim();
                if (categoryName.isNotEmpty) {
                  _createNewCategory(categoryName);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إضافة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createNewCategory(String categoryName) {
    // إضافة القسم الجديد إلى AppState
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addNewCategory(categoryName);
    
    // تحديث الواجهة
    setState(() {});
    
    // عرض رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة قسم "$categoryName" بنجاح!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCustomCategoryCard({
    required String categoryName,
    required int itemCount,
    required AppState appState,
  }) {
    return Container(
      height: 120, // إضافة ارتفاع ثابت
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2E), Color(0xFF1F1F23)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // الجزء الرئيسي القابل للنقر
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomCategoryScreen(
                      categoryName: categoryName,
                    ),
                  ),
                );
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '$itemCount عنصر',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // أزرار التحكم في الأسفل
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // زر التعديل
                Expanded(
                  child: InkWell(
                    onTap: () => _showEditCategoryDialog(categoryName, appState),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'تعديل',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.2),
                ),
                // زر الحذف
                Expanded(
                  child: InkWell(
                    onTap: () => _showDeleteCategoryDialog(categoryName, appState),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'حذف',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String oldName, AppState appState) {
    final TextEditingController controller = TextEditingController(text: oldName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'تعديل اسم القسم',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ادخل اسم القسم الجديد',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                appState.updateCategoryName(oldName, newName);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تعديل اسم القسم من "$oldName" إلى "$newName"'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String categoryName, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف قسم "$categoryName"؟\nسيتم حذف جميع العناصر الموجودة فيه نهائياً.',
          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              appState.removeCategory(categoryName);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف قسم "$categoryName" بنجاح'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

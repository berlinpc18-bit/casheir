import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseManager {
  static final LicenseManager _instance = LicenseManager._internal();
  factory LicenseManager() => _instance;
  LicenseManager._internal();

  // مفاتيح التشفير (يجب تغييرها لكل عميل)
  static const String _secretKey = 'YOUR_UNIQUE_SECRET_2025';
  static const String _licenseKey = 'device_license';
  static const String _activationKey = 'activation_date';

  // الحصول على معرف فريد للجهاز
  Future<String> _getDeviceId() async {
    try {
      String deviceInfo = '';
      
      if (Platform.isWindows) {
        // Windows: استخدام معرف الكمبيوتر
        final result = await Process.run('wmic', ['csproduct', 'get', 'uuid']);
        deviceInfo += result.stdout.toString().replaceAll('UUID', '').trim();
        
        // إضافة معرف اللوحة الأم
        final motherboard = await Process.run('wmic', ['baseboard', 'get', 'serialnumber']);
        deviceInfo += motherboard.stdout.toString().replaceAll('SerialNumber', '').trim();
      } else if (Platform.isMacOS) {
        // macOS: استخدام Hardware UUID
        final result = await Process.run('system_profiler', ['SPHardwareDataType']);
        deviceInfo = result.stdout.toString();
      } else if (Platform.isLinux) {
        // Linux: استخدام machine-id
        final result = await Process.run('cat', ['/etc/machine-id']);
        deviceInfo = result.stdout.toString().trim();
      }
      
      // تشفير المعرف
      final bytes = utf8.encode(deviceInfo + _secretKey);
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 32).toUpperCase();
    } catch (e) {
      // في حالة فشل الحصول على المعرف، استخدم معرف احتياطي
      return 'BACKUP_DEVICE_ID_${Platform.operatingSystem}'.toUpperCase();
    }
  }

  // توليد رمز الترخيص للجهاز الحالي
  Future<String> generateLicenseCode(String customerName, int validDays) async {
    final deviceId = await _getDeviceId();
    return _generateLicenseForDevice(customerName, deviceId, validDays);
  }

  // توليد رمز الترخيص لجهاز معين (للمطور)
  String generateLicenseForCustomDevice(String customerName, String deviceId, int validDays) {
    return _generateLicenseForDevice(customerName, deviceId, validDays);
  }

  // الدالة الأساسية لتوليد الترخيص
  String _generateLicenseForDevice(String customerName, String deviceId, int validDays) {
    final activationDate = DateTime.now().millisecondsSinceEpoch;
    final expiryDate = DateTime.now().add(Duration(days: validDays)).millisecondsSinceEpoch;
    
    final licenseData = {
      'device': deviceId,
      'customer': customerName,
      'activated': activationDate,
      'expires': expiryDate,
      'version': '1.0.0',
    };
    
    final licenseJson = jsonEncode(licenseData);
    final bytes = utf8.encode(licenseJson + _secretKey);
    final digest = sha256.convert(bytes);
    
    return base64.encode(utf8.encode(licenseJson)) + '.' + digest.toString().substring(0, 16);
  }

  // التحقق من صحة الترخيص
  Future<LicenseStatus> validateLicense(String licenseCode) async {
    try {
      final parts = licenseCode.split('.');
      if (parts.length != 2) {
        return LicenseStatus.invalid;
      }
      
      final licenseJson = utf8.decode(base64.decode(parts[0]));
      final expectedHash = parts[1];
      
      // التحقق من التوقيع
      final bytes = utf8.encode(licenseJson + _secretKey);
      final digest = sha256.convert(bytes);
      final actualHash = digest.toString().substring(0, 16);
      
      if (actualHash != expectedHash) {
        return LicenseStatus.tampered;
      }
      
      final licenseData = jsonDecode(licenseJson);
      final deviceId = await _getDeviceId();
      
      // التحقق من معرف الجهاز
      if (licenseData['device'] != deviceId) {
        return LicenseStatus.wrongDevice;
      }
      
      // التحقق من انتهاء الصلاحية
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(licenseData['expires']);
      if (DateTime.now().isAfter(expiryDate)) {
        return LicenseStatus.expired;
      }
      
      // حفظ معلومات الترخيص
      await _saveLicenseInfo(licenseData);
      
      return LicenseStatus.valid;
    } catch (e) {
      return LicenseStatus.invalid;
    }
  }

  // حفظ معلومات الترخيص محلياً
  Future<void> _saveLicenseInfo(Map<String, dynamic> licenseData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseKey, jsonEncode(licenseData));
    await prefs.setInt(_activationKey, DateTime.now().millisecondsSinceEpoch);
  }

  // الحصول على معلومات الترخيص المحفوظة
  Future<Map<String, dynamic>?> getLicenseInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final licenseJson = prefs.getString(_licenseKey);
      if (licenseJson != null) {
        return jsonDecode(licenseJson);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // التحقق من الترخيص المحفوظ
  Future<LicenseStatus> checkStoredLicense() async {
    final licenseInfo = await getLicenseInfo();
    if (licenseInfo == null) {
      return LicenseStatus.notActivated;
    }
    
    final deviceId = await _getDeviceId();
    if (licenseInfo['device'] != deviceId) {
      return LicenseStatus.wrongDevice;
    }
    
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(licenseInfo['expires']);
    if (DateTime.now().isAfter(expiryDate)) {
      return LicenseStatus.expired;
    }
    
    return LicenseStatus.valid;
  }

  // حذف الترخيص (لإلغاء التفعيل)
  Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
    await prefs.remove(_activationKey);
  }

  // الحصول على معرف الجهاز للعرض
  Future<String> getDeviceIdForDisplay() async {
    final deviceId = await _getDeviceId();
    return deviceId.toUpperCase(); // عرض Device ID كاملاً
  }
}

enum LicenseStatus {
  valid,
  invalid,
  expired,
  wrongDevice,
  tampered,
  notActivated,
}
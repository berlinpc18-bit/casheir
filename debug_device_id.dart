// أداة تشخيص مشكلة Device ID
// تشغيل: dart run debug_device_id.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  print('🔍 تشخيص مشكلة Device ID - BERLIN GAMING');
  print('=' * 60);
  
  try {
    // حساب Device ID بنفس طريقة التطبيق
    final deviceId = await calculateDeviceId();
    
    print('✅ Device ID الذي سيراه العميل:');
    print('   $deviceId');
    print('   الطول: ${deviceId.length} حرف');
    
    // اختبار رمز ترخيص تجريبي
    print('\n🧪 اختبار توليد ترخيص تجريبي...');
    final testLicense = generateTestLicense('عميل تجريبي', deviceId);
    
    print('✅ رمز الترخيص التجريبي:');
    print('   ${testLicense.substring(0, 50)}...');
    
    // فك تشفير الترخيص للتحقق
    print('\n🔍 فك تشفير الترخيص للتحقق:');
    final parts = testLicense.split('.');
    final licenseJson = utf8.decode(base64.decode(parts[0]));
    final licenseData = jsonDecode(licenseJson);
    
    print('   Device في الترخيص: ${licenseData['device']}');
    print('   Device الحقيقي: $deviceId');
    print('   التطابق: ${licenseData['device'] == deviceId ? "✅ نعم" : "❌ لا"}');
    
    // اختبار التحقق
    print('\n🔧 اختبار آلية التحقق:');
    final validationResult = await testValidation(testLicense, deviceId);
    print('   نتيجة التحقق: $validationResult');
    
    print('\n💡 الخلاصة:');
    if (licenseData['device'] == deviceId) {
      print('✅ Device ID صحيح - يجب أن يعمل الترخيص');
      print('❓ إذا لم يعمل، المشكلة في كود آخر');
    } else {
      print('❌ Device ID غير متطابق - هذا سبب المشكلة');
      print('🔧 يجب إصلاح حساب Device ID');
    }
    
  } catch (e) {
    print('❌ خطأ في التشخيص: $e');
  }
}

// حساب Device ID بنفس طريقة التطبيق
Future<String> calculateDeviceId() async {
  const String secretKey = 'YOUR_UNIQUE_SECRET_2025';
  
  try {
    String deviceInfo = '';
    
    if (Platform.isWindows) {
      final result = await Process.run('wmic', ['csproduct', 'get', 'uuid']);
      deviceInfo += result.stdout.toString().replaceAll('UUID', '').trim();
      
      final motherboard = await Process.run('wmic', ['baseboard', 'get', 'serialnumber']);
      deviceInfo += motherboard.stdout.toString().replaceAll('SerialNumber', '').trim();
    }
    
    print('🔍 معلومات الجهاز الخام:');
    print('   "$deviceInfo"');
    
    final bytes = utf8.encode(deviceInfo + secretKey);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32).toUpperCase();
  } catch (e) {
    return 'BACKUP_DEVICE_ID_${Platform.operatingSystem}';
  }
}

// توليد ترخيص تجريبي
String generateTestLicense(String customerName, String deviceId) {
  const String secretKey = 'YOUR_UNIQUE_SECRET_2025';
  
  final activationDate = DateTime.now().millisecondsSinceEpoch;
  final expiryDate = DateTime.now().add(Duration(days: 365)).millisecondsSinceEpoch;
  
  final licenseData = {
    'device': deviceId,
    'customer': customerName,
    'activated': activationDate,
    'expires': expiryDate,
    'version': '1.0.0',
  };
  
  final licenseJson = jsonEncode(licenseData);
  final bytes = utf8.encode(licenseJson + secretKey);
  final digest = sha256.convert(bytes);
  
  return base64.encode(utf8.encode(licenseJson)) + '.' + digest.toString().substring(0, 16);
}

// اختبار التحقق
Future<String> testValidation(String licenseCode, String actualDeviceId) async {
  const String secretKey = 'YOUR_UNIQUE_SECRET_2025';
  
  try {
    final parts = licenseCode.split('.');
    if (parts.length != 2) {
      return 'خطأ: تركيب رمز الترخيص غير صحيح';
    }
    
    final licenseJson = utf8.decode(base64.decode(parts[0]));
    final expectedHash = parts[1];
    
    // التحقق من التوقيع
    final bytes = utf8.encode(licenseJson + secretKey);
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString().substring(0, 16);
    
    if (actualHash != expectedHash) {
      return 'خطأ: التوقيع غير صحيح';
    }
    
    final licenseData = jsonDecode(licenseJson);
    
    // التحقق من Device ID
    if (licenseData['device'] != actualDeviceId) {
      return 'خطأ: Device ID غير متطابق';
    }
    
    // التحقق من انتهاء الصلاحية
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(licenseData['expires']);
    if (DateTime.now().isAfter(expiryDate)) {
      return 'خطأ: الترخيص منتهي الصلاحية';
    }
    
    return '✅ صحيح - يجب أن يعمل';
  } catch (e) {
    return 'خطأ: $e';
  }
}
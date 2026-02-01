// أداة للحصول على Device ID الصحيح
// تشغيل: dart run get_device_id.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  print('🔑 أداة الحصول على Device ID الصحيح');
  print('=' * 60);
  
  try {
    final deviceId = await getDeviceId();
    
    print('\n✅ Device ID للجهاز الحالي:');
    print('=' * 60);
    print('📱 الرمز الكامل: $deviceId');
    print('🔍 الرمز المختصر: ${deviceId.substring(0, 8).toUpperCase()}');
    print('=' * 60);
    
    print('\n📋 تعليمات للعميل:');
    print('1. شغل التطبيق على جهاز العميل');
    print('2. سيظهر Device ID في شاشة التفعيل');  
    print('3. العميل ينسخ الرمز ويرسله لك');
    print('4. استخدم الرمز الكامل (32 رقم/حرف) في مولد الترخيص');
    
    print('\n💡 ملاحظة: هذا Device ID للجهاز الذي تعمل عليه الآن');
    print('   العميل سيحصل على Device ID مختلف لجهازه');
    
  } catch (e) {
    print('❌ خطأ في الحصول على Device ID: $e');
  }
}

// نفس دالة Device ID من license_manager.dart
Future<String> getDeviceId() async {
  const String secretKey = 'YOUR_UNIQUE_SECRET_2025';
  
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
    final bytes = utf8.encode(deviceInfo + secretKey);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  } catch (e) {
    // في حالة فشل الحصول على المعرف، استخدم معرف احتياطي
    return 'BACKUP_DEVICE_ID_${Platform.operatingSystem}';
  }
}
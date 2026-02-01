// فحص الترخيص المحدد
// تشغيل: dart run check_specific_license.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  print('🔍 فحص الترخيص المحدد');
  print('=' * 60);
  
  final deviceId = '4ADFC0808273C87538896F207EF8E90F';
  final licenseCode = 'eyJkZXZpY2UiOiI0QURGQzA4MDgyNzNDODc1Mzg4OTZGMjA3RUY4RTkwRiIsImN1c3RvbWVyIjoiT01BUiBZQVNFUiIsImFjdGl2YXRlZCI6MTc1OTU1MDY3ODM0MywiZXhwaXJlcyI6MTc5MDY1NDY3ODM0MywidmVyc2lvbiI6IjEuMC4wIn0=.676b5311fdc7c267';
  
  print('📱 Device ID المعطى:');
  print('   $deviceId');
  print('   الطول: ${deviceId.length}');
  
  print('\n🔑 رمز الترخيص:');
  print('   ${licenseCode.substring(0, 50)}...');
  
  try {
    // فك تشفير الترخيص
    final parts = licenseCode.split('.');
    if (parts.length != 2) {
      print('❌ خطأ: تركيب رمز الترخيص غير صحيح');
      return;
    }
    
    final licenseJson = utf8.decode(base64.decode(parts[0]));
    final expectedHash = parts[1];
    
    print('\n📋 محتوى الترخيص:');
    final licenseData = jsonDecode(licenseJson);
    print('   Device في الترخيص: ${licenseData['device']}');
    print('   العميل: ${licenseData['customer']}');
    print('   تاريخ التفعيل: ${DateTime.fromMillisecondsSinceEpoch(licenseData['activated'])}');
    print('   تاريخ انتهاء الصلاحية: ${DateTime.fromMillisecondsSinceEpoch(licenseData['expires'])}');
    print('   الإصدار: ${licenseData['version']}');
    
    print('\n🔍 فحص التطابق:');
    print('   Device ID المعطى: $deviceId');
    print('   Device ID في الترخيص: ${licenseData['device']}');
    
    if (deviceId == licenseData['device']) {
      print('   ✅ Device ID متطابق');
    } else {
      print('   ❌ Device ID غير متطابق');
      print('   الفرق: ${deviceId.length != licenseData['device'].length ? "الطول مختلف" : "المحتوى مختلف"}');
      
      // مقارنة حرف بحرف
      print('\n🔍 مقارنة تفصيلية:');
      final given = deviceId.split('');
      final inLicense = licenseData['device'].split('');
      
      for (int i = 0; i < given.length && i < inLicense.length; i++) {
        if (given[i] != inLicense[i]) {
          print('   الموضع $i: معطى="${given[i]}" في الترخيص="${inLicense[i]}"');
        }
      }
    }
    
    // فحص التوقيع
    print('\n🔐 فحص التوقيع:');
    const String secretKey = 'YOUR_UNIQUE_SECRET_2025';
    final bytes = utf8.encode(licenseJson + secretKey);
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString().substring(0, 16);
    
    print('   التوقيع المتوقع: $expectedHash');
    print('   التوقيع الفعلي: $actualHash');
    print('   تطابق التوقيع: ${actualHash == expectedHash ? "✅ صحيح" : "❌ خطأ"}');
    
    // فحص انتهاء الصلاحية
    print('\n⏰ فحص الصلاحية:');
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(licenseData['expires']);
    final now = DateTime.now();
    print('   تاريخ الانتهاء: $expiryDate');
    print('   التاريخ الحالي: $now');
    print('   منتهي الصلاحية: ${now.isAfter(expiryDate) ? "❌ نعم" : "✅ لا"}');
    
    print('\n🎯 الخلاصة النهائية:');
    if (deviceId != licenseData['device']) {
      print('❌ المشكلة: Device ID غير متطابق');
      print('💡 الحل: استخدم Device ID الصحيح: ${licenseData['device']}');
    } else if (actualHash != expectedHash) {
      print('❌ المشكلة: التوقيع غير صحيح');
      print('💡 الحل: أعد توليد الترخيص');
    } else if (now.isAfter(expiryDate)) {
      print('❌ المشكلة: الترخيص منتهي الصلاحية');
      print('💡 الحل: أعد توليد ترخيص جديد');
    } else {
      print('✅ الترخيص صحيح تماماً - يجب أن يعمل!');
      print('❓ إذا لم يعمل، المشكلة في كود التطبيق');
    }
    
  } catch (e) {
    print('❌ خطأ في فك التشفير: $e');
  }
}
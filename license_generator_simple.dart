// مولد رموز الترخيص - إصدار مبسط
// تشغيل: dart run license_generator_simple.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  print('🔑 مولد رموز الترخيص - BERLIN GAMING');
  print('=' * 60);
  
  // الحصول على معلومات العميل
  stdout.write('أدخل اسم العميل: ');
  final customerName = stdin.readLineSync() ?? '';
  
  stdout.write('أدخل Device ID الذي أرسله العميل: ');
  final deviceId = stdin.readLineSync() ?? '';
  
  stdout.write('أدخل عدد الأيام الصالحة (افتراضي 365): ');
  final daysInput = stdin.readLineSync() ?? '365';
  final validDays = int.tryParse(daysInput) ?? 365;
  
  if (customerName.isEmpty || deviceId.isEmpty) {
    print('❌ اسم العميل و Device ID مطلوبان');
    return;
  }
  
  print('\n⏳ جاري توليد رمز الترخيص...');
  print('-' * 60);
  
  try {
    // توليد رمز الترخيص
    final licenseCode = generateLicenseForDevice(customerName, deviceId, validDays);
    final expiryDate = DateTime.now().add(Duration(days: validDays));
    
    print('\n✅ تم توليد رمز الترخيص بنجاح!');
    print('=' * 60);
    print('📋 معلومات الترخيص:');
    print('   العميل: $customerName');
    print('   Device ID: $deviceId');
    print('   صالح حتى: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}');
    print('   عدد الأيام: $validDays يوم');
    print('=' * 60);
    print('🔑 رمز الترخيص:');
    print('\n$licenseCode\n');
    print('=' * 60);
    
    // حفظ في ملف نصي
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'license_${customerName.replaceAll(' ', '_')}_$timestamp.txt';
    final file = File(fileName);
    
    await file.writeAsString('''
🔑 معلومات ترخيص BERLIN GAMING
================================

📋 معلومات العميل:
   الاسم: $customerName
   Device ID: $deviceId
   تاريخ الإنشاء: ${DateTime.now()}
   صالح حتى: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}
   المدة: $validDays يوم

🔑 رمز الترخيص:
$licenseCode

📱 تعليمات للعميل:
1. افتح تطبيق BERLIN GAMING
2. انسخ رمز الترخيص أعلاه
3. الصقه في شاشة التفعيل
4. اضغط "تفعيل الترخيص"

⚠️  ملاحظات مهمة:
- هذا الرمز صالح فقط للجهاز المحدد أعلاه
- لا يمكن استخدامه على أجهزة أخرى
- احتفظ بهذا الملف للمراجعة المستقبلية

🔒 للدعم الفني: تواصل مع المطور
================================
''');
    
    print('💾 تم حفظ معلومات الترخيص في: $fileName');
    print('\n📨 أرسل رمز الترخيص للعميل الآن!');
    
  } catch (e) {
    print('❌ خطأ في توليد الترخيص: $e');
  }
  
  print('\nاضغط Enter للخروج...');
  stdin.readLineSync();
}

// دالة توليد الترخيص (نسخة مبسطة من LicenseManager)
String generateLicenseForDevice(String customerName, String deviceId, int validDays) {
  const String secretKey = 'YOUR_UNIQUE_SECRET_2025';
  
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
  final bytes = utf8.encode(licenseJson + secretKey);
  final digest = sha256.convert(bytes);
  
  return base64.encode(utf8.encode(licenseJson)) + '.' + digest.toString().substring(0, 16);
}
// مولد تراخيص محسن بحماية متقدمة
// تشغيل: dart run secure_license_generator.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:berlin_gaming_cashier/advanced_security_manager.dart';

void main() async {
  print('🔒 مولد التراخيص المحمي - BERLIN GAMING v2.0');
  print('=' * 70);
  
  try {
    final securityManager = AdvancedSecurityManager();
    
    // فحص أمني أولي
    print('🔍 إجراء فحص أمني...');
    final securityCheck = await securityManager.performSecurityCheck();
    
    if (!securityCheck.isSecure) {
      print('⚠️ تحذير أمني:');
      if (securityCheck.isTampered) print('   - تم اكتشاف تلاعب في النظام');
      if (securityCheck.isVirtualMachine) print('   - تم اكتشاف بيئة افتراضية');
      if (securityCheck.hasDebugger) print('   - تم اكتشاف أدوات تصحيح');
      
      stdout.write('هل تريد المتابعة رغم المخاطر؟ (y/N): ');
      final confirm = stdin.readLineSync()?.toLowerCase();
      if (confirm != 'y' && confirm != 'yes') {
        print('تم إيقاف العملية لأسباب أمنية');
        return;
      }
    } else {
      print('✅ البيئة آمنة');
    }
    
    // الحصول على بصمة الجهاز المتقدمة
    print('\n🔑 توليد بصمة الجهاز المتقدمة...');
    final deviceFingerprint = await securityManager.getAdvancedDeviceFingerprint();
    print('✅ بصمة الجهاز: ${deviceFingerprint.substring(0, 16)}...***');
    
    // إدخال معلومات العميل
    stdout.write('\nأدخل اسم العميل: ');
    final customerName = stdin.readLineSync() ?? '';
    
    stdout.write('أدخل Device Fingerprint العميل (أو اتركه فارغ لاستخدام الجهاز الحالي): ');
    final clientFingerprint = stdin.readLineSync();
    final finalFingerprint = clientFingerprint?.isEmpty == false ? clientFingerprint! : deviceFingerprint;
    
    stdout.write('أدخل عدد الأيام الصالحة (افتراضي 365): ');
    final daysInput = stdin.readLineSync() ?? '365';
    final validDays = int.tryParse(daysInput) ?? 365;
    
    if (customerName.isEmpty) {
      print('❌ اسم العميل مطلوب');
      return;
    }
    
    print('\n⏳ توليد الترخيص المحمي...');
    
    // توليد الترخيص مع الحماية المتقدمة
    final licenseData = {
      'device': finalFingerprint,
      'customer': customerName,
      'activated': DateTime.now().millisecondsSinceEpoch,
      'expires': DateTime.now().add(Duration(days: validDays)).millisecondsSinceEpoch,
      'version': '2.0.0',
      'security': {
        'vm_check': !securityCheck.isVirtualMachine,
        'debug_check': !securityCheck.hasDebugger,
        'tamper_check': !securityCheck.isTampered,
        'generation_time': DateTime.now().millisecondsSinceEpoch,
      }
    };
    
    final licenseJson = jsonEncode(licenseData);
    final masterKey = 'BERLIN_GAMING_2025_ULTRA_SECURE';
    
    // تشفير متعدد المراحل
    final stage1Hash = sha256.convert(utf8.encode(licenseJson + masterKey)).toString();
    final stage2Hash = sha256.convert(utf8.encode(stage1Hash + finalFingerprint)).toString();
    final finalHash = stage2Hash.substring(0, 24);
    
    final secureLicense = base64.encode(utf8.encode(licenseJson)) + '.' + finalHash;
    
    final expiryDate = DateTime.now().add(Duration(days: validDays));
    
    print('\n🎉 تم توليد الترخيص المحمي بنجاح!');
    print('=' * 70);
    print('📋 معلومات الترخيص:');
    print('   العميل: $customerName');
    print('   Device Fingerprint: ${finalFingerprint.substring(0, 20)}...***');
    print('   صالح حتى: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}');
    print('   المدة: $validDays يوم');
    print('   نسخة الحماية: 2.0.0 (محسنة)');
    print('=' * 70);
    print('🔒 الترخيص المحمي:');
    print('\n$secureLicense\n');
    print('=' * 70);
    
    // حفظ في ملف
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'secure_license_${customerName.replaceAll(' ', '_')}_$timestamp.txt';
    final file = File(fileName);
    
    await file.writeAsString('''
🔒 ترخيص BERLIN GAMING المحمي v2.0
====================================

📋 معلومات العميل:
   الاسم: $customerName
   Device Fingerprint: $finalFingerprint
   تاريخ الإنشاء: ${DateTime.now()}
   صالح حتى: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}
   المدة: $validDays يوم

🔒 الترخيص المحمي:
$secureLicense

🛡️ مميزات الحماية:
- بصمة جهاز متقدمة (7 مكونات)
- فحص البيئة الافتراضية
- كشف أدوات التصحيح
- تشفير متعدد المراحل
- مقاوم للتلاعب

📱 تعليمات للعميل:
1. تشغيل BERLIN GAMING v2.0 المحسن
2. لصق الترخيص في شاشة التفعيل
3. التفعيل التلقائي

⚠️ تحذيرات أمنية:
- لا يعمل على الأجهزة الافتراضية
- لا يعمل مع أدوات التصحيح
- مقاوم للنسخ والتقليد
- مرتبط بالجهاز فقط

🔐 مستوى الأمان: عالي جداً
====================================
''');
    
    print('💾 تم حفظ معلومات الترخيص في: $fileName');
    print('\n🚀 الترخيص جاهز للإرسال - حماية متقدمة!');
    
  } catch (e) {
    print('❌ خطأ: $e');
  }
  
  print('\nاضغط Enter للخروج...');
  stdin.readLineSync();
}
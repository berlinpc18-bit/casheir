import 'package:flutter/material.dart';
import 'printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبار سريع لحفظ وتحميل إعدادات الطابعات
class PrinterSettingsTest {
  static Future<void> testSettingsPersistence() async {
    print('🧪 بدء اختبار حفظ وتحميل الإعدادات...');
    
    final printerService = PrinterService();
    
    // إعدادات اختبارية
    Map<String, String> testCategoryMapping = {
      'قهوة': 'barista',
      'شاي': 'barista',
      'طعام': 'kitchen',
      'شيشة': 'shisha',
    };
    
    print('📝 حفظ إعدادات الاختبار...');
    
    // حفظ الإعدادات
    await printerService.updatePrinterSettings(
      kitchenIP: '192.168.1.100',
      baristaIP: '192.168.1.101',
      cashierIP: '192.168.1.102',
      shishaIP: '192.168.1.103',
      backupIP: '192.168.1.104',
      enableKitchen: true,
      enableBarista: true,
      enableCashier: false, // مُعطل للاختبار
      enableShisha: true,
      enableBackup: false, // مُعطل للاختبار
      useNetwork: true,
      categoryMapping: testCategoryMapping,
    );
    
    await Future.delayed(Duration(milliseconds: 500)); // انتظار للتأكد من الحفظ
    
    print('📖 تحميل الإعدادات وفحصها...');
    
    // قراءة الإعدادات المحفوظة
    final savedMapping = printerService.categoryToPrinter;
    final kitchenEnabled = printerService.printKitchenReceipts;
    final baristaEnabled = printerService.printBaristaReceipts;
    final cashierEnabled = printerService.printCashierReceipts;
    final shishaEnabled = printerService.printShishaReceipts;
    final backupEnabled = printerService.printBackupReceipts;
    
    // فحص النتائج
    bool testPassed = true;
    String errors = '';
    
    // فحص ربط الأقسام
    for (String category in testCategoryMapping.keys) {
      String expected = testCategoryMapping[category]!;
      String? actual = savedMapping[category];
      
      if (actual != expected) {
        testPassed = false;
        errors += '\n❌ القسم "$category": متوقع "$expected", لكن الفعلي "$actual"';
      } else {
        print('✅ القسم "$category": محفوظ بشكل صحيح كـ "$actual"');
      }
    }
    
    // فحص حالات الطابعات
    if (!kitchenEnabled) {
      testPassed = false;
      errors += '\n❌ طابعة المطبخ يجب أن تكون مفعلة';
    }
    
    if (!baristaEnabled) {
      testPassed = false;
      errors += '\n❌ طابعة الباريستا يجب أن تكون مفعلة';
    }
    
    if (cashierEnabled) {
      testPassed = false;
      errors += '\n❌ طابعة الكاشير يجب أن تكون معطلة';
    }
    
    if (!shishaEnabled) {
      testPassed = false;
      errors += '\n❌ طابعة اراكيل يجب أن تكون مفعلة';
    }
    
    if (backupEnabled) {
      testPassed = false;
      errors += '\n❌ الطابعة الاحتياطية يجب أن تكون معطلة';
    }
    
    // النتائج
    if (testPassed) {
      print('🎉 الاختبار نجح! جميع الإعدادات محفوظة ومحملة بشكل صحيح.');
    } else {
      print('💥 الاختبار فشل! هناك مشاكل في الحفظ:$errors');
    }
    
    return;
  }
  
  /// فحص الإعدادات المحفوظة مباشرة من SharedPreferences
  static Future<void> inspectSavedSettings() async {
    print('🔍 فحص الإعدادات المحفوظة في SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('📊 الإعدادات المحفوظة:');
      print('Kitchen IP: ${prefs.getString('kitchen_printer_ip')}');
      print('Barista IP: ${prefs.getString('barista_printer_ip')}');
      print('Cashier IP: ${prefs.getString('cashier_printer_ip')}');
      print('Shisha IP: ${prefs.getString('shisha_printer_ip')}');
      print('Backup IP: ${prefs.getString('backup_printer_ip')}');
      
      print('Kitchen enabled: ${prefs.getBool('print_kitchen_receipts')}');
      print('Barista enabled: ${prefs.getBool('print_barista_receipts')}');
      print('Cashier enabled: ${prefs.getBool('print_cashier_receipts')}');
      print('Shisha enabled: ${prefs.getBool('print_shisha_receipts')}');
      print('Backup enabled: ${prefs.getBool('print_backup_receipts')}');
      
      print('Network enabled: ${prefs.getBool('use_network_printers')}');
      print('Category mapping: ${prefs.getString('category_to_printer_mapping')}');
      
      print('✅ انتهى فحص الإعدادات المحفوظة');
      
    } catch (e) {
      print('❌ خطأ في فحص الإعدادات: $e');
    }
  }

  /// اختبار سريع للاستدعاء من صفحة الإعدادات
  static Widget buildTestButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🧪 جاري اختبار حفظ الإعدادات...')),
          );
          
          await testSettingsPersistence();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ انتهى الاختبار، راجع الكونسول للنتائج'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: Icon(Icons.bug_report),
        label: Text('اختبار حفظ الإعدادات'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
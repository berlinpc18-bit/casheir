import 'dart:io';
import 'data_persistence_manager.dart';

/// سكريبت تنظيف تلقائي للملفات الاحتياطية
/// يمكن تشغيله عبر مهام Windows المجدولة لتنظيف دوري
void main() async {
  print('🧹 بدء عملية التنظيف التلقائي للملفات الاحتياطية...');
  
  try {
    final manager = DataPersistenceManager();
    
    // الحصول على معلومات الملفات قبل التنظيف
    final infoBefore = await manager.getBackupFilesInfo();
    print('📊 الملفات قبل التنظيف: ${infoBefore['total_files']} ملف');
    print('📦 الحجم قبل التنظيف: ${infoBefore['total_size_mb']} ميجابايت');
    
    // تنظيف الملفات (الاحتفاظ بـ 3 ملفات فقط)
    await manager.cleanupOldBackups(keepCount: 3);
    
    // الحصول على معلومات الملفات بعد التنظيف
    final infoAfter = await manager.getBackupFilesInfo();
    print('📊 الملفات بعد التنظيف: ${infoAfter['total_files']} ملف');
    print('📦 الحجم بعد التنظيف: ${infoAfter['total_size_mb']} ميجابايت');
    
    final deletedFiles = (infoBefore['total_files'] as int) - (infoAfter['total_files'] as int);
    final savedSpace = (double.parse(infoBefore['total_size_mb'] as String) - 
                       double.parse(infoAfter['total_size_mb'] as String)).toStringAsFixed(2);
    
    print('✅ تم حذف $deletedFiles ملف');
    print('💾 تم توفير $savedSpace ميجابايت من المساحة');
    print('🎉 انتهت عملية التنظيف بنجاح!');
    
  } catch (e) {
    print('❌ حدث خطأ أثناء التنظيف: $e');
    exit(1);
  }
  
  exit(0);
}
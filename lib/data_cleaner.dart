import 'dart:io';

/// خدمة تنظيف البيانات والملفات المؤقتة
class DataCleaner {
  static final DataCleaner _instance = DataCleaner._internal();
  factory DataCleaner() => _instance;
  DataCleaner._internal();

  /// تنظيف شامل لجميع المجلدات والملفات القديمة
  Future<void> performFullCleanup() async {
    final appDir = Directory.current.path;
    
    await _cleanupOldDataFolders(appDir);
    await _cleanupTempFiles(appDir);
    await _cleanupLogFiles(appDir);
    
    print('🧹 تم إكمال التنظيف الشامل');
  }

  /// حذف المجلدات القديمة من النسخ السابقة
  Future<void> _cleanupOldDataFolders(String appDir) async {
    try {
      final parentDir = Directory(appDir);
      if (!await parentDir.exists()) return;
      
      final allItems = parentDir.listSync();
      
      // أنماط المجلدات القديمة التي يجب حذفها
      final oldPatterns = [
        'safe_data_',
        'emergency_backup_',
        'temp_data_',
        'backup_data_',
        'hive_backup_',
        'data_backup_',
        '.hive_',
      ];
      
      int deletedCount = 0;
      
      for (var item in allItems) {
        if (item is Directory) {
          final dirName = item.path.split(Platform.pathSeparator).last;
          
          // تحقق من المجلدات القديمة
          bool shouldDelete = false;
          for (String pattern in oldPatterns) {
            if (dirName.startsWith(pattern)) {
              shouldDelete = true;
              break;
            }
          }
          
          // حذف المجلدات القديمة التي تزيد عن 7 أيام
          if (shouldDelete) {
            try {
              final stat = await item.stat();
              final daysSinceModified = DateTime.now().difference(stat.modified).inDays;
              
              if (daysSinceModified > 0) { // حذف فوري للمجلدات القديمة
                await item.delete(recursive: true);
                deletedCount++;
                print('🗑️ تم حذف المجلد القديم: $dirName');
              }
            } catch (e) {
              print('خطأ في حذف المجلد $dirName: $e');
            }
          }
        }
      }
      
      if (deletedCount > 0) {
        print('✅ تم تنظيف $deletedCount مجلد قديم');
      }
    } catch (e) {
      print('خطأ في تنظيف المجلدات القديمة: $e');
    }
  }

  /// حذف الملفات المؤقتة
  Future<void> _cleanupTempFiles(String appDir) async {
    try {
      final tempFilePatterns = [
        'test_init.txt',
        'debug.log',
        'temp_backup.dat',
        '*.tmp',
        '*.cache',
        '*.lock',
      ];
      
      final dir = Directory(appDir);
      final files = dir.listSync(recursive: false).whereType<File>();
      
      int deletedCount = 0;
      
      for (var file in files) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        
        bool shouldDelete = false;
        for (String pattern in tempFilePatterns) {
          if (pattern.contains('*')) {
            final extension = pattern.substring(1);
            if (fileName.endsWith(extension)) {
              shouldDelete = true;
              break;
            }
          } else if (fileName == pattern) {
            shouldDelete = true;
            break;
          }
        }
        
        if (shouldDelete) {
          try {
            await file.delete();
            deletedCount++;
            print('🗑️ تم حذف الملف المؤقت: $fileName');
          } catch (e) {
            print('تحذير عند حذف الملف $fileName: $e');
          }
        }
      }
      
      if (deletedCount > 0) {
        print('✅ تم تنظيف $deletedCount ملف مؤقت');
      }
    } catch (e) {
      print('خطأ في تنظيف الملفات المؤقتة: $e');
    }
  }

  /// حذف ملفات السجلات القديمة
  Future<void> _cleanupLogFiles(String appDir) async {
    try {
      final logsDir = Directory('$appDir/logs');
      if (!await logsDir.exists()) return;
      
      final logFiles = logsDir.listSync().whereType<File>();
      final now = DateTime.now();
      int deletedCount = 0;
      
      for (var file in logFiles) {
        try {
          final stat = await file.stat();
          final daysSinceModified = now.difference(stat.modified).inDays;
          
          // حذف ملفات السجلات الأقدم من 30 يوم
          if (daysSinceModified > 30) {
            await file.delete();
            deletedCount++;
            print('🗑️ تم حذف ملف سجل قديم: ${file.path.split(Platform.pathSeparator).last}');
          }
        } catch (e) {
          print('تحذير عند حذف ملف السجل: $e');
        }
      }
      
      if (deletedCount > 0) {
        print('✅ تم تنظيف $deletedCount ملف سجل قديم');
      }
    } catch (e) {
      print('خطأ في تنظيف ملفات السجلات: $e');
    }
  }

  /// تنظيف سريع للملفات الأساسية فقط
  Future<void> performQuickCleanup() async {
    final appDir = Directory.current.path;
    await _cleanupTempFiles(appDir);
    print('🧹 تم إكمال التنظيف السريع');
  }

  /// حساب حجم المجلدات القديمة
  Future<String> calculateWastedSpace() async {
    try {
      final appDir = Directory.current.path;
      final parentDir = Directory(appDir);
      
      int totalSize = 0;
      int folderCount = 0;
      
      final oldPatterns = [
        'safe_data_',
        'emergency_backup_',
        'temp_data_',
        'backup_data_',
      ];
      
      final allItems = parentDir.listSync();
      
      for (var item in allItems) {
        if (item is Directory) {
          final dirName = item.path.split(Platform.pathSeparator).last;
          
          for (String pattern in oldPatterns) {
            if (dirName.startsWith(pattern)) {
              try {
                final size = await _calculateDirectorySize(item);
                totalSize += size;
                folderCount++;
              } catch (e) {
                print('خطأ في حساب حجم المجلد $dirName: $e');
              }
              break;
            }
          }
        }
      }
      
      if (totalSize == 0) {
        return 'لا توجد ملفات قديمة';
      }
      
      final sizeInMB = (totalSize / (1024 * 1024)).toStringAsFixed(1);
      return '$folderCount مجلد قديم يشغل ${sizeInMB}MB';
      
    } catch (e) {
      return 'خطأ في حساب الحجم: $e';
    }
  }

  /// حساب حجم مجلد معين
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;
    
    try {
      final contents = dir.listSync(recursive: true);
      
      for (var item in contents) {
        if (item is File) {
          try {
            final stat = await item.stat();
            totalSize += stat.size;
          } catch (e) {
            // تجاهل الملفات التي لا يمكن الوصول إليها
          }
        }
      }
    } catch (e) {
      // تجاهل المجلدات التي لا يمكن الوصول إليها
    }
    
    return totalSize;
  }
}
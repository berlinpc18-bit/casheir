// نظام حفظ البيانات المحسن
// يضمن عدم فقدان البيانات نهائياً

import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataPersistenceManager {
  static final DataPersistenceManager _instance = DataPersistenceManager._internal();
  factory DataPersistenceManager() => _instance;
  DataPersistenceManager._internal();

  static const String _backupKey = 'berlin_gaming_backup_data';
  static const String _lastSaveKey = 'last_save_timestamp';
  
  // حفظ البيانات في مصادر متعددة
  Future<void> saveAllData(Map<String, dynamic> allData) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dataWithTimestamp = {
        'timestamp': timestamp,
        'data': allData,
      };
      
      final jsonString = jsonEncode(dataWithTimestamp);
      
      // 1. حفظ في SharedPreferences (أولوية أولى)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKey, jsonString);
      await prefs.setInt(_lastSaveKey, timestamp);
      
      // 2. حفظ في ملف نصي (أولوية ثانية)
      final appDir = Directory.current.path;
      final backupFile = File('$appDir/berlin_gaming_backup.json');
      await backupFile.writeAsString(jsonString);
      
      // 3. حفظ في ملف احتياطي إضافي (أولوية ثالثة) - فقط مرة واحدة كل ساعة
      await _createEmergencyBackupIfNeeded(jsonString, timestamp);
      
      // 4. تنظيف الملفات القديمة تلقائياً
      await _autoCleanupOldBackups();
      
      print('✅ تم حفظ البيانات في مصادر متعددة مع تنظيف تلقائي');
      
    } catch (e) {
      print('❌ خطأ في حفظ البيانات: $e');
    }
  }

  // إنشاء نسخة احتياطية طارئة فقط عند الحاجة
  Future<void> _createEmergencyBackupIfNeeded(String jsonString, int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmergencyBackup = prefs.getInt('last_emergency_backup') ?? 0;
      
      // إنشاء نسخة احتياطية طارئة فقط كل ساعة (3600000 مللي ثانية)
      if (timestamp - lastEmergencyBackup > 3600000) {
        final appDir = Directory.current.path;
        final emergencyFile = File('$appDir/emergency_backup_${timestamp}.json');
        await emergencyFile.writeAsString(jsonString);
        await prefs.setInt('last_emergency_backup', timestamp);
        print('📁 تم إنشاء نسخة احتياطية طارئة جديدة');
      }
    } catch (e) {
      print('تحذير: لم يتم إنشاء النسخة الاحتياطية الطارئة: $e');
    }
  }

  // تنظيف تلقائي محسن للملفات القديمة
  Future<void> _autoCleanupOldBackups() async {
    try {
      final appDir = Directory.current.path;
      final emergencyFiles = Directory(appDir)
          .listSync()
          .where((file) => 
              file is File && 
              file.path.contains('emergency_backup_') && 
              file.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      if (emergencyFiles.length <= 3) return; // احتفظ بـ 3 ملفات على الأقل
      
      // ترتيب الملفات حسب تاريخ الإنشاء (الأحدث أولاً)
      emergencyFiles.sort((a, b) {
        try {
          final timestampA = _extractTimestampFromFilename(a.path);
          final timestampB = _extractTimestampFromFilename(b.path);
          return timestampB.compareTo(timestampA);
        } catch (e) {
          return b.statSync().modified.compareTo(a.statSync().modified);
        }
      });
      
      // احذف الملفات الزائدة (احتفظ بآخر 3 فقط)
      int deletedCount = 0;
      for (int i = 3; i < emergencyFiles.length; i++) {
        try {
          await emergencyFiles[i].delete();
          deletedCount++;
        } catch (e) {
          print('تحذير عند حذف ملف قديم: $e');
        }
      }
      
      if (deletedCount > 0) {
        print('🗑️ تم حذف $deletedCount ملف احتياطي قديم تلقائياً');
      }
      
    } catch (e) {
      print('خطأ في التنظيف التلقائي: $e');
    }
  }

  // استخراج الطابع الزمني من اسم الملف
  int _extractTimestampFromFilename(String path) {
    try {
      final match = RegExp(r'emergency_backup_(\d+)\.json').firstMatch(path);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      // في حالة الخطأ، استخدم تاريخ الملف
    }
    return 0;
  }
  
  // استرداد البيانات من أفضل مصدر متاح
  Future<Map<String, dynamic>?> loadAllData() async {
    Map<String, dynamic>? latestData;
    int latestTimestamp = 0;
    
    try {
      // 1. محاولة استرداد من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefData = prefs.getString(_backupKey);
      if (prefData != null) {
        final decoded = jsonDecode(prefData);
        if (decoded['timestamp'] > latestTimestamp) {
          latestTimestamp = decoded['timestamp'];
          latestData = decoded['data'];
          print('✅ تم استرداد البيانات من SharedPreferences');
        }
      }
      
      // 2. محاولة استرداد من الملف الرئيسي
      final appDir = Directory.current.path;
      final backupFile = File('$appDir/berlin_gaming_backup.json');
      if (await backupFile.exists()) {
        final fileContent = await backupFile.readAsString();
        final decoded = jsonDecode(fileContent);
        if (decoded['timestamp'] > latestTimestamp) {
          latestTimestamp = decoded['timestamp'];
          latestData = decoded['data'];
          print('✅ تم استرداد البيانات من الملف الرئيسي');
        }
      }
      
      // 3. البحث في ملفات الطوارئ
      final emergencyFiles = Directory(appDir)
          .listSync()
          .where((file) => file.path.contains('emergency_backup_'))
          .cast<File>();
      
      for (var file in emergencyFiles) {
        try {
          final content = await file.readAsString();
          final decoded = jsonDecode(content);
          if (decoded['timestamp'] > latestTimestamp) {
            latestTimestamp = decoded['timestamp'];
            latestData = decoded['data'];
            print('✅ تم استرداد البيانات من ملف الطوارئ: ${file.path}');
          }
        } catch (e) {
          print('تحذير عند قراءة ملف طوارئ: $e');
        }
      }
      
    } catch (e) {
      print('❌ خطأ في استرداد البيانات: $e');
    }
    
    if (latestData != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);
      print('📅 تم استرداد البيانات المحفوظة في: $date');
    }
    
    return latestData;
  }
  
  // حفظ بيانات محددة (للاستخدام السريع)
  Future<void> saveQuickData(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(value);
      await prefs.setString('quick_$key', jsonString);
    } catch (e) {
      print('خطأ في الحفظ السريع: $e');
    }
  }
  
  // استرداد بيانات محددة
  Future<T?> loadQuickData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('quick_$key');
      if (jsonString != null) {
        return jsonDecode(jsonString) as T;
      }
    } catch (e) {
      print('خطأ في الاسترداد السريع: $e');
    }
    return null;
  }
  
  // تنظيف الملفات القديمة (للاستخدام اليدوي)
  Future<void> cleanupOldBackups({int keepCount = 3}) async {
    try {
      final appDir = Directory.current.path;
      final emergencyFiles = Directory(appDir)
          .listSync()
          .where((file) => 
              file is File && 
              file.path.contains('emergency_backup_') && 
              file.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      if (emergencyFiles.length <= keepCount) {
        print('📁 عدد الملفات الاحتياطية: ${emergencyFiles.length} (لا حاجة للتنظيف)');
        return;
      }
      
      // ترتيب الملفات حسب تاريخ الإنشاء (الأحدث أولاً)
      emergencyFiles.sort((a, b) {
        try {
          final timestampA = _extractTimestampFromFilename(a.path);
          final timestampB = _extractTimestampFromFilename(b.path);
          return timestampB.compareTo(timestampA);
        } catch (e) {
          return b.statSync().modified.compareTo(a.statSync().modified);
        }
      });
      
      // احذف الملفات الزائدة
      int deletedCount = 0;
      for (int i = keepCount; i < emergencyFiles.length; i++) {
        try {
          await emergencyFiles[i].delete();
          deletedCount++;
          print('🗑️ تم حذف: ${emergencyFiles[i].path.split('/').last}');
        } catch (e) {
          print('❌ فشل حذف الملف: $e');
        }
      }
      
      print('✅ تم حذف $deletedCount ملف احتياطي قديم (محتفظ بـ $keepCount ملفات)');
      
    } catch (e) {
      print('❌ خطأ في تنظيف الملفات القديمة: $e');
    }
  }

  // حذف جميع الملفات الاحتياطية الطارئة (للطوارئ فقط)
  Future<void> deleteAllEmergencyBackups() async {
    try {
      final appDir = Directory.current.path;
      final emergencyFiles = Directory(appDir)
          .listSync()
          .where((file) => 
              file is File && 
              file.path.contains('emergency_backup_') && 
              file.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      int deletedCount = 0;
      for (var file in emergencyFiles) {
        try {
          await file.delete();
          deletedCount++;
          print('🗑️ تم حذف: ${file.path.split('/').last}');
        } catch (e) {
          print('❌ فشل حذف الملف: $e');
        }
      }
      
      print('🚨 تم حذف جميع الملفات الاحتياطية الطارئة ($deletedCount ملف)');
      
    } catch (e) {
      print('❌ خطأ في حذف الملفات الاحتياطية: $e');
    }
  }

  // الحصول على معلومات الملفات الاحتياطية
  Future<Map<String, dynamic>> getBackupFilesInfo() async {
    try {
      final appDir = Directory.current.path;
      final emergencyFiles = Directory(appDir)
          .listSync()
          .where((file) => 
              file is File && 
              file.path.contains('emergency_backup_') && 
              file.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      double totalSizeMB = 0;
      List<Map<String, dynamic>> filesInfo = [];
      
      for (var file in emergencyFiles) {
        try {
          final stat = file.statSync();
          final sizeMB = stat.size / (1024 * 1024);
          totalSizeMB += sizeMB;
          
          filesInfo.add({
            'name': file.path.split('/').last,
            'size_mb': sizeMB.toStringAsFixed(2),
            'modified': stat.modified.toString(),
          });
        } catch (e) {
          print('تحذير عند قراءة معلومات الملف: $e');
        }
      }
      
      return {
        'total_files': emergencyFiles.length,
        'total_size_mb': totalSizeMB.toStringAsFixed(2),
        'files': filesInfo,
      };
      
    } catch (e) {
      print('❌ خطأ في الحصول على معلومات الملفات: $e');
      return {
        'total_files': 0,
        'total_size_mb': '0.00',
        'files': [],
      };
    }
  }
}
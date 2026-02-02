import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  
  print('\n📊 SharedPreferences Data:');
  print('================================');
  
  final allKeys = prefs.getKeys();
  print('Total keys: ${allKeys.length}');
  
  for (var key in allKeys) {
    final value = prefs.get(key);
    print('\nKey: $key');
    print('Type: ${value.runtimeType}');
    if (value is String && value.length < 500) {
      print('Value: $value');
    } else if (value is String) {
      print('Value: ${value.substring(0, 500)}...');
    } else {
      print('Value: $value');
    }
  }
  
  // Check for device data specifically
  print('\n\n🔍 Checking for device data:');
  if (prefs.containsKey('devicesData_backup')) {
    print('✅ Found devicesData_backup');
    final deviceData = prefs.getString('devicesData_backup');
    try {
      final decoded = jsonDecode(deviceData!);
      final deviceMap = decoded as Map<String, dynamic>;
      print('Device count: ${deviceMap.length}');
      print('Devices: ${deviceMap.keys.toList()}');
    } catch (e) {
      print('Error decoding: $e');
    }
  } else {
    print('❌ No devicesData_backup found');
  }
  
  if (prefs.containsKey('berlin_gaming_backup_data')) {
    print('✅ Found berlin_gaming_backup_data');
    final backupData = prefs.getString('berlin_gaming_backup_data');
    try {
      final decoded = jsonDecode(backupData!);
      print('Backup timestamp: ${decoded['timestamp']}');
      final data = decoded['data'];
      if (data is Map && data.containsKey('devices')) {
        print('Device count in backup: ${(data['devices'] as Map).length}');
      }
    } catch (e) {
      print('Error decoding: $e');
    }
  } else {
    print('❌ No berlin_gaming_backup_data found');
  }
}

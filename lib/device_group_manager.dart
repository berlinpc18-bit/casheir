import 'dart:async';
import 'package:flutter/material.dart';
import 'sync_service.dart';
import 'local_network_sync_service.dart';
import 'app_state.dart';

/// مدير مجموعة الأجهزة الذكي
class DeviceGroupManager extends ChangeNotifier {
  static final DeviceGroupManager _instance = DeviceGroupManager._internal();
  
  factory DeviceGroupManager() => _instance;
  
  DeviceGroupManager._internal();
  
  final SyncService _syncService = SyncService();
  final LocalNetworkSyncService _networkService = LocalNetworkSyncService();
  
  // معرف مجموعة الأجهزة
  String? groupId;
  
  // قائمة الأجهزة المجمعة
  final Map<String, DeviceGroupData> deviceGroups = {};
  
  // معالج التحديثات
  late StreamSubscription _syncSubscription;
  
  // إعدادات التزامن
  bool autoSync = true;
  int syncInterval = 5; // ثانية
  Timer? _syncTimer;
  
  // سجل المزامنة
  final List<SyncLog> syncLogs = [];
  static const int maxSyncLogs = 100;

  /// تهيئة مدير المجموعة
  Future<void> initialize(String newGroupId) async {
    groupId = newGroupId;
    
    await _syncService.initialize();
    await _networkService.initialize();
    
    _setupSyncListeners();
    _startAutoSync();
    
    print('✓ تم تهيئة مدير مجموعة الأجهزة: $groupId');
  }

  /// إعداد مستمعي المزامنة
  void _setupSyncListeners() {
    _syncSubscription = _syncService.syncEvents.listen((event) {
      _addSyncLog('Event: ${event.type}', event.sourceDevice);
      
      if (event.type == 'device_update' && event.data != null) {
        _handleDeviceUpdate(event.data as DeviceSyncData);
      }
    });
  }

  /// تشغيل المزامنة التلقائية
  void _startAutoSync() {
    if (!autoSync) return;
    
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: syncInterval),
      (_) => _performAutoSync(),
    );
  }

  /// تنفيذ المزامنة التلقائية
  void _performAutoSync() {
    // التحقق من اتصال الأجهزة
    for (final device in _networkService.getDiscoveredDevices()) {
      _addSyncLog('Sync check', device.deviceId);
    }
  }

  /// التعامل مع تحديث الجهاز
  void _handleDeviceUpdate(DeviceSyncData syncData) {
    if (deviceGroups[syncData.deviceId] == null) {
      deviceGroups[syncData.deviceId] = DeviceGroupData(
        deviceId: syncData.deviceId,
        deviceName: syncData.deviceName,
        createdAt: DateTime.now(),
      );
    }
    
    deviceGroups[syncData.deviceId]?.updateState(syncData);
    _addSyncLog('Update received', syncData.deviceId);
    notifyListeners();
  }

  /// تسجيل جهاز جديد في المجموعة
  void registerDeviceInGroup(String deviceName) {
    _syncService.registerDevice(deviceName);
    _addSyncLog('Device registered', _syncService.deviceId);
    notifyListeners();
  }

  /// بث تحديث جهاز إلى جميع أجهزة المجموعة
  Future<void> broadcastDeviceState(String deviceName, DeviceData deviceData) async {
    // إضافة إلى خدمة المزامنة
    _syncService.broadcastDeviceUpdate(deviceName, deviceData);
    
    // إرسال عبر الشبكة المحلية
    final payload = _syncService.generateSyncPayload(deviceData);
    await _networkService.broadcastSyncUpdate(payload);
    
    _addSyncLog('Broadcast sent', _syncService.deviceId);
    notifyListeners();
  }

  /// مزامنة جهاز محدد
  Future<void> syncWithDevice(String targetDeviceId, DeviceData deviceData) async {
    final payload = _syncService.generateSyncPayload(deviceData);
    await _networkService.sendSyncUpdate(targetDeviceId, payload);
    
    _addSyncLog('Direct sync', targetDeviceId);
    notifyListeners();
  }

  /// الحصول على حالة المجموعة الكاملة
  Map<String, dynamic> getGroupState() {
    return {
      'groupId': groupId,
      'deviceCount': deviceGroups.length,
      'devices': deviceGroups.values.map((d) => d.toJson()).toList(),
      'syncStatus': _networkService.getDiscoveredDevices().map((d) => {
        'deviceId': d.deviceId,
        'deviceName': d.deviceName,
        'ipAddress': d.ipAddress,
        'isActive': DateTime.now().difference(d.lastSeen).inSeconds < 30,
      }).toList(),
      'lastSync': DateTime.now().toIso8601String(),
    };
  }

  /// تصدير سجل المزامنة
  String exportSyncLogs() {
    return syncLogs.map((log) => '${log.timestamp} - ${log.action}: ${log.deviceId}').join('\n');
  }

  /// إضافة إدخال إلى سجل المزامنة
  void _addSyncLog(String action, String deviceId) {
    syncLogs.add(SyncLog(
      timestamp: DateTime.now(),
      action: action,
      deviceId: deviceId,
    ));
    
    // الحفاظ على حد أقصى من السجلات
    if (syncLogs.length > maxSyncLogs) {
      syncLogs.removeAt(0);
    }
  }

  /// تعطيل المزامنة التلقائية
  void disableAutoSync() {
    autoSync = false;
    _syncTimer?.cancel();
  }

  /// تفعيل المزامنة التلقائية
  void enableAutoSync() {
    autoSync = true;
    _startAutoSync();
  }

  /// تغيير فترة المزامنة
  void setSyncInterval(int seconds) {
    syncInterval = seconds;
    if (autoSync) {
      _startAutoSync();
    }
  }

  /// إيقاف مدير المجموعة
  void stop() {
    _syncTimer?.cancel();
    _syncSubscription.cancel();
    _networkService.stop();
    _syncService.dispose();
  }
}

/// بيانات مجموعة الجهاز
class DeviceGroupData {
  final String deviceId;
  final String deviceName;
  final DateTime createdAt;
  
  DeviceData? lastKnownState;
  DateTime? lastUpdate;
  bool isOnline = false;

  DeviceGroupData({
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
  });

  void updateState(DeviceSyncData syncData) {
    lastKnownState = syncData.deviceState;
    lastUpdate = syncData.lastUpdate;
    isOnline = syncData.isActive;
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdate': lastUpdate?.toIso8601String(),
    'isOnline': isOnline,
    'state': lastKnownState?.toJson(),
  };
}

/// سجل المزامنة
class SyncLog {
  final DateTime timestamp;
  final String action;
  final String deviceId;

  SyncLog({
    required this.timestamp,
    required this.action,
    required this.deviceId,
  });
}

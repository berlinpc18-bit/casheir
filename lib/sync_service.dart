import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'app_state.dart';

/// خدمة المزامنة المركزية للتحكم المشترك بين الأجهزة
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  static const uuid = Uuid();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  // معرف الجهاز الفريد
  late String deviceId;
  
  // قائمة الأجهزة المتصلة
  final Map<String, DeviceSyncData> connectedDevices = {};
  
  // حالة الاتصال
  bool isOnline = false;
  
  // تدفقات البيانات
  final StreamController<SyncEvent> _syncEventStream = StreamController<SyncEvent>.broadcast();
  final StreamController<DeviceSyncData> _deviceUpdateStream = StreamController<DeviceSyncData>.broadcast();
  
  // المراقب
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  // آخر وقت تم فيه تحديث البيانات
  Map<String, DateTime> lastUpdateTime = {};

  Stream<SyncEvent> get syncEvents => _syncEventStream.stream;
  Stream<DeviceSyncData> get deviceUpdates => _deviceUpdateStream.stream;

  /// تهيئة خدمة المزامنة
  Future<void> initialize() async {
    // توليد معرف فريد للجهاز
    deviceId = uuid.v4();
    
    // مراقبة الاتصال بالشبكة
    _monitorConnectivity();
    
    print('✓ تم تهيئة خدمة المزامنة - معرف الجهاز: $deviceId');
  }

  /// مراقبة الاتصال بالشبكة
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      bool wasOnline = isOnline;
      isOnline = result != ConnectivityResult.none;
      
      if (isOnline != wasOnline) {
        _syncEventStream.add(SyncEvent(
          type: isOnline ? 'connected' : 'disconnected',
          sourceDevice: deviceId,
          timestamp: DateTime.now(),
        ));
        notifyListeners();
      }
    });
  }

  /// تسجيل جهاز جديد في الشبكة
  void registerDevice(String deviceName) {
    final deviceData = DeviceSyncData(
      deviceId: deviceId,
      deviceName: deviceName,
      lastUpdate: DateTime.now(),
      isActive: true,
    );
    
    connectedDevices[deviceId] = deviceData;
    _deviceUpdateStream.add(deviceData);
    
    print('✓ تم تسجيل الجهاز: $deviceName');
  }

  /// بث تحديث من جهاز إلى جميع الأجهزة الأخرى
  void broadcastDeviceUpdate(String deviceName, DeviceData deviceData) {
    final syncData = DeviceSyncData(
      deviceId: deviceId,
      deviceName: deviceName,
      lastUpdate: DateTime.now(),
      isActive: true,
      deviceState: deviceData,
    );
    
    _deviceUpdateStream.add(syncData);
    
    final event = SyncEvent(
      type: 'device_update',
      sourceDevice: deviceId,
      timestamp: DateTime.now(),
      data: syncData,
    );
    
    _syncEventStream.add(event);
    lastUpdateTime[deviceName] = DateTime.now();
  }

  /// استقبال تحديث من جهاز آخر
  void receiveDeviceUpdate(DeviceSyncData syncData) {
    connectedDevices[syncData.deviceId] = syncData;
    _deviceUpdateStream.add(syncData);
    notifyListeners();
  }

  /// الحصول على قائمة الأجهزة المتصلة
  List<DeviceSyncData> getConnectedDevices() {
    return connectedDevices.values.toList();
  }

  /// التحقق من اتصال جهاز معين
  bool isDeviceConnected(String targetDeviceId) {
    final device = connectedDevices[targetDeviceId];
    if (device == null) return false;
    
    final timeSinceUpdate = DateTime.now().difference(device.lastUpdate);
    return timeSinceUpdate.inSeconds < 30;
  }

  /// محاكاة مزامنة محلية (للشبكة المحلية)
  void simulateLocalSync(DeviceData deviceData, String deviceName) {
    broadcastDeviceUpdate(deviceName, deviceData);
  }

  /// إنشاء حمل عمل موحد بين الأجهزة
  Map<String, dynamic> generateSyncPayload(DeviceData deviceData) {
    return {
      'deviceId': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'name': deviceData.name,
        'elapsedTime': deviceData.elapsedTime.inSeconds,
        'isRunning': deviceData.isRunning,
        'orders': deviceData.orders.map((o) => o.toJson()).toList(),
        'notes': deviceData.notes,
        'mode': deviceData.mode,
        'customerCount': deviceData.customerCount,
      },
    };
  }

  /// تنظيف الموارد
  void dispose() {
    _connectivitySubscription.cancel();
    _syncEventStream.close();
    _deviceUpdateStream.close();
    super.dispose();
  }
}

/// بيانات مزامنة الجهاز
class DeviceSyncData {
  final String deviceId;
  final String deviceName;
  final DateTime lastUpdate;
  final bool isActive;
  final DeviceData? deviceState;

  DeviceSyncData({
    required this.deviceId,
    required this.deviceName,
    required this.lastUpdate,
    required this.isActive,
    this.deviceState,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'lastUpdate': lastUpdate.toIso8601String(),
    'isActive': isActive,
    'deviceState': deviceState != null ? deviceState!.toJson() : null,
  };

  factory DeviceSyncData.fromJson(Map<String, dynamic> json) => DeviceSyncData(
    deviceId: json['deviceId'],
    deviceName: json['deviceName'],
    lastUpdate: DateTime.parse(json['lastUpdate']),
    isActive: json['isActive'],
    deviceState: json['deviceState'] != null 
      ? DeviceData.fromJson(json['deviceState']) 
      : null,
  );
}

/// حدث المزامنة
class SyncEvent {
  final String type;
  final String sourceDevice;
  final DateTime timestamp;
  final dynamic data;

  SyncEvent({
    required this.type,
    required this.sourceDevice,
    required this.timestamp,
    this.data,
  });
}

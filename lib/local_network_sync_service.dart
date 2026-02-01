import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'sync_service.dart';

/// خدمة المزامنة عبر الشبكة المحلية (LAN)
class LocalNetworkSyncService {
  static final LocalNetworkSyncService _instance = LocalNetworkSyncService._internal();
  
  factory LocalNetworkSyncService() => _instance;
  
  LocalNetworkSyncService._internal();
  
  final SyncService _syncService = SyncService();
  
  // خادم UDP للاكتشاف
  late DatagramSocket _udpSocket;
  late DatagramSocket _udpBroadcaster;
  
  // قائمة الأجهزة المكتشفة
  final Map<String, NetworkDeviceInfo> discoveredDevices = {};
  
  // بث الاكتشاف
  Timer? _discoveryBroadcaster;
  
  // معالج الرسائل
  late StreamSubscription _socketSubscription;
  
  static const int discoveryPort = 5555;
  static const int syncPort = 5556;
  static const String broadcastAddress = '255.255.255.255';

  /// تهيئة خدمة المزامنة المحلية
  Future<void> initialize() async {
    try {
      // فتح منفذ UDP للاستماع
      _udpSocket = await DatagramSocket.bind(InternetAddress.anyIPv4, syncPort);
      _udpBroadcaster = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
      
      // بدء الاستماع للرسائل
      _startListening();
      
      // بدء بث الاكتشاف
      _startDiscoveryBroadcast();
      
      print('✓ تم تهيئة خدمة المزامنة المحلية على المنفذ $syncPort');
    } catch (e) {
      print('✗ خطأ في تهيئة خدمة المزامنة المحلية: $e');
    }
  }

  /// الاستماع للرسائل الواردة
  void _startListening() {
    _socketSubscription = _udpSocket.asBroadcastStream().listen(
      (datagram) {
        _handleIncomingMessage(datagram);
      },
      onError: (error) {
        print('✗ خطأ في الاستماع: $error');
      },
    );
  }

  /// معالجة الرسائل الواردة
  void _handleIncomingMessage(Datagram datagram) {
    try {
      String message = String.fromCharCodes(datagram.data);
      Map<String, dynamic> data = jsonDecode(message);
      
      if (data['type'] == 'discovery') {
        _handleDiscovery(data, datagram.address);
      } else if (data['type'] == 'sync') {
        _handleSyncMessage(data);
      }
    } catch (e) {
      print('✗ خطأ في معالجة الرسالة: $e');
    }
  }

  /// التعامل مع رسائل الاكتشاف
  void _handleDiscovery(Map<String, dynamic> data, InternetAddress address) {
    final deviceInfo = NetworkDeviceInfo(
      deviceId: data['deviceId'],
      deviceName: data['deviceName'],
      ipAddress: address.address,
      port: data['port'] ?? syncPort,
      lastSeen: DateTime.now(),
    );
    
    discoveredDevices[data['deviceId']] = deviceInfo;
    print('✓ تم اكتشاف جهاز: ${data['deviceName']} على ${address.address}');
  }

  /// التعامل مع رسائل المزامنة
  void _handleSyncMessage(Map<String, dynamic> data) {
    try {
      final syncData = DeviceSyncData.fromJson(data['payload']);
      _syncService.receiveDeviceUpdate(syncData);
      print('✓ تم استقبال تحديث من: ${syncData.deviceName}');
    } catch (e) {
      print('✗ خطأ في معالجة رسالة المزامنة: $e');
    }
  }

  /// بث الاكتشاف
  void _startDiscoveryBroadcast() {
    _discoveryBroadcaster ??= Timer.periodic(
      Duration(seconds: 10),
      (_) => _broadcastDiscovery(),
    );
  }

  /// بث رسالة الاكتشاف
  Future<void> _broadcastDiscovery() async {
    try {
      final message = jsonEncode({
        'type': 'discovery',
        'deviceId': _syncService.deviceId,
        'deviceName': 'Device-${_syncService.deviceId.substring(0, 8)}',
        'port': syncPort,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      final bytes = utf8.encode(message);
      
      try {
        await _udpBroadcaster.send(
          bytes,
          InternetAddress(broadcastAddress),
          discoveryPort,
        );
      } catch (e) {
        // محاولة إرسال للعنوان المحلي كبديل
        await _udpBroadcaster.send(
          bytes,
          InternetAddress('127.255.255.255'),
          discoveryPort,
        );
      }
    } catch (e) {
      print('✗ خطأ في بث الاكتشاف: $e');
    }
  }

  /// إرسال تحديث المزامنة إلى جهاز محدد
  Future<void> sendSyncUpdate(String targetDeviceId, Map<String, dynamic> payload) async {
    try {
      final device = discoveredDevices[targetDeviceId];
      if (device == null) {
        print('✗ الجهاز المستهدف غير مكتشف: $targetDeviceId');
        return;
      }
      
      final message = jsonEncode({
        'type': 'sync',
        'sourceDeviceId': _syncService.deviceId,
        'payload': payload,
      });
      
      final bytes = utf8.encode(message);
      
      await _udpBroadcaster.send(
        bytes,
        InternetAddress(device.ipAddress),
        device.port,
      );
      
      print('✓ تم إرسال تحديث إلى: ${device.deviceName}');
    } catch (e) {
      print('✗ خطأ في إرسال التحديث: $e');
    }
  }

  /// بث التحديث لجميع الأجهزة
  Future<void> broadcastSyncUpdate(Map<String, dynamic> payload) async {
    try {
      final message = jsonEncode({
        'type': 'sync',
        'sourceDeviceId': _syncService.deviceId,
        'payload': payload,
      });
      
      final bytes = utf8.encode(message);
      
      for (final device in discoveredDevices.values) {
        try {
          await _udpBroadcaster.send(
            bytes,
            InternetAddress(device.ipAddress),
            device.port,
          );
        } catch (e) {
          print('⚠ خطأ في إرسال التحديث إلى ${device.deviceName}: $e');
        }
      }
      
      print('✓ تم بث التحديث لـ ${discoveredDevices.length} جهاز');
    } catch (e) {
      print('✗ خطأ في بث التحديث: $e');
    }
  }

  /// الحصول على قائمة الأجهزة المكتشفة
  List<NetworkDeviceInfo> getDiscoveredDevices() {
    // تصفية الأجهزة المنقطعة
    discoveredDevices.removeWhere((key, device) {
      return DateTime.now().difference(device.lastSeen).inSeconds > 60;
    });
    
    return discoveredDevices.values.toList();
  }

  /// إيقاف الخدمة
  void stop() {
    _discoveryBroadcaster?.cancel();
    _socketSubscription.cancel();
    _udpSocket.close();
    _udpBroadcaster.close();
    print('✓ تم إيقاف خدمة المزامنة المحلية');
  }
}

/// معلومات جهاز الشبكة
class NetworkDeviceInfo {
  final String deviceId;
  final String deviceName;
  final String ipAddress;
  final int port;
  DateTime lastSeen;

  NetworkDeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.ipAddress,
    required this.port,
    required this.lastSeen,
  });
}

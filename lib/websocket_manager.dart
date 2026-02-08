import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'app_state.dart';
import 'auth_service.dart';
import 'printer_service.dart';
import 'api_client.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  AppState? _appState;
  
  // ignore: constant_identifier_names
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool get isConnected => _isConnected;

  WebSocketManager._internal();

  void init(AppState appState) {
    _appState = appState;
    connect();
  }

  void connect() {
    if (_isConnected) return;

    // Use dynamic URL based on ApiClient settings
    final apiBaseUrl = ApiClient().baseUrl;
    final wsUrl = apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://') + '/ws';

    try {
      print('🔌 Connecting to WebSocket at $wsUrl...');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _handleDisconnect();
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _sendConnectMessage();
      _startPingTimer();
      _appState?.setOnlineStatus(true);
      print('✅ WebSocket connected successfully');
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _appState?.setOnlineStatus(false);
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel = null;

    // Try to reconnect in 5 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      sendMessage({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print('⚠️ Cannot send message: WebSocket not connected');
      return;
    }
    try {
      final jsonString = jsonEncode(data);
      print('📤 Sending WebSocket: ${data['type']} for ${data['deviceId'] ?? 'all'}');
      _channel!.sink.add(jsonString);
    } catch (e) {
      print('❌ Error sending WebSocket message: $e');
    }
  }

  void _sendConnectMessage() {
    sendMessage({
      'type': 'connect',
      'clientId': 'cashier-client-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      print('📩 WebSocket received: $type');

      if (_appState == null) return;

      if (type == 'error') {
        print('❌ WebSocket Server Error: ${data['message']} (Code: ${data['code']})');
        return;
      }

      switch (type) {
        case 'pong':
        case 'connected':
          // Keep alive / acknowledgement, ignore
          break;
          
        case 'device_updated':
        case 'device_update':
        case 'device_created': // Handle creation same as update
          _handleDeviceUpdate(data);
          break;
          
        case 'order_added':
        case 'order_placed':
          print('📦 Processing full order sync for ${data['deviceId']}');
          _handleOrderAdded(data);
          break;
          
        case 'order_modified':
        case 'order_updated':
          print('📝 Processing single order modification for ${data['deviceId']}');
          _handleOrderUpdated(data);
          break;
          
        case 'order_removed':
        case 'order_deleted':
          print('🗑️ Processing order removal for ${data['deviceId']}');
          _handleOrderDeleted(data);
          break;
          
        case 'device_transferred':
        case 'device_transfer':
          final fromId = data['fromDeviceId'];
          final toId = data['toDeviceId'];
          if (fromId != null && toId != null) {
            _appState!.transferDeviceDataFromSocket(fromId, toId);
          }
          break;

        case 'device_removed':
          final deviceId = data['deviceId'];
          if (deviceId != null) {
            _appState!.removeDeviceFromSocket(deviceId);
          }
          break;

        case 'device_cleared':

        case 'device_reset':
          final deviceId = data['deviceId'];
          if (deviceId != null) {
            _appState!.resetDeviceFromSocket(deviceId);
          }
          break;


        case 'print_order':
          print('🖨️ Received remote print request');
          _handleRemotePrint(data);
          break;

        case 'print_bill':
          print('🧾 Received remote bill request');
          _handleRemoteBill(data);
          break;

        // Add more handlers as strictly needed
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }

  void _handleDeviceUpdate(Map<String, dynamic> data) {
    final deviceId = data['deviceId'];
    final deviceData = data['data'];

    if (deviceId != null && deviceData != null) {
      // Direct update to AppState
      // We need to bypass the 'notifyListeners' loop that might trigger sending back to server 
      // if we were observing properly, but for now we just update state.
      // IMPLEMENTATION NOTE: We need new methods in AppState to update silently or we accept the echo? 
      // The requirement says "Server broadcasts to ALL OTHER clients". 
      // So if WE receive it, it means SOMEONE ELSE changed it. We should definitely update.
      
      _appState!.updateDeviceStatusFromSocket(
        deviceId,
        isRunning: deviceData['isRunning'] ?? false,
        time: deviceData['time'] ?? deviceData['elapsedSeconds'] ?? 0,
        mode: deviceData['mode'] ?? 'single',
        customerCount: deviceData['customerCount'] ?? 1,
        notes: deviceData['notes'] ?? '',
      );
    }
  }
  
  void _handleOrderAdded(Map<String, dynamic> data) {
    final deviceId = data['deviceId'];
    final ordersRaw = data['orders'];
    
    if (deviceId != null && ordersRaw is List) {
      try {
        final List<OrderItem> newOrders = ordersRaw
            .whereType<Map<String, dynamic>>()
            .map((o) => OrderItem.fromJson(o))
            .toList();
        // Use additive method to avoid replacing the entire list with a delta
        _appState!.addOrdersFromSocket(deviceId, newOrders);
      } catch (e) {
        print('❌ Error parsing orders from socket: $e');
      }
    }
  }

  void _handleOrderUpdated(Map<String, dynamic> data) {
     final deviceId = data['deviceId'];
     final orderIndex = data['orderIndex'];
     final orderData = data['data'];

     if (deviceId != null && orderIndex != null && orderData != null) {
       final updatedOrder = OrderItem.fromJson(orderData);
       _appState!.updateOrderFromSocket(deviceId, orderIndex, updatedOrder);
     }
  }

  void _handleOrderDeleted(Map<String, dynamic> data) {
     final deviceId = data['deviceId'];
     final orderIndex = data['orderIndex'];
     
     if (deviceId != null && orderIndex != null) {
       _appState!.removeOrderFromSocket(deviceId, orderIndex);
     }
  }
  
  Future<void> _handleRemotePrint(Map<String, dynamic> data) async {
    final authService = AuthService();
    if (!await authService.isLoggedIn()) {
      print('🚫 Ignoring remote print: Not logged in');
      return;
    }

    final username = await authService.getLoggedInUsername();
    if (username != 'super_admin') {
      print('🚫 Ignoring remote print: User "$username" is not authorized');
      return;
    }

    try {
      final List<dynamic> ordersList = data['orders'] ?? [];
      if (ordersList.isEmpty) return;

      final orders = ordersList.map((o) => OrderItem.fromJson(o)).toList();
      final tableName = data['tableName'] ?? data['deviceId'];

      // Build specific category map for this print job
      Map<String, String> itemToCategoryMap = {};
      if (_appState != null) {
        _appState!.customCategories.forEach((cat, items) {
          for (var item in items) itemToCategoryMap[item] = cat;
        });
      }

      print('🖨️ Authorized Remote Print: ${orders.length} items for $tableName');
      
      await PrinterService().printOrdersByCategory(
        orders,
        itemToCategoryMap,
        tableName: tableName,
      );
    } catch (e) {
      print('❌ Remote Print Error: $e');
    }
  }


  Future<void> _handleRemoteBill(Map<String, dynamic> data) async {
    final authService = AuthService();
    if (!await authService.isLoggedIn()) {
      print('🚫 Ignoring remote bill: Not logged in');
      return;
    }

    final username = await authService.getLoggedInUsername();
    if (username != 'super_admin') {
      print('🚫 Ignoring remote bill: User "$username" is not authorized');
      return;
    }

    try {
      final List<dynamic> ordersList = data['orders'] ?? [];
      if (ordersList.isEmpty) return;

      final orders = ordersList.map((o) => OrderItem.fromJson(o)).toList();
      final tableName = data['tableName'] ?? data['deviceId'] ?? 'Unknown';
      final title = data['title'] ?? 'فاتورة نهائية';

      print('🧾 Authorized Remote Bill: ${orders.length} items for $tableName');
      
      await PrinterService().printCashierBill(
        orders,
        tableName: tableName,
        title: title,
      );
    } catch (e) {
      print('❌ Remote Bill Error: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
  }
}

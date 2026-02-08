import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Server Discovery Service
/// Uses UDP Broadcast to allow Android devices to find the PC Server automatically
class ServerDiscoveryService {
  static final ServerDiscoveryService _instance = ServerDiscoveryService._internal();
  factory ServerDiscoveryService() => _instance;
  ServerDiscoveryService._internal();

  static const int discoveryPort = 5557;
  static const String discoveryType = 'cashier_api_discovery';

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  bool _isSearching = false;

  /// Start broadcasting the server URL (Call this on the PC/Server side)
  Future<void> startBroadcasting() async {
    if (kIsWeb) return;
    
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      
      print('🚀 Starting Server Discovery Broadcast on port $discoveryPort');
      
      _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        final serverUrl = ApiClient().baseUrl;
        // Avoid broadcasting 'localhost' as it's useless for other devices
        if (serverUrl.contains('localhost') || serverUrl.contains('127.0.0.1')) {
          final localIp = await _getLocalIp();
          if (localIp != null) {
             _sendDiscoveryPacket('http://$localIp:8080');
          }
          return;
        }
        _sendDiscoveryPacket(serverUrl);
      });
    } catch (e) {
      print('❌ Error starting discovery broadcast: $e');
    }
  }

  void _sendDiscoveryPacket(String url) {
    if (_socket == null) return;
    
    final data = jsonEncode({
      'type': discoveryType,
      'url': url,
      'name': Platform.localHostname,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    final bytes = utf8.encode(data);
    _socket!.send(bytes, InternetAddress('255.255.255.255'), discoveryPort);
  }

  /// Start searching for the server (Call this on the Android/Client side)
  Future<void> startSearching(Function(String url) onServerFound) async {
    if (_isSearching || kIsWeb) return;
    _isSearching = true;

    try {
      print('🔍 Searching for Cashier Server on the network...');
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram == null) return;
          
          try {
            final message = utf8.decode(datagram.data);
            final data = jsonDecode(message);
            
            if (data['type'] == discoveryType && data['url'] != null) {
              final foundUrl = data['url'] as String;
              print('✅ Server Found! URL: $foundUrl');
              onServerFound(foundUrl);
            }
          } catch (e) {
            // Ignore malformed packets
          }
        }
      });
    } catch (e) {
      print('❌ Error searching for server: $e');
      _isSearching = false;
    }
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4
      );
      if (interfaces.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  void stop() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _isSearching = false;
  }
}

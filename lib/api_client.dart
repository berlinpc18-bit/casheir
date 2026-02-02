import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client for communicating with the external server
/// Base URL: http://localhost:8080 (configurable)
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  
  late String baseUrl;
  late http.Client _httpClient;
  
  factory ApiClient() {
    return _instance;
  }
  
  ApiClient._internal() {
    baseUrl = 'http://192.168.0.135:8080';
    _httpClient = http.Client();
  }
  
  /// Set custom base URL (for testing or different server)
  void setBaseUrl(String url) {
    baseUrl = url;
  }
  
  /// Get all devices
  /// GET /api/devices
  Future<Map<String, dynamic>> getDevices() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/devices'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map;
        // Unwrap response wrapper { success, data, count, timestamp }
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
        return Map<String, dynamic>.from(decoded);
      } else {
        throw ApiException('Failed to get devices: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting devices: $e');
    }
  }
  
  /// Get specific device by ID
  /// GET /api/devices/{id}
  Future<Map<String, dynamic>> getDevice(String deviceId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/devices/$deviceId'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw ApiException('Device not found: $deviceId');
      } else {
        throw ApiException('Failed to get device: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting device: $e');
    }
  }
  
  /// Get orders for specific device
  /// GET /api/devices/{id}/orders
  Future<List<dynamic>> getDeviceOrders(String deviceId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/devices/$deviceId/orders'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else if (response.statusCode == 404) {
        throw ApiException('Device not found: $deviceId');
      } else {
        throw ApiException('Failed to get orders: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting orders: $e');
    }
  }
  
  /// Get all reservations
  /// GET /api/reservations
  Future<List<dynamic>> getReservations() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/reservations'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Unwrap response wrapper { success, data, count, timestamp }
        if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          return data is List ? data : [];
        }
        return decoded is List ? decoded : [];
      } else {
        throw ApiException('Failed to get reservations: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting reservations: $e');
    }
  }
  
  /// Get all prices
  /// GET /api/prices
  Future<Map<String, dynamic>> getPrices() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/prices'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map;
        // Unwrap response wrapper { success, data, count, timestamp }
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
        return Map<String, dynamic>.from(decoded);
      } else {
        throw ApiException('Failed to get prices: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting prices: $e');
    }
  }
  
  /// Get all categories
  /// GET /api/categories
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/categories'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Unwrap response wrapper { success, data, count, timestamp }
        if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          return data is List ? data : [];
        }
        return decoded is List ? decoded : [];
      } else {
        throw ApiException('Failed to get categories: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting categories: $e');
    }
  }
  
  /// Get all debts
  /// GET /api/debts
  Future<Map<String, dynamic>> getDebts() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/debts'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map;
        // Unwrap response wrapper { success, data, count, timestamp }
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
        return Map<String, dynamic>.from(decoded);
      } else {
        throw ApiException('Failed to get debts: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting debts: $e');
    }
  }
  
  /// Get today's expenses
  /// GET /api/expenses
  Future<List<dynamic>> getExpenses() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/expenses'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Unwrap response wrapper { success, data, count, timestamp }
        if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          return data is List ? data : [];
        }
        return decoded is List ? decoded : [];
      } else {
        throw ApiException('Failed to get expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error getting expenses: $e');
    }
  }
  
  /// Place a new order
  /// POST /api/order/place
  Future<Map<String, dynamic>> placeOrder({
    required String deviceId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final body = jsonEncode({
        'deviceId': deviceId,
        'items': items,
        if (notes != null) 'notes': notes,
      });
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/order/place'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw ApiException('Invalid order data: ${response.body}');
      } else if (response.statusCode == 404) {
        throw ApiException('Device not found: $deviceId');
      } else {
        throw ApiException('Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error placing order: $e');
    }
  }
  
  /// Check if server is reachable
  Future<bool> isServerAvailable() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/devices'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

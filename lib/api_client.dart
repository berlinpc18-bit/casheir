import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// API Client for communicating with the external server
/// Base URL: http://localhost:8080 (configurable)
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  
  String baseUrl = 'http://localhost:8080';
  late http.Client _httpClient;
  static const String _baseUrlKey = 'api_base_url';
  
  factory ApiClient() {
    return _instance;
  }
  
  ApiClient._internal() {
    _httpClient = http.Client();
  }

  /// Initialize and load saved URL
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_baseUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseUrl = savedUrl;
        AppLogger().info('Loaded saved API URL: $baseUrl', 'API');
      }
    } catch (e) {
      AppLogger().error('Failed to load saved API URL: $e', 'API');
    }
  }
  
  /// Set custom base URL (for testing or different server)
  Future<void> setBaseUrl(String url) async {
    AppLogger().info('Changing Base URL to: $url', 'API');
    baseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_baseUrlKey, url);
    } catch (e) {
      AppLogger().error('Failed to save API URL: $e', 'API');
    }
  }
  
  /// Get all devices
  /// GET /api/devices
  Future<Map<String, dynamic>> getDevices() async {
    return _get('/api/devices');
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
    return _get('/api/prices');
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


  /// Add a new category
  /// POST /api/categories
  Future<void> addCategory(String name) async {
    try {
      await _post('/api/categories', {'name': name});
    } catch (e) {
      throw ApiException('Error adding category: $e');
    }
  }

  /// Delete a category
  /// DELETE /api/categories/{name}
  Future<void> deleteCategory(String name) async {
    try {
      // Encode name to handle spaces
      final encodedName = Uri.encodeComponent(name);
      await _delete('/api/categories/$encodedName');
    } catch (e) {
      throw ApiException('Error deleting category: $e');
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
  
  /// Transfer device data from one device to another
  /// POST /api/devices/transfer
  Future<Map<String, dynamic>> transferDevice({
    required String fromDeviceId,
    required String toDeviceId,
  }) async {
    try {
      final body = jsonEncode({
        'fromDeviceId': fromDeviceId,
        'toDeviceId': toDeviceId,
      });
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/devices/transfer'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw ApiException('Invalid transfer request: ${response.body}');
      } else if (response.statusCode == 404) {
        throw ApiException('Source device not found: $fromDeviceId');
      } else {
        throw ApiException('Failed to transfer device: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error transferring device: $e');
    }
  }
  
  /// Check if server is reachable
  Future<bool> isServerAvailable() async {
    AppLogger().info('Testing connection to: $baseUrl...', 'API');
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/devices'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode < 500) {
        AppLogger().info('✓ Connection successful! (Status: ${response.statusCode})', 'API');
        return true;
      } else {
        AppLogger().warning('Connection returned error status: ${response.statusCode}', 'API');
        return false;
      }
    } catch (e) {
      AppLogger().error('Connection failed: $e', 'API');
      return false;
    }
  }
  /// Update device status
  /// POST /api/devices/update
  Future<Map<String, dynamic>> updateDeviceStatus({
    required String deviceId,
    required bool isRunning,
    required int elapsedSeconds,
    required String mode,
    required int customerCount,
    String? notes,
  }) async {
    try {
      final body = jsonEncode({
        'deviceId': deviceId,
        'isRunning': isRunning,
        'elapsedSeconds': elapsedSeconds,
        'mode': mode,
        'customerCount': customerCount,
        if (notes != null) 'notes': notes,
        'startTime': DateTime.now().toIso8601String(), // Optional, but good for validation
      });
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/devices/update'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10)); // Shorter timeout for updates
      
      if (response.statusCode == 200 || response.statusCode == 201) {
         final decoded = jsonDecode(response.body);
         return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        throw ApiException('Failed to update device status: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error updating device status: $e');
    }
  }

  /// Sync device orders (Full Sync)
  /// POST /api/devices/orders/sync
  Future<Map<String, dynamic>> syncDeviceOrders({
    required String deviceId,
    required List<Map<String, dynamic>> orders,
  }) async {
    try {
      final body = jsonEncode({
        'deviceId': deviceId,
        'orders': orders,
      });
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/devices/orders/sync'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        throw ApiException('Failed to sync orders: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error syncing orders: $e');
    }
  }
  // --- New Endpoints Implementation matching SERVER_ENDPOINTS_SPEC.md ---

  /// Get global settings and prices
  /// GET /api/settings
  Future<Map<String, dynamic>> getSettings() async {
    return _get('/api/settings');
  }

  /// Update prices
  /// PUT /api/settings/prices
  Future<void> updatePrices(Map<String, dynamic> prices) async {
    await _put('/api/settings/prices', prices);
  }

  /// Get printer settings
  /// GET /api/settings/printers
  Future<Map<String, dynamic>> getPrinters() async {
    return _get('/api/settings/printers');
  }

  /// Update printer settings
  /// PUT /api/settings/printers
  Future<void> updatePrinters(Map<String, dynamic> settings) async {
    await _put('/api/settings/printers', settings);
  }

  /// Get all products (Menu)
  /// GET /api/products
  /// Get all products and categories hierarchy
  /// GET /api/products
  Future<Map<String, dynamic>> getProducts() async {
    return _get('/api/products');
  }

  /// Add a new product
  /// POST /api/products
  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _post('/api/products', productData);
  }

  /// Update a product
  /// PUT /api/products/{id}
  Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
    await _put('/api/products/$id', productData);
  }

  /// Delete a product
  /// DELETE /api/products/{id}
  Future<void> deleteProduct(String id) async {
    await _delete('/api/products/$id');
  }

  /// Add a new device
  /// POST /api/devices
  Future<void> addDevice(Map<String, dynamic> deviceData) async {
    await _post('/api/devices', deviceData);
  }

  /// Delete a device
  /// DELETE /api/devices/{id}
  Future<void> deleteDevice(String id) async {
    await _delete('/api/devices/$id');
  }

  /// Add an expense
  /// POST /api/financials/expenses
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    await _post('/api/financials/expenses', expenseData);
  }

  /// Add a new debt
  /// POST /api/debts
  Future<void> addDebt(Map<String, dynamic> debtData) async {
    await _post('/api/debts', debtData);
  }

  /// Update/Settle a debt
  /// PUT /api/debts/{id}
  Future<void> updateDebt(String id, Map<String, dynamic> debtData) async {
    await _put('/api/debts/$id', debtData);
  }

  // --- Helper Methods ---

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await _httpClient.get(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('GET $endpoint failed: $e');
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final String fullUrl;
      if (endpoint.startsWith('/') && baseUrl.endsWith('/')) {
        fullUrl = baseUrl + endpoint.substring(1);
      } else if (!endpoint.startsWith('/') && !baseUrl.endsWith('/')) {
        fullUrl = '$baseUrl/$endpoint';
      } else {
        fullUrl = '$baseUrl$endpoint';
      }
      
      final response = await _httpClient.post(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('POST $endpoint failed: $e');
    }
  }

  Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final String fullUrl;
      if (endpoint.startsWith('/') && baseUrl.endsWith('/')) {
        fullUrl = baseUrl + endpoint.substring(1);
      } else if (!endpoint.startsWith('/') && !baseUrl.endsWith('/')) {
        fullUrl = '$baseUrl/$endpoint';
      } else {
        fullUrl = '$baseUrl$endpoint';
      }

      final response = await _httpClient.put(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('PUT $endpoint failed: $e');
    }
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await _httpClient.delete(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('DELETE $endpoint failed: $e');
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      
      if (decoded is Map<String, dynamic>) {
        // Automatically unwrap { success: true, data: { ... } } if present
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
        return decoded;
      }
      return {'data': decoded};
    } else {
      throw ApiException('Request failed with status: ${response.statusCode}');
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

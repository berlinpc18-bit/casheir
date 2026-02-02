import 'api_client.dart';
import 'app_state.dart';

/// API Sync Manager - Handles syncing AppState with external API server
/// This allows AppState to fetch data from the API instead of (or alongside) Hive
class ApiSyncManager {
  static final ApiSyncManager _instance = ApiSyncManager._internal();
  
  late ApiClient _apiClient;
  bool _useApi = true; // Enable/disable API usage
  
  factory ApiSyncManager() {
    return _instance;
  }
  
  ApiSyncManager._internal() {
    _apiClient = ApiClient();
  }
  
  /// Enable or disable API usage
  void setApiEnabled(bool enabled) {
    _useApi = enabled;
  }
  
  /// Get current API enabled status
  bool get isApiEnabled => _useApi;
  
  /// Get API client
  ApiClient get apiClient => _apiClient;
  
  /// Sync all devices from API ONLY (no Hive fallback)
  Future<void> syncDevices(AppState appState) async {
    if (!_useApi) return;
    
    try {
      final response = await _apiClient.getDevices();
      
      // Clear all old devices - trust ONLY the API response
      appState.devices.clear();
      
      // Response is already unwrapped by API client
      if (response is Map && response.isNotEmpty) {
        for (var entry in response.entries) {
          final deviceId = entry.key;
          final deviceData = entry.value;
          
          if (deviceData is Map<String, dynamic>) {
            appState.updateDeviceFromApi(deviceId, deviceData);
            
            // Also fetch orders for this device
            try {
              final orders = await _apiClient.getDeviceOrders(deviceId);
              appState.updateDeviceOrdersFromApi(deviceId, orders);
              print('  ✅ Synced orders for $deviceId');
            } catch (e) {
              print('  ⚠️ Could not sync orders for $deviceId: $e');
            }
          }
        }
        print('✅ Synced ${response.length} devices from SERVER');
      } else {
        print('⚠️ SERVER has no devices');
      }
      appState.notifyListeners();
    } catch (e) {
      print('❌ Error syncing devices from SERVER: $e');
      rethrow;
    }
  }
  
  /// Sync specific device from API
  Future<void> syncDevice(AppState appState, String deviceId) async {
    if (!_useApi) return;
    
    try {
      final response = await _apiClient.getDevice(deviceId);
      appState.updateDeviceFromApi(deviceId, response);
      print('✅ Synced device $deviceId from API');
    } catch (e) {
      print('❌ Error syncing device $deviceId: $e');
    }
  }
  
  /// Sync device orders from API
  Future<void> syncDeviceOrders(AppState appState, String deviceId) async {
    if (!_useApi) return;
    
    try {
      final orders = await _apiClient.getDeviceOrders(deviceId);
      appState.updateDeviceOrdersFromApi(deviceId, orders);
      print('✅ Synced orders for $deviceId from API');
    } catch (e) {
      print('❌ Error syncing orders for $deviceId: $e');
    }
  }
  
  /// Sync reservations from API ONLY (no Hive fallback)
  Future<void> syncReservations(AppState appState) async {
    if (!_useApi) return;
    
    try {
      final reservations = await _apiClient.getReservations();
      appState.reservations.clear();
      appState.updateReservationsFromApi(reservations);
      print('✅ Synced reservations from SERVER');
      appState.notifyListeners();
    } catch (e) {
      print('❌ Error syncing reservations from SERVER: $e');
      rethrow; // No Hive fallback
    }
  }
  
  /// Sync prices from API ONLY (no Hive fallback)
  Future<void> syncPrices(AppState appState) async {
    if (!_useApi) return;
    
    try {
      final response = await _apiClient.getPrices();
      appState.updatePricesFromApi(response);
      print('✅ Synced prices from SERVER');
      appState.notifyListeners();
    } catch (e) {
      print('❌ Error syncing prices from SERVER: $e');
      rethrow;
    }
  }
  
  /// Sync categories from API ONLY (no Hive fallback)
  Future<void> syncCategories(AppState appState) async {
    if (!_useApi) return;
    
    try {
      final categories = await _apiClient.getCategories();
      appState.updateCategoriesFromApi(categories);
      print('✅ Synced categories from SERVER');
      appState.notifyListeners();
    } catch (e) {
      print('❌ Error syncing categories from SERVER: $e');
      rethrow; // No Hive fallback
    }
  }
  
  /// Sync debts from API ONLY (no Hive fallback)
  Future<void> syncDebts(AppState appState) async {
    if (!_useApi) return;
    
    try {
      final response = await _apiClient.getDebts();
      appState.updateDebtsFromApi(response);
      print('✅ Synced debts from SERVER');
      appState.notifyListeners();
    } catch (e) {
      print('❌ Error syncing debts from SERVER: $e');
      rethrow; // No Hive fallback
    }
  }
  
  /// Sync expenses from API ONLY (no Hive fallback)
  Future<void> syncExpenses(AppState appState) async {
    if (!_useApi) return;
    
    try {
      final expenses = await _apiClient.getExpenses();
      appState.updateExpensesFromApi(expenses);
      print('✅ Synced expenses from SERVER');
      appState.notifyListeners();
    } catch (e) {
      print('❌ Error syncing expenses from SERVER: $e');
      rethrow; // No Hive fallback
    }
  }
  
  /// Place order via API
  Future<Map<String, dynamic>> placeOrderViaApi(
    String deviceId,
    List<Map<String, dynamic>> items, {
    String? notes,
  }) async {
    if (!_useApi) {
      throw ApiException('API is disabled');
    }
    
    try {
      final response = await _apiClient.placeOrder(
        deviceId: deviceId,
        items: items,
        notes: notes,
      );
      print('✅ Order placed via API for $deviceId');
      return response;
    } catch (e) {
      print('❌ Error placing order via API: $e');
      rethrow;
    }
  }
  
  /// Sync all data from API (full refresh)
  Future<void> syncAll(AppState appState) async {
    if (!_useApi) return;
    
    try {
      await Future.wait([
        syncDevices(appState),
        syncReservations(appState),
        syncPrices(appState),
        syncCategories(appState),
        syncDebts(appState),
        syncExpenses(appState),
      ]);
      print('✅ Full sync from API completed');
    } catch (e) {
      print('❌ Error during full sync: $e');
    }
  }
  
  /// Update device status on server
  Future<void> updateDeviceStatus(
    String deviceId, {
    required bool isRunning,
    required int elapsedSeconds,
    required String mode,
    required int customerCount,
    String? notes,
  }) async {
    if (!_useApi) return;
    
    try {
      await _apiClient.updateDeviceStatus(
        deviceId: deviceId,
        isRunning: isRunning,
        elapsedSeconds: elapsedSeconds,
        mode: mode,
        customerCount: customerCount,
        notes: notes,
      );
      // print('✅ Device updated on server: $deviceId'); // Commented to reduce noise
    } catch (e) {
      print('❌ Error updating device on server: $e');
      // Don't rethrow to avoid breaking UI for offline usage
    }
  }

  /// Sync device orders to server (Full Sync)
  Future<void> syncOrdersToApi(String deviceId, List<Map<String, dynamic>> orders) async {
    if (!_useApi) return;
    
    try {
      await _apiClient.syncDeviceOrders(
        deviceId: deviceId,
        orders: orders,
      );
      print('✅ Orders synced to server for: $deviceId');
    } catch (e) {
      print('❌ Error syncing orders to server: $e');
    }
  }

  /// Transfer device data from one device to another on server
  Future<void> transferDeviceViaApi(String fromDeviceId, String toDeviceId) async {
    if (!_useApi) return;
    
    try {
      final result = await _apiClient.transferDevice(
        fromDeviceId: fromDeviceId,
        toDeviceId: toDeviceId,
      );
      print('✅ Device transferred on server: ${result['message']}');
    } catch (e) {
      print('❌ Error transferring device on server: $e');
      rethrow; // Rethrow to let caller handle the error
    }
  }

  /// Check if API server is available
  Future<bool> isServerAvailable() async {
    return await _apiClient.isServerAvailable();
  }
}

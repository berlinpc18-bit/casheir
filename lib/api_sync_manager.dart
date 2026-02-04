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
      print('');
      print('═══════════════════════════════════════════════════');
      print('🔄 SYNCING DEVICES FROM SERVER...');
      print('═══════════════════════════════════════════════════');
      
      final response = await _apiClient.getDevices();
      
      // Merge server devices with local devices (don't clear - preserve transferred devices)
      
      // Response is already unwrapped by API client
      if (response is Map && response.isNotEmpty) {
        print('📥 Server returned ${response.length} devices: ${response.keys.join(", ")}');
        
        for (var entry in response.entries) {
          final deviceId = entry.key;
          final deviceData = entry.value;
          
          if (deviceData is Map<String, dynamic>) {
            print('   ⬇️ Syncing device: $deviceId');
            appState.updateDeviceFromApi(deviceId, deviceData);
            
            // Also fetch orders for this device
            // Also fetch orders for this device
            try {
              final orders = await _apiClient.getDeviceOrders(deviceId);
              // Use device Name for local update (because AppState uses Name as Key)
              final deviceName = deviceData['name'] ?? deviceId;
              appState.updateDeviceOrdersFromApi(deviceName, orders);
              print('      ✅ Synced orders for $deviceName (ID: $deviceId)');
            } catch (e) {
              print('      ⚠️ Could not sync orders for $deviceId: $e');
            }
          }
        }
        print('✅ Synced ${response.length} devices from SERVER (merged with local)');
      } else {
        print('⚠️ SERVER has no devices');
      }
      
      // Always check for devices to remove (even if server is empty)
      final serverDeviceIds = response is Map ? response.keys.toSet() : <String>{};
      final localDeviceIds = appState.devices.keys.toList();
      
      print('🔍 Checking for devices to remove...');
      print('   Server has: ${serverDeviceIds.isEmpty ? "NONE" : serverDeviceIds.join(", ")}');
      print('   Local has: ${localDeviceIds.join(", ")}');
      
      for (var localId in localDeviceIds) {
        if (!serverDeviceIds.contains(localId)) {
          final device = appState.devices[localId]!;
          print('   📋 Device $localId not on server:');
          print('      - Orders: ${device.orders.length}');
          print('      - Running: ${device.isRunning}');
          print('      - Elapsed: ${device.elapsedTime.inSeconds}s');
          
          // Remove ALL devices not on server (server is source of truth)
          print('   🗑️ Removing device $localId (deleted on server)');
          appState.removeDeviceFromSocket(localId);
        }
      }
      
      print('');
      print('📊 SYNC COMPLETE - Final device count: ${appState.devices.length}');
      print('   Devices in app: ${appState.devices.keys.join(", ")}');
      print('');
      
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
  Future<void> syncDeviceOrders(AppState appState, String deviceId, {String? deviceName}) async {
    if (!_useApi) return;
    
    try {
      final orders = await _apiClient.getDeviceOrders(deviceId);
      // If name not provided, we might have an issue if deviceId differs from name.
      // But usually this is called with deviceId matching local key if using Name as ID on server?
      // Or we can lookup name from appState if we have the ID mapping?
      // For now, assume deviceName is passed or deviceId is used (if server uses names as IDs)
      appState.updateDeviceOrdersFromApi(deviceName ?? deviceId, orders);
      print('✅ Synced orders for ${deviceName ?? deviceId} from API');
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
    } on ApiException catch (e) {
      // Silently ignore 404 errors (device was deleted/transferred)
      if (e.message.contains('404') || e.message.contains('not found')) {
        print('ℹ️ Device $deviceId not found on server (may have been transferred/deleted)');
        return;
      }
      print('❌ Error updating device on server: $e');
      // Don't rethrow to avoid breaking UI for offline usage
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

  /// --- Settings & Management Sync Methods ---

  /// Update prices on server
  Future<void> updatePricesOnServer(Map<String, dynamic> prices) async {
    if (!_useApi) return;
    try {
      await _apiClient.updatePrices(prices);
      print('✅ Prices updated on server');
    } catch (e) {
      print('❌ Error updating prices on server: $e');
      rethrow;
    }
  }

  /// Update printer settings on server
  Future<void> updatePrintersOnServer(Map<String, dynamic> settings) async {
    if (!_useApi) return;
    try {
      await _apiClient.updatePrinters(settings);
      print('✅ Printer settings updated on server');
    } catch (e) {
      print('❌ Error updating printer settings on server: $e');
      rethrow;
    }
  }

  /// Add product to server
  Future<void> addProductToServer(Map<String, dynamic> productData) async {
    if (!_useApi) return;
    try {
      await _apiClient.addProduct(productData);
      print('✅ Product added to server');
    } catch (e) {
      print('❌ Error adding product to server: $e');
      rethrow;
    }
  }

  /// Update product on server
  Future<void> updateProductOnServer(String id, Map<String, dynamic> productData) async {
    if (!_useApi) return;
    try {
      await _apiClient.updateProduct(id, productData);
      print('✅ Product updated on server');
    } catch (e) {
      print('❌ Error updating product on server: $e');
      rethrow;
    }
  }

  /// Delete product from server
  Future<void> deleteProductFromServer(String id) async {
    if (!_useApi) return;
    try {
      await _apiClient.deleteProduct(id);
      print('✅ Product deleted from server');
    } catch (e) {
      print('❌ Error deleting product from server: $e');
      rethrow;
    }
  }

  /// Add device to server
  Future<void> addDeviceToServer(Map<String, dynamic> deviceData) async {
    if (!_useApi) return;
    try {
      await _apiClient.addDevice(deviceData);
      print('✅ Device added to server');
    } catch (e) {
      print('❌ Error adding device to server: $e');
      rethrow;
    }
  }

  /// Delete device from server
  Future<void> deleteDeviceFromServer(String id) async {
    if (!_useApi) return;
    try {
      await _apiClient.deleteDevice(id);
      print('✅ Device deleted from server');
    } catch (e) {
      print('❌ Error deleting device from server: $e');
      rethrow;
    }
  }

  /// Add expense to server
  Future<void> addExpenseToServer(Map<String, dynamic> expenseData) async {
    if (!_useApi) return;
    try {
      await _apiClient.addExpense(expenseData);
      print('✅ Expense added to server');
    } catch (e) {
      print('❌ Error adding expense to server: $e');
      rethrow;
    }
  }

  /// Add debt to server
  Future<void> addDebtToServer(Map<String, dynamic> debtData) async {
    if (!_useApi) return;
    try {
      await _apiClient.addDebt(debtData);
      print('✅ Debt added to server');
    } catch (e) {
      print('❌ Error adding debt to server: $e');
      rethrow;
    }
  }

  /// Update debt on server
  Future<void> updateDebtOnServer(String id, Map<String, dynamic> debtData) async {
    if (!_useApi) return;
    try {
      await _apiClient.updateDebt(id, debtData);
      print('✅ Debt updated on server');
    } catch (e) {
      print('❌ Error updating debt on server: $e');
      rethrow;
    }
  }

  /// Check if API server is available
  Future<bool> isServerAvailable() async {
    return await _apiClient.isServerAvailable();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'api_sync_manager.dart';

/// API Integration Guide and Examples
/// This file shows how to integrate API calls into your screens

class ApiIntegrationExample {
  /// Example 1: Load all devices when opening device management screen
  static Future<void> loadAllDevicesExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncDevices(appState);
      // Devices are now updated in appState
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading devices: $e')),
      );
    }
  }

  /// Example 2: Load device orders when opening device details
  static Future<void> loadDeviceOrdersExample(
    BuildContext context,
    String deviceId,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncDeviceOrders(appState, deviceId);
      // Orders are now updated in appState for this device
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  /// Example 3: Load reservations when opening reservations screen
  static Future<void> loadReservationsExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncReservations(appState);
      // Reservations are now updated in appState
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reservations: $e')),
      );
    }
  }

  /// Example 4: Load prices when opening prices settings
  static Future<void> loadPricesExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncPrices(appState);
      // Prices are now updated in appState
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading prices: $e')),
      );
    }
  }

  /// Example 5: Load categories when opening categories screen
  static Future<void> loadCategoriesExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncCategories(appState);
      // Categories are now updated in appState
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  /// Example 6: Load debts when opening debts screen
  static Future<void> loadDebtsExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncDebts(appState);
      // Debts are now updated in appState
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading debts: $e')),
      );
    }
  }

  /// Example 7: Load expenses when opening expenses screen
  static Future<void> loadExpensesExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      await apiSync.syncExpenses(appState);
      // Expenses are now updated in appState
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading expenses: $e')),
      );
    }
  }

  /// Example 8: Place order via API
  static Future<void> placeOrderViaApiExample(
    BuildContext context, {
    required String deviceId,
    required List<Map<String, dynamic>> orderItems,
    String? notes,
  }) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Place order via API
      final response = await apiSync.placeOrderViaApi(
        deviceId,
        orderItems,
        notes: notes,
      );
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      
      // Sync device orders to get the latest list
      await apiSync.syncDeviceOrders(appState, deviceId);
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  /// Example 9: Full sync on app startup
  static Future<void> fullSyncOnStartupExample(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final apiSync = ApiSyncManager();
    
    // Check if server is available before attempting sync
    final isAvailable = await apiSync.isServerAvailable();
    
    if (isAvailable) {
      try {
        // Sync all data at once
        await apiSync.syncAll(appState);
        print('✅ Full sync completed on startup');
      } catch (e) {
        print('⚠️ Full sync failed: $e');
      }
    } else {
      print('⚠️ API server not available, using local data');
    }
  }
}

// ============= Actual Implementation Guide =============
// 
// 1. ADD TO main.dart in initState/build:
//    - Call ApiIntegrationExample.fullSyncOnStartupExample(context)
//    - This will load all data from API on startup
//
// 2. UPDATE device_management_screen.dart:
//    - Add to initState: ApiIntegrationExample.loadAllDevicesExample(context)
//    - This will load devices from GET /api/devices
//
// 3. UPDATE order_dialog.dart or order placement code:
//    - Replace appState.addOrder() calls with:
//      await ApiIntegrationExample.placeOrderViaApiExample(
//        context,
//        deviceId: deviceId,
//        orderItems: items,
//        notes: notes,
//      )
//    - This will use POST /api/order/place endpoint
//
// 4. UPDATE debts_screen.dart:
//    - Add to initState: ApiIntegrationExample.loadDebtsExample(context)
//    - This will load debts from GET /api/debts
//
// 5. UPDATE prices_settings_screen.dart:
//    - Add to initState: ApiIntegrationExample.loadPricesExample(context)
//    - This will load prices from GET /api/prices
//
// 6. UPDATE reservation screens:
//    - Add to initState: ApiIntegrationExample.loadReservationsExample(context)
//    - This will load reservations from GET /api/reservations
//
// 7. UPDATE category screens:
//    - Add to initState: ApiIntegrationExample.loadCategoriesExample(context)
//    - This will load categories from GET /api/categories
//
// 8. UPDATE expense screens:
//    - Add to initState: ApiIntegrationExample.loadExpensesExample(context)
//    - This will load expenses from GET /api/expenses
//
// 9. OPTIONAL - Enable/Disable API usage:
//    - ApiSyncManager().setApiEnabled(true/false)
//    - This allows you to toggle between API and local data

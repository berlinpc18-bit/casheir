# API Integration Implementation Map

## Summary
The server is ready with 9 endpoints. This document maps each screen/file to the API endpoints it should call.

## Endpoint Summary
```
1. GET /api/devices             → Returns all devices
2. GET /api/devices/{id}        → Returns specific device
3. GET /api/devices/{id}/orders → Returns device orders
4. GET /api/reservations        → Returns all reservations
5. GET /api/prices              → Returns all prices
6. GET /api/categories          → Returns all categories
7. GET /api/debts               → Returns all debts
8. GET /api/expenses            → Returns today's expenses
9. POST /api/order/place        → Creates new order
```

---

## Files to Modify - Implementation Guide

### 1. **lib/main.dart** - Sync all data on app startup
```
Location: AppState initialization in main() or home screen initState
Current: Loads from Hive only
Change: Add full API sync on startup
Call: ApiIntegrationExample.fullSyncOnStartupExample(context)
Endpoints: Uses all endpoints (1, 4, 5, 6, 7, 8)
```

### 2. **lib/device_management_screen.dart** - Display/manage devices
```
Location: _DeviceManagementScreenState initState or build
Current: appState.devices from Hive
Change: Sync devices from API before displaying
Call: ApiIntegrationExample.loadAllDevicesExample(context)
Endpoint: GET /api/devices (Endpoint 1)
```

### 3. **lib/order_dialog.dart** - Place orders
```
Location: When user submits order form
Current: appState.addOrder(deviceId, items)
Change: Send order to API instead
Call: ApiIntegrationExample.placeOrderViaApiExample(context, deviceId, items)
Endpoint: POST /api/order/place (Endpoint 9)
```

### 4. **lib/debts_screen.dart** - Display debts
```
Location: _DebtsScreenState initState
Current: appState.debts from Hive
Change: Fetch debts from API
Call: ApiIntegrationExample.loadDebtsExample(context)
Endpoint: GET /api/debts (Endpoint 7)
```

### 5. **lib/prices_settings_screen.dart** - Display/manage prices
```
Location: _PricesSettingsScreenState initState
Current: appState prices from Hive
Change: Fetch prices from API
Call: ApiIntegrationExample.loadPricesExample(context)
Endpoint: GET /api/prices (Endpoint 5)
```

### 6. **lib/reservations_screen.dart** - Display reservations (if exists)
```
Location: Screen initState
Current: appState.reservations from Hive
Change: Fetch from API
Call: ApiIntegrationExample.loadReservationsExample(context)
Endpoint: GET /api/reservations (Endpoint 4)
```

### 7. **lib/custom_category_screen.dart** - Display categories
```
Location: Screen initState
Current: appState.customCategories from Hive
Change: Fetch from API
Call: ApiIntegrationExample.loadCategoriesExample(context)
Endpoint: GET /api/categories (Endpoint 6)
```

### 8. **lib/device_grid.dart or device card widget** - Display single device
```
Location: When displaying device details
Current: appState.devices[deviceId]
Change: Fetch specific device from API
Call: ApiIntegrationExample.loadDeviceOrdersExample(context, deviceId)
Endpoint: GET /api/devices/{id}/orders (Endpoint 3)
```

### 9. **lib/order_details.dart** - Show order details with device info
```
Location: Screen initState
Current: Gets device from appState
Change: Sync device orders from API
Call: ApiIntegrationExample.loadDeviceOrdersExample(context, deviceId)
Endpoint: GET /api/devices/{id}/orders (Endpoint 3)
```

### 10. **Optional: lib/app_state.dart - Add API sync initialization**
```
Location: AppState constructor or _loadFromPrefs()
Current: Loads from Hive only
Change: Add optional API initialization
Code: 
  if (await ApiSyncManager().isServerAvailable()) {
    await ApiSyncManager().syncAll(this);
  }
```

---

## Code Changes Template

### For each screen, add to initState():

```dart
@override
void initState() {
  super.initState();
  _loadDataFromApi();
}

Future<void> _loadDataFromApi() async {
  final appState = Provider.of<AppState>(context, listen: false);
  final apiSync = ApiSyncManager();
  
  try {
    // Call appropriate sync method
    // Example for devices:
    await apiSync.syncDevices(appState);
  } catch (e) {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### For order placement, replace direct Hive calls:

```dart
// OLD CODE:
appState.addOrder(deviceId, orderItem);

// NEW CODE:
try {
  await ApiSyncManager().placeOrderViaApi(
    deviceId,
    [orderItem.toJson()],
    notes: notes,
  );
  // Refresh device orders
  await ApiSyncManager().syncDeviceOrders(appState, deviceId);
} catch (e) {
  // Show error
}
```

---

## Files Created (Already Done)

✅ **lib/api_client.dart** - HTTP client for all 9 endpoints
✅ **lib/api_sync_manager.dart** - Sync manager for AppState updates
✅ **lib/api_integration_examples.dart** - Examples and implementation guide
✅ **lib/app_state.dart updated** - Added 8 methods to receive API data:
  - updateDeviceFromApi()
  - updateDeviceOrdersFromApi()
  - updateReservationsFromApi()
  - updatePricesFromApi()
  - updateCategoriesFromApi()
  - updateDebtsFromApi()
  - updateExpensesFromApi()

---

## Implementation Checklist

Files to modify (can be done progressively):

- [ ] lib/main.dart - Add startup sync
- [ ] lib/device_management_screen.dart - Load devices from API
- [ ] lib/order_dialog.dart - Place orders via API
- [ ] lib/debts_screen.dart - Load debts from API
- [ ] lib/prices_settings_screen.dart - Load prices from API
- [ ] lib/reservations_screen.dart - Load reservations from API
- [ ] lib/custom_category_screen.dart - Load categories from API
- [ ] lib/device_grid.dart - Load device orders from API
- [ ] lib/order_details.dart - Load order details from API

---

## Testing

1. **Start the API server** on http://localhost:8080
2. **Run the Flutter app**
3. **Check console logs** for ✅ sync messages
4. **Test each screen** to verify API calls are working
5. **Disable API** to test fallback to Hive:
   ```dart
   ApiSyncManager().setApiEnabled(false);
   ```

---

## API Base URL Configuration

Default: `http://localhost:8080`

To change:
```dart
ApiClient().setBaseUrl('http://your-server:port');
```

Or in main.dart:
```dart
void main() {
  ApiClient().setBaseUrl('http://192.168.1.100:8080');
  runApp(const MyApp());
}
```

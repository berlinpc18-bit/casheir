# External App Integration Guide - Files to Modify/Create

This document lists all files that need to be changed or created to allow an external app to connect to the Berlin Gaming Cashier device and place orders.

---

## Overview

The external app will communicate with the main cashier device via:
- **Local Network (LAN)** - using UDP/TCP sockets
- **Server** - via HTTP/WebSocket (you'll add this)
- **Direct device connection** - via the existing sync system

---

## Files to Modify in Main Cashier App

### 1. **`lib/app_state.dart`** ⭐ PRIORITY: HIGH
**Why:** Contains core data models (OrderItem, DeviceData)
**What to modify:**
- Add `toJson()` and `fromJson()` methods to all data classes for serialization
- Add methods to accept orders from external apps:
  ```dart
  void addOrderFromExternalApp(String deviceName, List<OrderItem> orders, Map<String, dynamic> metadata)
  void updateDeviceFromExternalApp(String deviceId, Map<String, dynamic> deviceData)
  ```
- Add event stream to notify about external order changes:
  ```dart
  Stream<OrderEvent> get externalOrderStream
  ```

**Key Classes:**
- `OrderItem` - order details
- `ReservationItem` - reservations
- `DeviceData` - device state
- `AppState` - main state manager

---

### 2. **`lib/local_network_sync_service.dart`** ⭐ PRIORITY: HIGH
**Why:** Handles network communication
**What to modify:**
- Add TCP server socket (in addition to UDP) for orders:
  ```dart
  late ServerSocket _orderServer;
  Future<void> startOrderServer(int port) async { ... }
  ```
- Add handlers for order messages:
  ```dart
  void _handleOrderMessage(Socket socket, Map<String, dynamic> data) { ... }
  ```
- Add endpoint for external apps to query device status:
  ```dart
  Future<Map<String, dynamic>> getDeviceStatus(String deviceId) async { ... }
  ```
- Export device price list and categories:
  ```dart
  Future<Map<String, dynamic>> getPriceList() async { ... }
  ```

**Methods to add:**
- `sendOrderToDevice(String deviceId, List<OrderItem> orders)`
- `broadcastDeviceUpdate(Map<String, dynamic> update)`
- `validateExternalApp(String appToken)`

---

### 3. **`lib/sync_service.dart`** - PRIORITY: MEDIUM
**Why:** Core synchronization logic
**What to modify:**
- Add method to accept orders from remote devices:
  ```dart
  void receiveExternalOrder(String sourceAppId, List<OrderItem> orders) { ... }
  ```
- Add authentication/validation for external apps:
  ```dart
  bool validateExternalAppToken(String token) { ... }
  Future<String> generateExternalAppToken() async { ... }
  ```
- Add logging for external orders (for security audit):
  ```dart
  void logExternalOrderAccess(String appId, String action) { ... }
  ```

---

### 4. **`lib/license_manager.dart`** - PRIORITY: MEDIUM
**Why:** License validation
**What to modify:**
- Add license check for external app connections:
  ```dart
  bool canAcceptExternalOrders() { ... }
  int getMaxExternalAppsAllowed() { ... }
  ```
- Store external app IDs tied to license

---

### 5. **`lib/device_group_manager.dart`** - PRIORITY: LOW
**Why:** Multi-device management
**What to modify:**
- Add method to handle orders from external apps for grouped devices:
  ```dart
  void distributeExternalOrderToGroup(String groupId, List<OrderItem> orders) { ... }
  ```

---

### 6. **`lib/order_dialog.dart`** - PRIORITY: MEDIUM
**Why:** Order creation/display
**What to modify:**
- Add visual indicator for orders from external app (badge/tag):
  ```dart
  Widget _buildExternalOrderBadge(String source) { ... }
  ```
- Add method to populate dialog from external order:
  ```dart
  void populateFromExternalOrder(List<OrderItem> items) { ... }
  ```

---

### 7. **`lib/data_persistence_manager.dart`** - PRIORITY: LOW
**Why:** Data storage
**What to modify:**
- Add tracking for external orders separately:
  ```dart
  Future<void> saveExternalOrderLog(Map<String, dynamic> orderData) async { ... }
  Future<List<Map>> getExternalOrderHistory() async { ... }
  ```

---

### 8. **`lib/printer_service.dart`** - PRIORITY: MEDIUM
**Why:** Order printing
**What to modify:**
- Add method to print orders from external apps with source info:
  ```dart
  Future<void> printExternalOrder(List<OrderItem> orders, String source) async { ... }
  ```

---

### 9. **`lib/main.dart`** - PRIORITY: HIGH
**Why:** App initialization
**What to modify:**
- Initialize external order server on app startup:
  ```dart
  // In main() or after app initialization
  await _initializeExternalOrderServer();
  ```
- Add configuration for listening port
- Add UI option to enable/disable external orders

---

## Files to Create (New)

### 1. **`lib/external_order_server.dart`** ⭐ CREATE NEW
**Purpose:** Dedicated server for external app connections
**Should contain:**
```dart
class ExternalOrderServer {
  ServerSocket? _server;
  
  Future<void> startServer(int port) async { ... }
  Future<void> stopServer() async { ... }
  
  // Handle incoming order from external app
  void _handleIncomingOrder(Socket socket, Map<String, dynamic> data) { ... }
  
  // Validate external app identity
  bool _validateExternalApp(String appToken) { ... }
  
  // Send response to external app
  Future<void> _sendResponse(Socket socket, Map<String, dynamic> response) async { ... }
}
```

---

### 2. **`lib/external_app_api.dart`** ⭐ CREATE NEW
**Purpose:** API definition for external apps to use
**Should contain:**
```dart
class ExternalAppAPI {
  static const String VERSION = '1.0.0';
  
  // API Endpoints
  static const String ENDPOINT_PLACE_ORDER = '/api/order/place';
  static const String ENDPOINT_GET_DEVICE = '/api/device/status';
  static const String ENDPOINT_GET_PRICES = '/api/prices/list';
  static const String ENDPOINT_AUTHENTICATE = '/api/auth/token';
  
  // Request models
  class PlaceOrderRequest {
    String deviceId;
    List<OrderItem> items;
    Map<String, dynamic>? metadata;
  }
  
  // Response models
  class APIResponse {
    bool success;
    dynamic data;
    String? error;
  }
}
```

---

### 3. **`lib/external_order_models.dart`** ⭐ CREATE NEW
**Purpose:** Data models for external app communication
**Should contain:**
```dart
class ExternalOrderRequest {
  String deviceId;
  String? appToken;
  List<OrderItem> items;
  String? notes;
  Map<String, dynamic>? metadata;
  
  Map<String, dynamic> toJson() { ... }
  factory ExternalOrderRequest.fromJson(Map<String, dynamic> json) { ... }
}

class DeviceStatusResponse {
  String deviceId;
  String deviceName;
  bool isRunning;
  Duration elapsedTime;
  List<String> availableItems;
  Map<String, double> prices;
  DateTime statusTime;
  
  Map<String, dynamic> toJson() { ... }
  factory DeviceStatusResponse.fromJson(Map<String, dynamic> json) { ... }
}

class ExternalOrderResponse {
  bool success;
  String orderId;
  String? message;
  DateTime timestamp;
  
  Map<String, dynamic> toJson() { ... }
  factory ExternalOrderResponse.fromJson(Map<String, dynamic> json) { ... }
}
```

---

### 4. **`lib/external_order_logger.dart`** - CREATE NEW
**Purpose:** Log all external app orders for auditing
**Should contain:**
```dart
class ExternalOrderLogger {
  Future<void> logOrder(String appId, List<OrderItem> items, bool success) async { ... }
  Future<void> logAuthAttempt(String appId, bool success) async { ... }
  Future<List<ExternalOrderLog>> getOrderHistory(String appId) async { ... }
}
```

---

### 5. **`lib/external_order_manager.dart`** ⭐ CREATE NEW
**Purpose:** Central manager for external orders
**Should contain:**
```dart
class ExternalOrderManager extends ChangeNotifier {
  // Receive order from external app
  Future<String> receiveOrder(ExternalOrderRequest request) async { ... }
  
  // Get available items and prices
  Future<Map<String, dynamic>> getPriceList() async { ... }
  
  // Get device status for external app
  Future<DeviceStatusResponse> getDeviceStatus(String deviceId) async { ... }
  
  // Authenticate external app
  Future<bool> authenticateApp(String appId, String appSecret) async { ... }
  
  // Listen to external orders
  Stream<ExternalOrderEvent> get externalOrdersStream { ... }
}
```

---

### 6. **`lib/screens/external_apps_management_screen.dart`** - CREATE NEW
**Purpose:** UI for managing connected external apps
**Should contain:**
```dart
// Settings screen showing:
// - List of connected external apps
// - Enable/disable external order acceptance
// - External app authentication tokens
// - Recent orders from external apps
// - Port configuration
```

---

## Configuration Files to Modify/Create

### 1. **`smart_sync_config.dart`** - MODIFY
**What to add:**
```dart
class SmartSyncConfig {
  // Existing config...
  
  // New: External App Configuration
  static const int externalOrderPort = 5557; // Different from sync port
  static const bool enableExternalOrders = true;
  static const int maxExternalApps = 10;
  static const String externalAppApiVersion = '1.0.0';
}
```

---

### 2. **`pubspec.yaml`** - MODIFY (if adding Server)
**Packages to add (optional, for server communication):**
```yaml
dependencies:
  # ... existing
  shelf: ^1.4.0          # For HTTP server if using REST API
  shelf_router: ^1.1.0   # For routing
  json_serializable: ^6.0.0  # For JSON serialization
  
dev_dependencies:
  build_runner: ^2.0.0
  json_serializable: ^6.0.0
```

---

## API Documentation (Create)

### Create: **`API_DOCUMENTATION.md`** ⭐ CREATE NEW
Document all endpoints:

```markdown
# External App API Documentation

## Base Endpoint
```
192.168.x.x:5557/api
```

## 1. Authenticate
```
POST /api/auth/token
Request: {appId, appSecret}
Response: {success, token, expiresIn}
```

## 2. Get Device Status
```
GET /api/device/{deviceId}?token={token}
Response: {deviceId, name, isRunning, elapsedTime, availableItems, prices}
```

## 3. Place Order
```
POST /api/order/place
Request: {token, deviceId, items: [{name, price, quantity}], notes}
Response: {success, orderId, message, timestamp}
```

## 4. Get Price List
```
GET /api/prices/list?token={token}
Response: {prices: {itemName: price}, categories}
```

## 5. Get Order History
```
GET /api/orders/history?token={token}&limit=50
Response: {orders: [{orderId, timestamp, items, source}]}
```
```

---

## Security Files to Create

### **`lib/external_app_security.dart`** - CREATE NEW
**Purpose:** Handle security for external apps
**Should contain:**
```dart
class ExternalAppSecurity {
  // Token generation and validation
  Future<String> generateToken(String appId) async { ... }
  bool validateToken(String token) { ... }
  
  // Rate limiting for external apps
  bool checkRateLimit(String appId) { ... }
  
  // Encrypt sensitive data
  String encryptData(String data) { ... }
  String decryptData(String encryptedData) { ... }
}
```

---

## Testing Files to Create

### **`test/external_order_test.dart`** - CREATE NEW
```dart
void main() {
  group('External Order Integration', () {
    test('Place order from external app', () { ... });
    test('Get device status', () { ... });
    test('Authenticate external app', () { ... });
    test('Invalid token rejection', () { ... });
  });
}
```

---

## Summary Table

| File | Action | Priority | Purpose |
|------|--------|----------|---------|
| `app_state.dart` | Modify | 🔴 HIGH | Add order acceptance methods |
| `local_network_sync_service.dart` | Modify | 🔴 HIGH | Add TCP server for orders |
| `main.dart` | Modify | 🔴 HIGH | Initialize external order server |
| `sync_service.dart` | Modify | 🟡 MEDIUM | Add external order handling |
| `external_order_server.dart` | Create | 🔴 HIGH | Dedicated server for external apps |
| `external_order_manager.dart` | Create | 🔴 HIGH | Central order management |
| `external_app_api.dart` | Create | 🔴 HIGH | API definition |
| `external_order_models.dart` | Create | 🔴 HIGH | Data models |
| `order_dialog.dart` | Modify | 🟡 MEDIUM | Show order source |
| `printer_service.dart` | Modify | 🟡 MEDIUM | Print external orders |
| `license_manager.dart` | Modify | 🟡 MEDIUM | License check for feature |
| `external_order_logger.dart` | Create | 🟡 MEDIUM | Order logging |
| `external_app_security.dart` | Create | 🟡 MEDIUM | Token & security |
| `external_apps_management_screen.dart` | Create | 🟢 LOW | Settings UI |
| `device_group_manager.dart` | Modify | 🟢 LOW | Group order distribution |
| `data_persistence_manager.dart` | Modify | 🟢 LOW | Log external orders |
| `API_DOCUMENTATION.md` | Create | 🔴 HIGH | API docs |
| `test/external_order_test.dart` | Create | 🟡 MEDIUM | Unit tests |

---

## Implementation Steps

### Phase 1: Core Infrastructure (Files to do FIRST)
1. ✅ Create `external_order_models.dart` (data models)
2. ✅ Create `external_order_server.dart` (TCP server)
3. ✅ Create `external_order_manager.dart` (main logic)
4. ✅ Modify `app_state.dart` (add acceptance methods)
5. ✅ Modify `main.dart` (initialize server)

### Phase 2: API & Communication
6. ✅ Create `external_app_api.dart` (API definition)
7. ✅ Modify `local_network_sync_service.dart` (integrate with server)
8. ✅ Create `API_DOCUMENTATION.md`

### Phase 3: Security & Logging
9. ✅ Create `external_app_security.dart` (tokens, encryption)
10. ✅ Create `external_order_logger.dart` (auditing)
11. ✅ Modify `sync_service.dart` (add auth)

### Phase 4: UI & Polish
12. ✅ Modify `order_dialog.dart` (show source)
13. ✅ Create `external_apps_management_screen.dart` (settings)
14. ✅ Modify `printer_service.dart` (print source)

### Phase 5: Testing
15. ✅ Create `test/external_order_test.dart`

---

## Quick Reference: What External App Needs

The external app will need to:

1. **Know the device IP address** (on same LAN)
2. **Have an app token** (generated by main app)
3. **Send HTTP POST request** to place order:
   ```
   POST http://<device-ip>:5557/api/order/place
   {
     "token": "app_token_xxx",
     "deviceId": "device123",
     "items": [
       {"name": "Item1", "quantity": 2, "price": 10.0}
     ]
   }
   ```
4. **Handle responses** with order confirmation

---

## Additional Notes

- All communication should be **encrypted** over HTTPS for production
- Implement **rate limiting** to prevent abuse
- Add **audit logging** for all external orders
- Consider **database persistence** for order history
- Add **device discovery** so external app can find device on LAN automatically

---

**Last Updated:** February 2, 2026
**Version:** 1.0 - External App Integration Guide

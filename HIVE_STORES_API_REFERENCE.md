# Hive Stores - Detailed Structure for API Integration

## Overview
- **Primary Hive Box Name:** `safeDevicesBox`
- **Secondary Box Name:** `reservationsBox`
- **Save Location:** `lib/app_state.dart` in `_saveToPrefs()` method (lines 1238-1380)
- **Load Location:** `lib/app_state.dart` in `_loadFromPrefs()` method (lines 1433-1600)

---

## Hive Box: `safeDevicesBox`

### Key-Value Pairs Stored

#### 1. **'devicesData'** (Lines 1267-1268)
**Description:** All devices with their complete state
**Type:** String (JSON encoded)
**Structure:**
```dart
Map<String, DeviceData> = {
  'Pc 1': {
    'name': String,
    'elapsedTime': int (seconds),
    'isRunning': bool,
    'orders': [
      {
        'name': String,
        'price': double,
        'quantity': int,
        'firstOrderTime': DateTime ISO8601,
        'lastOrderTime': DateTime ISO8601,
        'notes': String?
      }
    ],
    'reservations': [
      {
        'name': String,
        'price': double,
        'quantity': int,
        'reservationTime': DateTime ISO8601,
        'notes': String
      }
    ],
    'notes': String,
    'mode': String ('single' or 'multi'),
    'customerCount': int
  }
}
```

**Load Code:** Lines 1458-1467
```dart
final jsonString = box.get('devicesData');
final Map<String, dynamic> jsonData = jsonDecode(jsonString);
_devices = jsonData.map((key, value) =>
    MapEntry(key, DeviceData.fromJson(value as Map<String, dynamic>)));
```

---

#### 2. **'reservationsData'** (Lines 1269-1270)
**Description:** All reservations stored separately
**Type:** String (JSON encoded)
**Structure:**
```dart
List<ReservationItem> = [
  {
    'name': String,
    'price': double,
    'quantity': int,
    'reservationTime': DateTime ISO8601,
    'notes': String
  }
]
```

**Load Code:** Lines 1454-1457
```dart
final boxReservations = await _getBox();
final reservationsString = boxReservations.get('reservationsData');
final List<dynamic> reservationsData = jsonDecode(reservationsString);
_allReservations = reservationsData.map((e) => ReservationItem.fromJson(e)).toList();
```

---

#### 3. **'pricesData'** (Lines 1272-1281)
**Description:** All pricing information
**Type:** String (JSON encoded)
**Structure:**
```dart
{
  'pcPrice': double (default: 1500.0),
  'ps4Prices': {
    'Arabia 1': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 2': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 3': {'single': 3000.0, 'multi': 4000.0},
    'Arabia 4': {'single': 3000.0, 'multi': 4000.0},
    'Arabia 5': {'single': 3000.0, 'multi': 4000.0},
    'Arabia 6': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 7': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 8': {'single': 2000.0, 'multi': 3000.0}
  },
  'pcPrices': {
    'Pc 1': double,
    'Pc 2': double,
    ...
  },
  'tablePrices': {
    'Table 1': double,
    'Table 2': double,
    ...
  },
  'billiardPrices': {
    'Billiard 1': double,
    'Billiard 2': double,
    ...
  }
}
```

**Load Code:** Lines 1469-1487
```dart
final pricesString = box.get('pricesData');
final Map<String, dynamic> pricesData = jsonDecode(pricesString);
_pcPrice = pricesData['pcPrice']?.toDouble() ?? 1500;
_ps4Prices = Map from pricesData['ps4Prices'];
_pcPrices = Map from pricesData['pcPrices'];
_tablePrices = Map from pricesData['tablePrices'];
_billiardPrices = Map from pricesData['billiardPrices'];
```

---

#### 4. **'orderPricesData'** (Lines 1283-1284)
**Description:** Menu item prices
**Type:** String (JSON encoded)
**Structure:**
```dart
Map<String, double> = {
  'Item Name 1': 10.0,
  'Item Name 2': 15.5,
  'Item Name 3': 20.0,
  ...
}
```

**Load Code:** Lines 1489-1493
```dart
final orderPricesString = box.get('orderPricesData');
final Map<String, dynamic> orderPricesData = jsonDecode(orderPricesString);
_orderPrices.addAll(orderPricesData.map((key, value) => MapEntry(key, value.toDouble())));
```

---

#### 5. **'customCategoriesData'** (Lines 1286-1287)
**Description:** Custom order categories with items
**Type:** String (JSON encoded)
**Structure:**
```dart
Map<String, List<String>> = {
  'Drinks': ['Coffee', 'Tea', 'Juice'],
  'Snacks': ['Chips', 'Popcorn', 'Nuts'],
  'Meals': ['Pizza', 'Burger', 'Sandwich'],
  ...
}
```

**Load Code:** Lines 1495-1499
```dart
final customCategoriesString = box.get('customCategoriesData');
final Map<String, dynamic> customCategoriesData = jsonDecode(customCategoriesString);
_customCategories = customCategoriesData.map((key, value) => 
  MapEntry(key, List<String>.from(value)));
```

---

#### 6. **'defaultCategoryNamesData'** (Lines 1289-1290)
**Description:** Display names for categories
**Type:** String (JSON encoded)
**Structure:**
```dart
Map<String, String> = {
  'originalKey1': 'Display Name 1',
  'originalKey2': 'Display Name 2',
  ...
}
```

**Load Code:** Lines 1501-1505
```dart
final defaultCategoryNamesString = box.get('defaultCategoryNamesData');
final Map<String, dynamic> defaultCategoryNamesData = jsonDecode(defaultCategoryNamesString);
_defaultCategoryNames.addAll(defaultCategoryNamesData.map((key, value) => MapEntry(key, value.toString())));
```

---

#### 7. **'todayExpensesData'** (Lines 1292-1293)
**Description:** Daily expenses
**Type:** String (JSON encoded)
**Structure:**
```dart
List<Map<String, dynamic>> = [
  {
    'description': String,
    'amount': double,
    'date': DateTime ISO8601,
    'category': String
  }
]
```

**Load Code:** Lines 1507-1511
```dart
final expensesString = box.get('todayExpensesData');
final List<dynamic> expensesData = jsonDecode(expensesString);
_todayExpenses = List<Map<String, dynamic>>.from(expensesData);
```

---

#### 8. **'manualRevenuesData'** (Lines 1295-1296)
**Description:** Manual revenue entries
**Type:** String (JSON encoded)
**Structure:**
```dart
List<Map<String, dynamic>> = [
  {
    'description': String,
    'amount': double,
    'date': DateTime ISO8601
  }
]
```

**Load Code:** Lines 1513-1517
```dart
final revenuesString = box.get('manualRevenuesData');
final List<dynamic> revenuesData = jsonDecode(revenuesString);
_manualRevenues = List<Map<String, dynamic>>.from(revenuesData);
```

---

#### 9. **'completedMonthsData'** (Lines 1298-1299)
**Description:** Completed month identifiers
**Type:** String (JSON encoded)
**Structure:**
```dart
List<String> = [
  '2024-01',
  '2024-02',
  '2024-03',
  ...
]
```

**Load Code:** Lines 1519-1523
```dart
final completedMonthsString = box.get('completedMonthsData');
final List<dynamic> completedMonthsData = jsonDecode(completedMonthsString);
_completedMonths = Set<String>.from(completedMonthsData);
```

---

#### 10. **'monthlyDataMap'** (Lines 1301-1302)
**Description:** Full monthly financial data
**Type:** String (JSON encoded)
**Structure:**
```dart
Map<String, Map<String, dynamic>> = {
  '2024-01': {
    'revenue': double,
    'expenses': double,
    'profit': double,
    'orders': int,
    ...
  },
  '2024-02': { ... },
  ...
}
```

**Load Code:** Lines 1525-1529
```dart
final monthlyDataString = box.get('monthlyDataMap');
final Map<String, dynamic> monthlyDataRaw = jsonDecode(monthlyDataString);
_monthlyData = monthlyDataRaw.map((key, value) => 
  MapEntry(key, Map<String, dynamic>.from(value as Map)));
```

---

#### 11. **'debtsData'** (Lines 1304-1305)
**Description:** Customer debts
**Type:** String (JSON encoded)
**Structure:**
```dart
List<Map<String, dynamic>> = [
  {
    'name': String,
    'amount': double,
    'date': DateTime ISO8601
  }
]
```

**Load Code:** Lines 1531-1535
```dart
final debtsString = box.get('debtsData');
final List<dynamic> debtsData = jsonDecode(debtsString);
_debts = List<Map<String, dynamic>>.from(debtsData);
```

---

#### 12. **'deletedDevicesData'** (Lines 1307-1308)
**Description:** List of deleted device IDs
**Type:** String (JSON encoded)
**Structure:**
```dart
List<String> = [
  'Pc 5',
  'Arabia 3',
  'Table 2',
  ...
]
```

**Load Code:** Lines 1537-1544
```dart
final deletedDevicesString = box.get('deletedDevicesData');
final List<dynamic> deletedDevicesData = jsonDecode(deletedDevicesString);
_deletedDevices = Set<String>.from(deletedDevicesData);
```

---

#### 13. **'isDarkMode'** (Lines 1310-1311)
**Description:** Theme preference
**Type:** Boolean
**Structure:**
```dart
bool = true or false
```

**Load Code:** Line 1545
```dart
_isDarkMode = box.get('isDarkMode', defaultValue: true);
```

---

## Class Definitions

### OrderItem (Lines 7-45)
```dart
class OrderItem {
  String name;
  double price;
  int quantity;
  DateTime firstOrderTime;
  DateTime lastOrderTime;
  String? notes;
  
  // toJson() at lines 24-31
  // fromJson() at lines 33-45
}
```

### ReservationItem (Lines 47-83)
```dart
class ReservationItem {
  String name;
  double price;
  int quantity;
  DateTime reservationTime;
  String notes;
  
  // toJson() at lines 60-66
  // fromJson() at lines 68-83
}
```

### DeviceData (Lines 85-138)
```dart
class DeviceData {
  String name;
  Duration elapsedTime;
  bool isRunning;
  List<OrderItem> orders;
  List<ReservationItem> reservations;
  String notes;
  String mode;        // 'single' or 'multi'
  int customerCount;
  
  // toJson() at lines 108-118
  // fromJson() at lines 120-138
}
```

---

## AppState Properties (Lines 143-202)

### Collections to Expose via API
```dart
Map<String, DeviceData> _devices = {}
  → Getter: Map<String, DeviceData> get devices => Map.from(_devices);
  
List<ReservationItem> _allReservations = []
  → Getter: List<ReservationItem> get reservations { ... }

Map<String, List<String>> _customCategories = {}
  → Getter: Map<String, List<String>> get customCategories => Map.from(_customCategories);

Map<String, double> _orderPrices = {}
  → Getter: Map<String, double> get orderPrices => Map.from(_orderPrices);

Map<String, double> _pcPrices = {}
  → Method: double getPcPrice(String deviceName) { ... }

Map<String, double> _tablePrices = {}
  → Method: double getTablePrice(String deviceName) { ... }

Map<String, double> _billiardPrices = {}
  → Method: double getBilliardPrice(String deviceName) { ... }

Map<String, Map<String, double>> _ps4Prices = { ... }
  → Getter: Map<String, Map<String, double>> get ps4Prices => Map.from(_ps4Prices);
  → Method: double getPs4Price(String deviceName, String mode) { ... }

List<Map<String, dynamic>> _debts = []
  → Getter: List<Map<String, dynamic>> get debts => List.from(_debts);
  → Method: double getTotalDebts() { ... }

List<Map<String, dynamic>> _todayExpenses = []
  → Getter: List<Map<String, dynamic>> get todayExpenses => List.from(_todayExpenses);

List<Map<String, dynamic>> _manualRevenues = []
  → Used internally for financial tracking

Set<String> _deletedDevices = {}
  → Getter: Set<String> get deletedDevices => Set.from(_deletedDevices);

Map<String, Map<String, dynamic>> _monthlyData = {}
  → Used internally for monthly statistics
```

---

## API Endpoints to Create (Postman Collection)

Based on Hive structure, create these 9 endpoints:

### 1. GET /api/devices
**Description:** Get all devices with complete state
**Hive Source:** `devicesData` key
**Returns:** Map<String, DeviceData>
**From:** `appState.devices`
**URL:** `{{baseUrl}}/api/devices`

### 2. GET /api/devices/{id}
**Description:** Get single device by ID
**Hive Source:** `devicesData[deviceId]`
**Returns:** DeviceData
**From:** `appState.devices[deviceId]`
**URL:** `{{baseUrl}}/api/devices/Pc 1`

### 3. GET /api/devices/{id}/orders
**Description:** Get all orders for device
**Hive Source:** `devicesData[deviceId].orders`
**Returns:** List<OrderItem> with totalItems & totalPrice
**From:** `appState.devices[deviceId].orders`
**URL:** `{{baseUrl}}/api/devices/Pc 1/orders`

### 4. GET /api/reservations
**Description:** Get all reservations
**Hive Source:** `reservationsData` key
**Returns:** List<ReservationItem> with totalValue
**From:** `appState.reservations`
**URL:** `{{baseUrl}}/api/reservations`

### 5. GET /api/prices
**Description:** Get all pricing information
**Hive Source:** `pricesData` key (combined)
**Returns:** { pcPrice, pcPrices, tablePrices, billiardPrices, ps4Prices, orderPrices }
**From:** `appState.pcPrice`, `appState.devices`, `appState.ps4Prices`, `appState.orderPrices`
**URL:** `{{baseUrl}}/api/prices`

### 6. GET /api/categories
**Description:** Get all custom order categories
**Hive Source:** `customCategoriesData` key
**Returns:** Map<String, List<String>> with itemCounts
**From:** `appState.customCategories`
**URL:** `{{baseUrl}}/api/categories`

### 7. GET /api/debts
**Description:** Get all customer debts
**Hive Source:** `debtsData` key
**Returns:** List<Map<String, dynamic>> with totalDebt
**From:** `appState.debts`, `appState.getTotalDebts()`
**URL:** `{{baseUrl}}/api/debts`

### 8. GET /api/expenses
**Description:** Get daily expenses
**Hive Source:** `todayExpensesData` key
**Returns:** List<Map<String, dynamic>> with totalExpenses
**From:** `appState.todayExpenses`
**URL:** `{{baseUrl}}/api/expenses`

### 9. POST /api/order/place
**Description:** Place new order on device
**Hive Update:** Updates `devicesData[deviceId].orders`
**Input:** { deviceId, items, notes }
**Returns:** { orderId, deviceId, itemsCount, totalPrice }
**Updates:** `appState.devices[deviceId].orders` + calls `appState._saveToPrefs()`
**URL:** `{{baseUrl}}/api/order/place`
**Request Body:**
```json
{
  "deviceId": "Pc 1",
  "items": [
    {
      "name": "Cola",
      "price": 5.0,
      "quantity": 2,
      "notes": "Test Order"
    }
  ],
  "notes": "App Order"
}
```

---

## Detailed Endpoint Implementations

### File: `lib/api_endpoints.dart` (CREATE NEW)

Add these methods to expose Hive data via API:

---

#### 1. **GET /api/devices** - Get All Devices
**Hive Source:** `devicesData` key
**Method Signature:**
```dart
Future<Map<String, dynamic>> getAllDevices(AppState appState) async {
  try {
    final devices = appState.devices;
    return {
      'success': true,
      'data': devices.map((key, value) => MapEntry(key, value.toJson())),
      'count': devices.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/devices') {
  final response = await getAllDevices(_appState);
  await _sendResponse(socket, response);
}
```

---

#### 2. **GET /api/devices/{deviceId}** - Get Single Device
**Hive Source:** `devicesData[deviceId]`
**Method Signature:**
```dart
Future<Map<String, dynamic>> getDeviceById(AppState appState, String deviceId) async {
  try {
    final device = appState.devices[deviceId];
    if (device == null) {
      return {
        'success': false,
        'error': 'Device not found: $deviceId',
      };
    }
    
    return {
      'success': true,
      'data': device.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'].startsWith('/api/devices/') && !request['endpoint'].contains('/orders')) {
  final deviceId = request['endpoint'].split('/').last;
  final response = await getDeviceById(_appState, deviceId);
  await _sendResponse(socket, response);
}
```

---

#### 3. **GET /api/devices/{deviceId}/orders** - Get Device Orders
**Hive Source:** `devicesData[deviceId].orders`
**Method Signature:**
```dart
Future<Map<String, dynamic>> getDeviceOrders(AppState appState, String deviceId) async {
  try {
    final device = appState.devices[deviceId];
    if (device == null) {
      return {
        'success': false,
        'error': 'Device not found: $deviceId',
      };
    }
    
    return {
      'success': true,
      'deviceId': deviceId,
      'orders': device.orders.map((o) => o.toJson()).toList(),
      'totalItems': device.orders.fold(0, (sum, order) => sum + order.quantity),
      'totalPrice': device.orders.fold(0.0, (sum, order) => sum + (order.price * order.quantity)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'].contains('/api/devices/') && request['endpoint'].contains('/orders')) {
  final parts = request['endpoint'].split('/');
  final deviceId = parts[3];
  final response = await getDeviceOrders(_appState, deviceId);
  await _sendResponse(socket, response);
}
```

---

#### 4. **GET /api/reservations** - Get All Reservations
**Hive Source:** `reservationsData` key
**Method Signature:**
```dart
Future<Map<String, dynamic>> getAllReservations(AppState appState) async {
  try {
    final reservations = appState.reservations;
    return {
      'success': true,
      'data': reservations.map((r) => r.toJson()).toList(),
      'count': reservations.length,
      'totalValue': reservations.fold(0.0, (sum, res) => sum + (res.price * res.quantity)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/reservations') {
  final response = await getAllReservations(_appState);
  await _sendResponse(socket, response);
}
```

---

#### 5. **GET /api/prices** - Get All Prices
**Hive Source:** `pricesData` key (combined from multiple fields)
**Method Signature:**
```dart
Future<Map<String, dynamic>> getAllPrices(AppState appState) async {
  try {
    return {
      'success': true,
      'pcPrice': appState.pcPrice,
      'pcPrices': appState.devices
          .where((k, v) => k.startsWith('Pc'))
          .map((k, v) => MapEntry(k, appState.getPcPrice(k))),
      'tablePrices': appState.devices
          .where((k, v) => k.startsWith('Table'))
          .map((k, v) => MapEntry(k, appState.getTablePrice(k))),
      'billiardPrices': appState.devices
          .where((k, v) => k.startsWith('Billiard'))
          .map((k, v) => MapEntry(k, appState.getBilliardPrice(k))),
      'ps4Prices': appState.ps4Prices,
      'orderPrices': appState.orderPrices,
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/prices') {
  final response = await getAllPrices(_appState);
  await _sendResponse(socket, response);
}
```

---

#### 6. **GET /api/categories** - Get All Categories
**Hive Source:** `customCategoriesData` key
**Method Signature:**
```dart
Future<Map<String, dynamic>> getCategories(AppState appState) async {
  try {
    final categories = appState.customCategories;
    return {
      'success': true,
      'categories': categories,
      'count': categories.length,
      'itemCounts': categories.map((k, v) => MapEntry(k, v.length)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/categories') {
  final response = await getCategories(_appState);
  await _sendResponse(socket, response);
}
```

---

#### 7. **GET /api/debts** - Get All Debts
**Hive Source:** `debtsData` key
**Method Signature:**
```dart
Future<Map<String, dynamic>> getDebts(AppState appState) async {
  try {
    final debts = appState.debts;
    final totalDebt = appState.getTotalDebts();
    
    return {
      'success': true,
      'debts': debts,
      'count': debts.length,
      'totalDebt': totalDebt,
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/debts') {
  final response = await getDebts(_appState);
  await _sendResponse(socket, response);
}
```

---

#### 8. **GET /api/expenses** - Get Daily Expenses
**Hive Source:** `todayExpensesData` key
**Method Signature:**
```dart
Future<Map<String, dynamic>> getExpenses(AppState appState) async {
  try {
    final expenses = appState.todayExpenses;
    final totalExpenses = expenses.fold(0.0, (sum, exp) => sum + (exp['amount'] ?? 0.0));
    
    return {
      'success': true,
      'expenses': expenses,
      'count': expenses.length,
      'totalExpenses': totalExpenses,
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/expenses') {
  final response = await getExpenses(_appState);
  await _sendResponse(socket, response);
}
```

---

#### 9. **POST /api/order/place** - Place New Order
**Hive Update:** Updates `devicesData[deviceId].orders`
**Method Signature:**
```dart
Future<Map<String, dynamic>> placeOrder(
  AppState appState,
  String deviceId,
  List<Map<String, dynamic>> items,
  {String? notes}
) async {
  try {
    final device = appState.devices[deviceId];
    if (device == null) {
      return {
        'success': false,
        'error': 'Device not found: $deviceId',
      };
    }
    
    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    // Add orders to device
    for (final item in items) {
      device.orders.add(
        OrderItem(
          name: item['name'],
          price: (item['price'] as num).toDouble(),
          quantity: item['quantity'] as int,
          firstOrderTime: now,
          lastOrderTime: now,
          notes: notes ?? item['notes'],
        ),
      );
    }
    
    // Save to Hive
    await appState.saveAllData();
    
    return {
      'success': true,
      'orderId': orderId,
      'deviceId': deviceId,
      'itemsCount': items.length,
      'totalPrice': items.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1))),
      'timestamp': now.toIso8601String(),
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

**Integration Location:** `lib/external_order_server.dart` → `_handleOrderMessage()`
```dart
if (request['endpoint'] == '/api/order/place' && request['method'] == 'POST') {
  final deviceId = request['deviceId'];
  final items = request['items'];
  final notes = request['notes'];
  
  final response = await placeOrder(_appState, deviceId, items, notes: notes);
  await _sendResponse(socket, response);
}
```

---

## Where to Make Changes

| Item | File | Method | Lines |
|------|------|--------|-------|
| Save Logic | `lib/app_state.dart` | `_saveToPrefs()` | 1238-1380 |
| Load Logic | `lib/app_state.dart` | `_loadFromPrefs()` | 1433-1600 |
| Get Box | `lib/app_state.dart` | `_getBox()` | 1179-1235 |
| Hive Box Name | `lib/app_state.dart` | Line 1200 | `const boxName = 'safeDevicesBox';` |
| Class Models | `lib/app_state.dart` | Lines 7-138 | OrderItem, ReservationItem, DeviceData |
| AppState Props | `lib/app_state.dart` | Lines 143-202 | All private fields |
| Getters/Setters | `lib/app_state.dart` | Lines 212-323 | Accessors for API |
| **API Endpoints** | **`lib/api_endpoints.dart`** | **NEW FILE** | **All 9 methods** |
| **Integration** | **`lib/external_order_server.dart`** | **`_handleOrderMessage()`** | **Route requests** |

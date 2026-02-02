# API Endpoints Implementation Prompt

## Project Context
- **App:** Berlin Gaming Cashier (Flutter)
- **Database:** Hive (Local NoSQL)
- **Primary Box:** `safeDevicesBox`
- **Data Source:** AppState class in `lib/app_state.dart`
- **Implementation File:** Create `lib/api_endpoints.dart`
- **Integration File:** `lib/external_order_server.dart` → `_handleOrderMessage()` method

---

## Required Endpoints

### Endpoint 1: GET /api/devices
**Purpose:** Retrieve all devices with their current state

**Hive Source:** `devicesData` key from `safeDevicesBox`

**Request Format:**
```json
GET /api/devices
```

**Response Format:**
```json
{
  "success": true,
  "data": {
    "Pc 1": {
      "name": "Pc 1",
      "elapsedTime": 9000,
      "isRunning": true,
      "orders": [...],
      "reservations": [...],
      "notes": "",
      "mode": "single",
      "customerCount": 1
    },
    "Arabia 1": { ... }
  },
  "count": 30,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Requirements:**
- Get all devices from `appState.devices`
- Convert each device to JSON using `device.toJson()`
- Include device count
- Add ISO8601 timestamp

---

### Endpoint 2: GET /api/devices/{deviceId}
**Purpose:** Retrieve a single device by ID

**Hive Source:** `devicesData[deviceId]` from `safeDevicesBox`

**Request Format:**
```json
GET /api/devices/Pc%201
```

**Response Format:**
```json
{
  "success": true,
  "data": {
    "name": "Pc 1",
    "elapsedTime": 9000,
    "isRunning": true,
    "orders": [
      {
        "name": "Item 1",
        "price": 10.0,
        "quantity": 2,
        "firstOrderTime": "2026-02-02T10:00:00.000Z",
        "lastOrderTime": "2026-02-02T10:15:00.000Z",
        "notes": "Test order"
      }
    ],
    "reservations": [],
    "notes": "",
    "mode": "single",
    "customerCount": 1
  },
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Device not found: Pc 1"
}
```

**Implementation Requirements:**
- Extract deviceId from URL path
- Validate device exists
- Return device data as JSON
- Return error if device not found

---

### Endpoint 3: GET /api/devices/{deviceId}/orders
**Purpose:** Retrieve all orders for a specific device

**Hive Source:** `devicesData[deviceId].orders` from `safeDevicesBox`

**Request Format:**
```json
GET /api/devices/Pc%201/orders
```

**Response Format:**
```json
{
  "success": true,
  "deviceId": "Pc 1",
  "orders": [
    {
      "name": "Item 1",
      "price": 10.0,
      "quantity": 2,
      "firstOrderTime": "2026-02-02T10:00:00.000Z",
      "lastOrderTime": "2026-02-02T10:15:00.000Z",
      "notes": "Test order"
    },
    {
      "name": "Item 2",
      "price": 15.0,
      "quantity": 1,
      "firstOrderTime": "2026-02-02T10:20:00.000Z",
      "lastOrderTime": "2026-02-02T10:20:00.000Z",
      "notes": null
    }
  ],
  "totalItems": 3,
  "totalPrice": 35.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Device not found: Pc 1"
}
```

**Implementation Requirements:**
- Extract deviceId from URL path
- Get device from `appState.devices[deviceId]`
- Return all orders as JSON array
- Calculate total items quantity
- Calculate total price (sum of price * quantity)
- Return error if device not found

---

### Endpoint 4: GET /api/reservations
**Purpose:** Retrieve all reservations across all devices

**Hive Source:** `reservationsData` key from `safeDevicesBox`

**Request Format:**
```json
GET /api/reservations
```

**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "name": "Item 1",
      "price": 10.0,
      "quantity": 2,
      "reservationTime": "2026-02-02T10:00:00.000Z",
      "notes": "Reserved for tomorrow"
    },
    {
      "name": "Item 2",
      "price": 25.0,
      "quantity": 1,
      "reservationTime": "2026-02-02T10:15:00.000Z",
      "notes": "Gaming reservation"
    }
  ],
  "count": 2,
  "totalValue": 45.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Requirements:**
- Get reservations from `appState.reservations`
- Convert each reservation to JSON using `reservation.toJson()`
- Include reservation count
- Calculate total value (sum of price * quantity)
- Add ISO8601 timestamp

---

### Endpoint 5: GET /api/prices
**Purpose:** Retrieve all pricing information

**Hive Source:** `pricesData` key from `safeDevicesBox`

**Request Format:**
```json
GET /api/prices
```

**Response Format:**
```json
{
  "success": true,
  "pcPrice": 1500.0,
  "pcPrices": {
    "Pc 1": 1000.0,
    "Pc 2": 1500.0,
    "Pc 3": 1500.0
  },
  "tablePrices": {
    "Table 1": 500.0,
    "Table 2": 750.0
  },
  "billiardPrices": {
    "Billiard 1": 2000.0,
    "Billiard 2": 2000.0
  },
  "ps4Prices": {
    "Arabia 1": {
      "single": 2000.0,
      "multi": 3000.0
    },
    "Arabia 2": {
      "single": 2000.0,
      "multi": 3000.0
    }
  },
  "orderPrices": {
    "Coffee": 3.0,
    "Tea": 2.5,
    "Juice": 4.0,
    "Snack": 5.0
  },
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Requirements:**
- Get `pcPrice` from `appState.pcPrice`
- Get PC prices from `appState.devices` where key starts with "Pc"
- Get Table prices from `appState.devices` where key starts with "Table"
- Get Billiard prices from `appState.devices` where key starts with "Billiard"
- Get PS4 prices from `appState.ps4Prices`
- Get order prices from `appState.orderPrices`
- Add ISO8601 timestamp

---

### Endpoint 6: GET /api/categories
**Purpose:** Retrieve all custom order categories

**Hive Source:** `customCategoriesData` key from `safeDevicesBox`

**Request Format:**
```json
GET /api/categories
```

**Response Format:**
```json
{
  "success": true,
  "categories": {
    "Drinks": [
      "Coffee",
      "Tea",
      "Juice"
    ],
    "Snacks": [
      "Chips",
      "Popcorn",
      "Nuts"
    ],
    "Meals": [
      "Pizza",
      "Burger",
      "Sandwich"
    ]
  },
  "count": 3,
  "itemCounts": {
    "Drinks": 3,
    "Snacks": 3,
    "Meals": 3
  },
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Requirements:**
- Get categories from `appState.customCategories`
- Count total categories
- Count items in each category
- Add ISO8601 timestamp

---

### Endpoint 7: GET /api/debts
**Purpose:** Retrieve all customer debts

**Hive Source:** `debtsData` key from `safeDevicesBox`

**Request Format:**
```json
GET /api/debts
```

**Response Format:**
```json
{
  "success": true,
  "debts": [
    {
      "name": "Customer 1",
      "amount": 100.0,
      "date": "2026-02-01T14:30:00.000Z"
    },
    {
      "name": "Customer 2",
      "amount": 250.0,
      "date": "2026-02-02T10:00:00.000Z"
    }
  ],
  "count": 2,
  "totalDebt": 350.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Requirements:**
- Get debts from `appState.debts`
- Count total debts
- Calculate total debt amount using `appState.getTotalDebts()`
- Add ISO8601 timestamp

---

### Endpoint 8: GET /api/expenses
**Purpose:** Retrieve daily expenses

**Hive Source:** `todayExpensesData` key from `safeDevicesBox`

**Request Format:**
```json
GET /api/expenses
```

**Response Format:**
```json
{
  "success": true,
  "expenses": [
    {
      "description": "Office supplies",
      "amount": 50.0,
      "date": "2026-02-02T09:00:00.000Z",
      "category": "Supplies"
    },
    {
      "description": "Utilities",
      "amount": 150.0,
      "date": "2026-02-02T10:00:00.000Z",
      "category": "Bills"
    }
  ],
  "count": 2,
  "totalExpenses": 200.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Requirements:**
- Get expenses from `appState.todayExpenses`
- Count total expenses
- Calculate total expense amount (sum of all 'amount' fields)
- Add ISO8601 timestamp

---

### Endpoint 9: POST /api/order/place
**Purpose:** Place a new order on a device

**Hive Update:** Updates `devicesData[deviceId].orders`

**Request Format:**
```json
POST /api/order/place
Content-Type: application/json

{
  "deviceId": "Pc 1",
  "items": [
    {
      "name": "Coffee",
      "price": 3.0,
      "quantity": 2,
      "notes": "Extra sugar"
    },
    {
      "name": "Juice",
      "price": 4.0,
      "quantity": 1,
      "notes": null
    }
  ],
  "notes": "External order from app"
}
```

**Response Format:**
```json
{
  "success": true,
  "orderId": "ORD_1738500600000",
  "deviceId": "Pc 1",
  "itemsCount": 2,
  "totalPrice": 10.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Device not found: Pc 1"
}
```

**Implementation Requirements:**
- Extract `deviceId`, `items`, and optional `notes` from request
- Validate device exists in `appState.devices`
- Create OrderItem for each item with:
  - `name` from request
  - `price` from request (convert to double)
  - `quantity` from request (convert to int)
  - `firstOrderTime` = current DateTime
  - `lastOrderTime` = current DateTime
  - `notes` from request or null
- Add OrderItem to device's orders list
- Save using `appState._saveToPrefs()` or equivalent
- Generate orderId with format: `ORD_{millisecondsSinceEpoch}`
- Calculate total price (sum of price * quantity)
- Return error if device not found

---

## Integration Instructions

### Step 1: Create File
Create new file: `lib/api_endpoints.dart`

### Step 2: Implement Methods
Implement all 9 methods as specified above

### Step 3: Integrate with Server
In `lib/external_order_server.dart`, modify the `_handleOrderMessage()` method to route requests:

```dart
void _handleOrderMessage(Socket socket, Map<String, dynamic> request) async {
  final endpoint = request['endpoint'] as String;
  final method = request['method'] as String? ?? 'GET';
  
  try {
    Map<String, dynamic> response;
    
    // Route requests to appropriate endpoint
    if (endpoint == '/api/devices' && method == 'GET') {
      response = await getAllDevices(_appState);
    }
    else if (endpoint.startsWith('/api/devices/') && endpoint.contains('/orders') && method == 'GET') {
      final deviceId = endpoint.split('/')[3];
      response = await getDeviceOrders(_appState, deviceId);
    }
    else if (endpoint.startsWith('/api/devices/') && !endpoint.contains('/orders') && method == 'GET') {
      final deviceId = endpoint.split('/')[3];
      response = await getDeviceById(_appState, deviceId);
    }
    else if (endpoint == '/api/reservations' && method == 'GET') {
      response = await getAllReservations(_appState);
    }
    else if (endpoint == '/api/prices' && method == 'GET') {
      response = await getAllPrices(_appState);
    }
    else if (endpoint == '/api/categories' && method == 'GET') {
      response = await getCategories(_appState);
    }
    else if (endpoint == '/api/debts' && method == 'GET') {
      response = await getDebts(_appState);
    }
    else if (endpoint == '/api/expenses' && method == 'GET') {
      response = await getExpenses(_appState);
    }
    else if (endpoint == '/api/order/place' && method == 'POST') {
      final deviceId = request['deviceId'];
      final items = request['items'];
      final notes = request['notes'];
      response = await placeOrder(_appState, deviceId, items, notes: notes);
    }
    else {
      response = {
        'success': false,
        'error': 'Endpoint not found: $endpoint'
      };
    }
    
    await _sendResponse(socket, response);
  } catch (e) {
    await _sendResponse(socket, {
      'success': false,
      'error': 'Server error: $e'
    });
  }
}
```

### Step 4: Add Imports
```dart
import 'app_state.dart';
import 'api_endpoints.dart';
```

---

## Data Types Reference

### OrderItem
```dart
{
  "name": String,
  "price": double,
  "quantity": int,
  "firstOrderTime": String (ISO8601),
  "lastOrderTime": String (ISO8601),
  "notes": String?
}
```

### ReservationItem
```dart
{
  "name": String,
  "price": double,
  "quantity": int,
  "reservationTime": String (ISO8601),
  "notes": String
}
```

### DeviceData
```dart
{
  "name": String,
  "elapsedTime": int (seconds),
  "isRunning": boolean,
  "orders": OrderItem[],
  "reservations": ReservationItem[],
  "notes": String,
  "mode": String ("single" or "multi"),
  "customerCount": int
}
```

---

## Testing Checklist

- [ ] Endpoint 1: GET /api/devices - Returns all devices
- [ ] Endpoint 2: GET /api/devices/{deviceId} - Returns single device
- [ ] Endpoint 3: GET /api/devices/{deviceId}/orders - Returns device orders
- [ ] Endpoint 4: GET /api/reservations - Returns all reservations
- [ ] Endpoint 5: GET /api/prices - Returns all prices
- [ ] Endpoint 6: GET /api/categories - Returns all categories
- [ ] Endpoint 7: GET /api/debts - Returns all debts
- [ ] Endpoint 8: GET /api/expenses - Returns all expenses
- [ ] Endpoint 9: POST /api/order/place - Places new order successfully
- [ ] All endpoints return error response on failure
- [ ] All endpoints include timestamp in response
- [ ] Data saves to Hive after order placement

---

**Created:** February 2, 2026
**Total Endpoints:** 9 (8 GET, 1 POST)
**Status:** Ready for Implementation

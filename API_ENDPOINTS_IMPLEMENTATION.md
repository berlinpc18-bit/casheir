# API Endpoints - Implementation Ready

## Prompt

You need to implement 9 REST API endpoints that expose data from a Flutter Hive database to an external mobile app. Each endpoint retrieves or modifies data stored in the `safeDevicesBox` Hive box from the Berlin Gaming Cashier app.

**Core Requirements:**
- All endpoints must read from AppState class getters/methods
- All responses must include `success: boolean` and `timestamp: ISO8601`
- Error responses must include `error: string`
- POST endpoint must update Hive database via `appState._saveToPrefs()`
- All data types must be serialized to JSON

---

## Endpoints

### 1. GET /api/devices

**Purpose:** Get all devices with complete state

**Request:**
```
GET /api/devices
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "Pc 1": {
      "name": "Pc 1",
      "elapsedTime": 9000,
      "isRunning": true,
      "orders": [
        {
          "name": "Coffee",
          "price": 3.0,
          "quantity": 2,
          "firstOrderTime": "2026-02-02T10:00:00.000Z",
          "lastOrderTime": "2026-02-02T10:15:00.000Z",
          "notes": "Extra sugar"
        }
      ],
      "reservations": [],
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

**Response (Error):**
```json
{
  "success": false,
  "error": "Error message here",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Get all devices: `appState.devices` (returns `Map<String, DeviceData>`)
- Convert each to JSON: `device.toJson()`
- Return device count
- Wrap in response object with timestamp

---

### 2. GET /api/devices/{deviceId}

**Purpose:** Get single device by ID

**Request:**
```
GET /api/devices/Pc%201
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "name": "Pc 1",
    "elapsedTime": 9000,
    "isRunning": true,
    "orders": [...],
    "reservations": [],
    "notes": "",
    "mode": "single",
    "customerCount": 1
  },
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Device not found: Pc 1",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Extract deviceId from URL: `request['endpoint'].split('/')[3]`
- Get device: `appState.devices[deviceId]`
- Return device.toJson() if exists
- Return error if null

---

### 3. GET /api/devices/{deviceId}/orders

**Purpose:** Get all orders for a device

**Request:**
```
GET /api/devices/Pc%201/orders
```

**Response (Success):**
```json
{
  "success": true,
  "deviceId": "Pc 1",
  "orders": [
    {
      "name": "Coffee",
      "price": 3.0,
      "quantity": 2,
      "firstOrderTime": "2026-02-02T10:00:00.000Z",
      "lastOrderTime": "2026-02-02T10:15:00.000Z",
      "notes": "Extra sugar"
    }
  ],
  "totalItems": 3,
  "totalPrice": 10.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Device not found: Pc 1",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Extract deviceId from URL: `request['endpoint'].split('/')[3]`
- Get device: `appState.devices[deviceId]`
- Get orders: `device.orders.map((o) => o.toJson()).toList()`
- Calculate totalItems: `orders.fold(0, (sum, order) => sum + order.quantity)`
- Calculate totalPrice: `orders.fold(0.0, (sum, order) => sum + (order.price * order.quantity))`
- Return error if device not found

---

### 4. GET /api/reservations

**Purpose:** Get all reservations

**Request:**
```
GET /api/reservations
```

**Response (Success):**
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
    }
  ],
  "count": 1,
  "totalValue": 20.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Error message here",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Get reservations: `appState.reservations` (returns `List<ReservationItem>`)
- Convert to JSON: `reservations.map((r) => r.toJson()).toList()`
- Count: `reservations.length`
- Calculate totalValue: `reservations.fold(0.0, (sum, res) => sum + (res.price * res.quantity))`

---

### 5. GET /api/prices

**Purpose:** Get all pricing data

**Request:**
```
GET /api/prices
```

**Response (Success):**
```json
{
  "success": true,
  "pcPrice": 1500.0,
  "pcPrices": {
    "Pc 1": 1000.0,
    "Pc 2": 1500.0
  },
  "tablePrices": {
    "Table 1": 500.0
  },
  "billiardPrices": {
    "Billiard 1": 2000.0
  },
  "ps4Prices": {
    "Arabia 1": {
      "single": 2000.0,
      "multi": 3000.0
    }
  },
  "orderPrices": {
    "Coffee": 3.0,
    "Tea": 2.5,
    "Juice": 4.0
  },
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Error message here",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- pcPrice: `appState.pcPrice`
- pcPrices: Filter devices where key starts with "Pc", map to `appState.getPcPrice(deviceName)`
- tablePrices: Filter devices where key starts with "Table", map to `appState.getTablePrice(deviceName)`
- billiardPrices: Filter devices where key starts with "Billiard", map to `appState.getBilliardPrice(deviceName)`
- ps4Prices: `appState.ps4Prices`
- orderPrices: `appState.orderPrices`

---

### 6. GET /api/categories

**Purpose:** Get all product categories

**Request:**
```
GET /api/categories
```

**Response (Success):**
```json
{
  "success": true,
  "categories": {
    "Drinks": ["Coffee", "Tea", "Juice"],
    "Snacks": ["Chips", "Popcorn"],
    "Meals": ["Pizza", "Burger"]
  },
  "count": 3,
  "itemCounts": {
    "Drinks": 3,
    "Snacks": 2,
    "Meals": 2
  },
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Error message here",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Get categories: `appState.customCategories` (returns `Map<String, List<String>>`)
- Count: `categories.length`
- Item counts: `categories.map((k, v) => MapEntry(k, v.length))`

---

### 7. GET /api/debts

**Purpose:** Get all customer debts

**Request:**
```
GET /api/debts
```

**Response (Success):**
```json
{
  "success": true,
  "debts": [
    {
      "name": "Customer 1",
      "amount": 100.0,
      "date": "2026-02-01T14:30:00.000Z"
    }
  ],
  "count": 1,
  "totalDebt": 100.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Error message here",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Get debts: `appState.debts` (returns `List<Map<String, dynamic>>`)
- Count: `debts.length`
- Total debt: `appState.getTotalDebts()` (already calculates sum)

---

### 8. GET /api/expenses

**Purpose:** Get daily expenses

**Request:**
```
GET /api/expenses
```

**Response (Success):**
```json
{
  "success": true,
  "expenses": [
    {
      "description": "Office supplies",
      "amount": 50.0,
      "date": "2026-02-02T09:00:00.000Z",
      "category": "Supplies"
    }
  ],
  "count": 1,
  "totalExpenses": 50.0,
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Error message here",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
- Get expenses: `appState.todayExpenses` (returns `List<Map<String, dynamic>>`)
- Count: `expenses.length`
- Total: `expenses.fold(0.0, (sum, exp) => sum + (exp['amount'] ?? 0.0))`

---

### 9. POST /api/order/place

**Purpose:** Place new order on device

**Request:**
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
      "quantity": 1
    }
  ],
  "notes": "External order"
}
```

**Response (Success):**
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

**Response (Error):**
```json
{
  "success": false,
  "error": "Device not found: Pc 1",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Implementation:**
1. Extract from request:
   - `deviceId = request['deviceId']`
   - `items = request['items']` (Array of objects)
   - `notes = request['notes']` (Optional)

2. Validate device exists:
   - `device = appState.devices[deviceId]`
   - Return error if null

3. Create orderId:
   - `orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}'`

4. For each item in items array:
   ```
   device.orders.add(OrderItem(
     name: item['name'],
     price: item['price'].toDouble(),
     quantity: item['quantity'].toInt(),
     firstOrderTime: DateTime.now(),
     lastOrderTime: DateTime.now(),
     notes: notes ?? item['notes']
   ))
   ```

5. Save to Hive:
   - Call `appState._saveToPrefs()` or `appState.saveAllData()`

6. Calculate totalPrice:
   - `items.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)))`

7. Return success response with orderId

---

## Integration

**Route Requests in Server Handler:**

```
if endpoint == '/api/devices' && method == 'GET'
  → Call getAllDevices()

if endpoint == '/api/devices/{id}' && method == 'GET'
  → Extract id from path, call getDeviceById(id)

if endpoint == '/api/devices/{id}/orders' && method == 'GET'
  → Extract id from path, call getDeviceOrders(id)

if endpoint == '/api/reservations' && method == 'GET'
  → Call getAllReservations()

if endpoint == '/api/prices' && method == 'GET'
  → Call getAllPrices()

if endpoint == '/api/categories' && method == 'GET'
  → Call getCategories()

if endpoint == '/api/debts' && method == 'GET'
  → Call getDebts()

if endpoint == '/api/expenses' && method == 'GET'
  → Call getExpenses()

if endpoint == '/api/order/place' && method == 'POST'
  → Call placeOrder(deviceId, items, notes)
```

---

## Data Types

**OrderItem:**
```json
{
  "name": "String",
  "price": "double",
  "quantity": "int",
  "firstOrderTime": "ISO8601 DateTime",
  "lastOrderTime": "ISO8601 DateTime",
  "notes": "String or null"
}
```

**ReservationItem:**
```json
{
  "name": "String",
  "price": "double",
  "quantity": "int",
  "reservationTime": "ISO8601 DateTime",
  "notes": "String"
}
```

**DeviceData:**
```json
{
  "name": "String",
  "elapsedTime": "int (seconds)",
  "isRunning": "boolean",
  "orders": "OrderItem[]",
  "reservations": "ReservationItem[]",
  "notes": "String",
  "mode": "String (single|multi)",
  "customerCount": "int"
}
```

---

**Status:** Ready for Implementation
**Total Endpoints:** 9 (8 GET, 1 POST)
**Data Source:** AppState class from Flutter app
**Database:** Hive NoSQL (safeDevicesBox)

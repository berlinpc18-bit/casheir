# Server API Endpoints Specification for Helper App

This document outlines the required API endpoints to fully migrate the application settings and data management to the server.

## 1. Global Settings & Prices

### Get All Settings
**GET** `/api/settings`
Returns all global application settings including prices.

**Response:**
```json
{
  "prices": {
    "pc_price_default": 1500.0,
    "pc_prices_individual": {
      "PC 1": 1500.0,
      "PC 2": 1800.0
    },
    "ps4_prices": {
      "Arabia 1": { "single": 2000.0, "multi": 3000.0 },
      "Arabia 2": { "single": 2000.0, "multi": 3000.0 }
    },
    "table_prices": {
      "Table 1": 1000.0
    },
    "billiard_price": 2000.0
  },
  "preferences": {
    "sound_enabled": true,
    "dark_mode": true
  }
}
```

### Update Prices
**PUT** `/api/settings/prices`
Updates the pricing configuration.

**Request Body:**
```json
{
  "pc_price_default": 1600.0,
  "ps4_prices": {
    "Arabia 1": { "single": 2500.0, "multi": 3500.0 }
  }
  // partial updates allowed
}
```

---

## 2. Menu & Products Management

### Get All Products & Categories
**GET** `/api/products`
Returns the full menu hierarchy.

**Response:**
```json
{
  "categories": [
    {
      "id": "cat_1",
      "name": "Hot Drinks",
      "items": [
        {
          "id": "prod_1",
          "name": "Tea",
          "price": 250.0
        },
        {
          "id": "prod_2",
          "name": "Coffee",
          "price": 500.0
        }
      ]
    },
    {
      "id": "cat_2",
      "name": "Cold Drinks",
      "items": []
    }
  ],
  "custom_layout": {
    "VIP Section": ["PC 1", "PC 2"],
    "Main Hall": ["Table 1", "Table 2"]
  }
}
```

### Add/Update Product
**POST** `/api/products`
Adds or updates a product.

**Request Body:**
```json
{
  "id": "prod_new", // Optional for new items
  "category_id": "cat_1",
  "name": "Green Tea",
  "price": 300.0
}
```

### Delete Product
**DELETE** `/api/products/{id}`

---

## 3. Devices Management

### Get All Devices
**GET** `/api/devices`
Returns all configured devices as a map of IDs to Device Objects (matching Hive schema).

**Response:**
```json
{
  "success": true,
  "data": {
    "dev_1770169700633_0": {
      "name": "Arabia 1",
      "elapsedTime": 0,
      "isRunning": false,
      "orders": [],
      "reservations": [],
      "notes": "",
      "mode": "single",
      "customerCount": 1
    },
    "dev_1770169734787_0": {
      "name": "Pc 1",
      "elapsedTime": 0,
      "isRunning": false,
      "orders": [],
      "reservations": [],
      "notes": "",
      "mode": "single",
      "customerCount": 1
    }
  },
  "count": 2,
  "timestamp": "2026-02-04T01:49:03.452354Z"
}
```

### Add Device
**POST** `/api/devices`
Adds a new device. The body should correspond to the Hive `DeviceData` schema.

**Request Body:**
```json
{
  "name": "Pc 2",
  "elapsedTime": 0,
  "isRunning": false,
  "orders": [],
  "reservations": [],
  "notes": "",
  "mode": "single",
  "customerCount": 1
}
```

### Remove Device
**DELETE** `/api/devices/{id}`

---

## 4. Financials & Reports

### Get Daily Summary
**GET** `/api/financials/daily?date=2024-02-04`

**Response:**
```json
{
  "date": "2024-02-04",
  "total_revenue": 150000.0,
  "total_expenses": 20000.0,
  "net_profit": 130000.0,
  "expenses": [
    {
      "id": "exp_1",
      "description": "Electricity",
      "amount": 5000.0,
      "time": "10:00:00"
    }
  ],
  "manual_revenues": [
    {
      "description": "Extra Service",
      "amount": 1000.0
    }
  ]
}
```

### Add Expense
**POST** `/api/financials/expenses`

**Request Body:**
```json
{
  "description": "Cleaning Supplies",
  "amount": 3000.0
}
```

---

## 5. Debts Management

### Get All Debts
**GET** `/api/debts`

**Response:**
```json
[
  {
    "id": "debt_1",
    "customer_name": "John Doe",
    "amount": 5000.0,
    "created_at": "2024-02-01T10:00:00Z",
    "notes": "Pending payment"
  }
]
```

### Add Debt
**POST** `/api/debts`

**Request Body:**
```json
{
  "customer_name": "Jane Smith",
  "amount": 2000.0,
  "notes": "PS4 Session"
}
```

### Update/Settle Debt
**PUT** `/api/debts/{id}`

**Request Body:**
```json
{
  "amount": 0.0, // Fully paid
  "notes": "Paid via Cash"
}
```

---

## 6. Printer Configuration

### Get Printer Settings
**GET** `/api/settings/printers`

**Response:**
```json
{
  "kitchen_printer": {
    "enabled": true,
    "ip": "192.168.1.200",
    "port": 9100
  },
  "receipt_printer": {
    "enabled": true,
    "ip": "192.168.1.201",
    "port": 9100
  }
}
```

### Update Printer Settings
**PUT** `/api/settings/printers`
Updates the printer configuration.

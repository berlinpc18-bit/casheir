# BERLIN GAMING - API Endpoints Specification

**Server Base URL:** `http://192.168.0.135:8080`

**Last Updated:** February 2, 2026

---

## Table of Contents
1. [GET /api/devices](#1-get-apidevices)
2. [GET /api/devices/{id}](#2-get-apidevicesid)
3. [GET /api/devices/{id}/orders](#3-get-apidevicesidorders)
4. [GET /api/reservations](#4-get-apireservations)
5. [GET /api/prices](#5-get-apiprices)
6. [GET /api/categories](#6-get-apicategories)
7. [GET /api/debts](#7-get-apidebts)
8. [GET /api/expenses](#8-get-apiexpenses)
9. [POST /api/order/place](#9-post-apiorderplace)

---

## 1. GET /api/devices
**Description:** Get all gaming devices (PCs, PlayStations, Tables, Billiards)

**HTTP Method:** `GET`

**URL:** `/api/devices`

**Headers:** None required

**Query Parameters:** None

**Response Format:**
```json
{
  "success": true,
  "data": {
    "PC 1": {
      "name": "PC 1",
      "elapsedTime": 0,
      "isRunning": false,
      "orders": [],
      "reservations": [],
      "notes": "",
      "mode": "single",
      "customerCount": 1
    },
    "PC 2": {
      "name": "PC 2",
      "elapsedTime": 3600,
      "isRunning": true,
      "orders": [
        {
          "name": "Coffee",
          "price": 500.0,
          "quantity": 1,
          "firstOrderTime": "2026-02-02T10:00:00Z",
          "lastOrderTime": "2026-02-02T10:05:00Z",
          "notes": "No sugar"
        }
      ],
      "reservations": [],
      "notes": "VIP client",
      "mode": "double",
      "customerCount": 2
    },
    "Arabia 1": {
      "name": "Arabia 1",
      "elapsedTime": 1800,
      "isRunning": true,
      "orders": [],
      "reservations": [],
      "notes": "",
      "mode": "multi",
      "customerCount": 2
    },
    "Table 1": {
      "name": "Table 1",
      "elapsedTime": 0,
      "isRunning": false,
      "orders": [],
      "reservations": [],
      "notes": "",
      "mode": "single",
      "customerCount": 1
    }
  },
  "count": 4,
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**Field Descriptions:**
- `success` (boolean): Whether request succeeded
- `data` (object): Key-value pairs where key is device ID (string) and value is device object
  - `name` (string, required): Device name/identifier
  - `elapsedTime` (integer): Elapsed time in seconds
  - `isRunning` (boolean): Is device currently active
  - `orders` (array): Array of order items (see OrderItem structure)
  - `reservations` (array): Array of reservation items
  - `notes` (string): Additional notes
  - `mode` (string): "single", "double", or "multi"
  - `customerCount` (integer): Number of customers using device
- `count` (integer): Total number of devices
- `timestamp` (string, ISO 8601): Server timestamp

**HTTP Status Codes:**
- `200`: Success
- `500`: Server error

---

## 2. GET /api/devices/{id}
**Description:** Get specific device by ID

**HTTP Method:** `GET`

**URL:** `/api/devices/{id}`

**URL Parameters:**
- `id` (string, required): Device ID (e.g., "PC 1", "Arabia 1")

**Headers:** None required

**Response Format:**
```json
{
  "success": true,
  "data": {
    "name": "PC 1",
    "elapsedTime": 1800,
    "isRunning": true,
    "orders": [
      {
        "name": "Pizza",
        "price": 2500.0,
        "quantity": 2,
        "firstOrderTime": "2026-02-02T09:30:00Z",
        "lastOrderTime": "2026-02-02T09:35:00Z",
        "notes": ""
      }
    ],
    "reservations": [],
    "notes": "Regular customer",
    "mode": "single",
    "customerCount": 1
  },
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**Field Descriptions:** Same as endpoint 1, but returns single device object

**HTTP Status Codes:**
- `200`: Success
- `404`: Device not found
- `500`: Server error

---

## 3. GET /api/devices/{id}/orders
**Description:** Get all orders for specific device

**HTTP Method:** `GET`

**URL:** `/api/devices/{id}/orders`

**URL Parameters:**
- `id` (string, required): Device ID (e.g., "PC 1")

**Headers:** None required

**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "name": "Burger",
      "price": 3000.0,
      "quantity": 1,
      "firstOrderTime": "2026-02-02T10:00:00Z",
      "lastOrderTime": "2026-02-02T10:00:00Z",
      "notes": "Extra cheese"
    },
    {
      "name": "Soda",
      "price": 800.0,
      "quantity": 2,
      "firstOrderTime": "2026-02-02T10:05:00Z",
      "lastOrderTime": "2026-02-02T10:05:00Z",
      "notes": ""
    }
  ],
  "count": 2,
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**OrderItem Structure:**
- `name` (string, required): Item name
- `price` (number, required): Price per item
- `quantity` (integer, required): Number of items
- `firstOrderTime` (string, ISO 8601, required): When item was first ordered
- `lastOrderTime` (string, ISO 8601, required): When item was last ordered
- `notes` (string): Special instructions or notes

**HTTP Status Codes:**
- `200`: Success
- `404`: Device not found
- `500`: Server error

---

## 4. GET /api/reservations
**Description:** Get all reservations

**HTTP Method:** `GET`

**URL:** `/api/reservations`

**Headers:** None required

**Query Parameters:** None

**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "name": "Ahmed",
      "price": 5000.0,
      "quantity": 2,
      "reservationTime": "2026-02-02T14:00:00Z",
      "notes": "VIP table"
    },
    {
      "name": "Sara",
      "price": 3000.0,
      "quantity": 1,
      "reservationTime": "2026-02-02T15:30:00Z",
      "notes": ""
    }
  ],
  "count": 2,
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**ReservationItem Structure:**
- `name` (string, required): Customer name
- `price` (number, required): Reservation price
- `quantity` (integer, required): Number of people or tables
- `reservationTime` (string, ISO 8601, required): Reservation date/time
- `notes` (string): Special notes (VIP, preferences, etc.)

**HTTP Status Codes:**
- `200`: Success
- `500`: Server error

---

## 5. GET /api/prices
**Description:** Get all pricing information

**HTTP Method:** `GET`

**URL:** `/api/prices`

**Headers:** None required

**Query Parameters:** None

**Response Format:**
```json
{
  "success": true,
  "data": {
    "pcPrice": 1500.0,
    "ps4Prices": {
      "Arabia 1": {
        "single": 2000.0,
        "multi": 3000.0
      },
      "Arabia 2": {
        "single": 2000.0,
        "multi": 3000.0
      },
      "Arabia 3": {
        "single": 3000.0,
        "multi": 4000.0
      }
    },
    "pcPrices": {
      "PC 1": 1500.0,
      "PC 2": 2000.0,
      "PC 3": 1500.0
    },
    "tablePrices": {
      "Table 1": 5000.0,
      "Table 2": 5000.0,
      "Table 3": 5000.0
    },
    "billiardPrices": {
      "Billiard 1": 3000.0,
      "Billiard 2": 3000.0
    },
    "orderPrices": {
      "Coffee": 500.0,
      "Tea": 400.0,
      "Burger": 3000.0,
      "Pizza": 2500.0,
      "Sandwich": 2000.0,
      "Soda": 800.0,
      "Water": 300.0
    }
  },
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**Field Descriptions:**
- `pcPrice` (number): Default PC hourly rate
- `ps4Prices` (object): PlayStation prices by device name
  - Each device has `single` (1 player) and `multi` (2+ players) rates
- `pcPrices` (object): Individual PC prices (device name → price)
- `tablePrices` (object): Gaming table prices (device name → price)
- `billiardPrices` (object): Billiard table prices (device name → price)
- `orderPrices` (object): Food/drink prices (item name → price)

**HTTP Status Codes:**
- `200`: Success
- `500`: Server error

---

## 6. GET /api/categories
**Description:** Get food/drink categories and items

**HTTP Method:** `GET`

**URL:** `/api/categories`

**Headers:** None required

**Query Parameters:** None

**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "name": "مطعم",
      "items": [
        "ريزو كلاسك",
        "ريزو اعشاب",
        "بركر كلاسك",
        "بركر جبن",
        "تويستر كلاسك",
        "تويستر هني ماستر"
      ]
    },
    {
      "name": "مشروبات",
      "items": [
        "قهوة",
        "شاي",
        "عصير برتقال",
        "عصير ليمون",
        "سوفت درينك"
      ]
    },
    {
      "name": "موهيتو",
      "items": [
        "موهيتو فراولة",
        "موهيتو ليمون",
        "موهيتو رمان",
        "موهيتو برتقال",
        "موهيتو بلو"
      ]
    },
    {
      "name": "ميلك شيك",
      "items": [
        "ميلك شيك نوتيلا",
        "ميلك شيك اوريو",
        "ميلك شيك لوتس"
      ]
    }
  ],
  "count": 4,
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**Category Structure:**
- `name` (string, required): Category name (can be Arabic)
- `items` (array, required): Array of item names (strings)

**HTTP Status Codes:**
- `200`: Success
- `500`: Server error

---

## 7. GET /api/debts
**Description:** Get all customer debts

**HTTP Method:** `GET`

**URL:** `/api/debts`

**Headers:** None required

**Query Parameters:** None

**Response Format:**
```json
{
  "success": true,
  "data": {
    "Ahmed Salih": 25000.0,
    "Youssef": 10000.0,
    "Moatassem": 9250.0,
    "Ali": 5000.0
  },
  "totalDebt": 49250.0,
  "count": 4,
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**Field Descriptions:**
- `data` (object): Key-value pairs where key is customer name and value is debt amount
- `totalDebt` (number): Sum of all debts
- `count` (integer): Number of customers with debt

**HTTP Status Codes:**
- `200`: Success
- `500`: Server error

---

## 8. GET /api/expenses
**Description:** Get today's expenses

**HTTP Method:** `GET`

**URL:** `/api/expenses`

**Headers:** None required

**Query Parameters:** 
- `date` (optional, string, YYYY-MM-DD): Get expenses for specific date (defaults to today)

**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "type": "علاء",
      "amount": 60000.0,
      "description": "صيانة",
      "date": "2026-02-02T09:00:00Z"
    },
    {
      "type": "الدباغ",
      "amount": 504000.0,
      "description": "راتب",
      "date": "2026-02-02T10:00:00Z"
    },
    {
      "type": "علاء",
      "amount": 240000.0,
      "description": "إصلاح",
      "date": "2026-02-02T14:30:00Z"
    }
  ],
  "totalExpenses": 804000.0,
  "count": 3,
  "timestamp": "2026-02-02T10:15:00Z"
}
```

**Expense Structure:**
- `type` (string, required): Expense category/person name
- `amount` (number, required): Expense amount
- `description` (string): What the expense is for
- `date` (string, ISO 8601, required): When expense occurred

**HTTP Status Codes:**
- `200`: Success
- `500`: Server error

---

## 9. POST /api/order/place
**Description:** Place a new order for a device

**HTTP Method:** `POST`

**URL:** `/api/order/place`

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "PC 1",
  "items": [
    {
      "name": "Coffee",
      "price": 500.0,
      "quantity": 1
    },
    {
      "name": "Burger",
      "price": 3000.0,
      "quantity": 2
    }
  ],
  "notes": "Extra cheese on burger"
}
```

**Request Fields:**
- `deviceId` (string, required): ID of device placing order
- `items` (array, required): Array of items to order
  - `name` (string, required): Item name
  - `price` (number, required): Price per item
  - `quantity` (integer, required): Number of items
- `notes` (string, optional): Special instructions

**Response Format (Success):**
```json
{
  "success": true,
  "data": {
    "orderId": "order_123456789",
    "deviceId": "PC 1",
    "items": [
      {
        "name": "Coffee",
        "price": 500.0,
        "quantity": 1
      },
      {
        "name": "Burger",
        "price": 3000.0,
        "quantity": 2
      }
    ],
    "totalPrice": 6500.0,
    "notes": "Extra cheese on burger",
    "timestamp": "2026-02-02T10:15:00Z"
  },
  "message": "Order placed successfully"
}
```

**Response Format (Error):**
```json
{
  "success": false,
  "message": "Device not found or invalid order data",
  "errors": {
    "deviceId": "Device PC 1 not found"
  }
}
```

**HTTP Status Codes:**
- `200` or `201`: Order placed successfully
- `400`: Invalid request data
- `404`: Device not found
- `500`: Server error

---

## Data Type Reference

| Type | Format | Example |
|------|--------|---------|
| String | Text | `"PC 1"`, `"Coffee"` |
| Number | Float/Int | `1500.0`, `1500` |
| Integer | Whole number | `1`, `2`, `3` |
| Boolean | true/false | `true`, `false` |
| ISO 8601 Timestamp | UTC datetime | `"2026-02-02T10:15:00Z"` |
| Array | JSON array | `[1, 2, 3]`, `[{...}, {...}]` |
| Object | JSON object | `{"key": "value"}` |

---

## Error Handling

All endpoints should return appropriate HTTP status codes:
- `200`: Successful GET request
- `201`: Successful POST request
- `400`: Invalid request data
- `404`: Resource not found
- `500`: Internal server error

Error responses should follow this format:
```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": "error_code_optional"
}
```

---

## Notes for Server Developer

1. All timestamps must be in **ISO 8601 format** with **Z suffix** (UTC timezone)
2. All monetary values should be **numbers** (float or int)
3. Device names should be **consistent** across all endpoints
4. The `data` field structure varies:
   - `/api/devices` returns **object** (key-value pairs)
   - `/api/devices/{id}` returns **single object**
   - `/api/devices/{id}/orders` returns **array**
   - `/api/reservations` returns **array**
   - `/api/prices` returns **object**
   - `/api/categories` returns **array of objects**
   - `/api/debts` returns **object**
   - `/api/expenses` returns **array**
5. All GET requests should support **CORS headers**
6. Response time should be **under 5 seconds**

---

**Generated:** February 2, 2026
**Version:** 1.0

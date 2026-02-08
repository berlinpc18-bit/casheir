# Backend WebSocket Integration Guide: Remote Printing

This guide details the WebSocket event required to trigger a remote print job on the Cashier system. This functionality is restricted to the `super_admin` user.

## 1. Event Type
The Cashier application listens for a WebSocket message with the type: **`print_order`**.

## 2. JSON Payload Structure

When an order needs to be printed from an external app (Android/Web), send the following JSON payload to the specific Cashier client via the WebSocket server.

```json
{
  "type": "print_order",
  "deviceId": "Table 5",        // Or "tableName": "Table 5"
  "orders": [
    {
      "name": "Tea",
      "quantity": 2,
      "price": 500,
      "notes": "No Sugar"       // Optional
    },
    {
      "name": "Burger",
      "quantity": 1,
      "price": 5000,
      "notes": "Extra Cheese"
    }
  ]
}
```

## 3. Field Descriptions

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `type` | String | **Yes** | Must be exactly `"print_order"`. |
| `deviceId` | String | **Yes** | Identifier for the source table or device (e.g., "Table 1", "Android App"). Used as the header on the receipt. |
| `orders` | Array | **Yes** | List of items to print. |
| `orders[].name` | String | **Yes** | Name of the product (must match names in Cashier to be routed correctly). |
| `orders[].quantity` | Integer | **Yes** | Quantity of the item. |
| `orders[].price` | Number | **Yes** | Unit price of the item. |
| `orders[].notes` | String | No | Kitchen notes or special requests. |

## 4. How it Works
1.  **Authentication Check**: The Cashier app receiving this message will **strictly** check if the currently logged-in user is `super_admin`. If not, the print job is ignored.
2.  **Category Routing**: The app will look up the `name` of each item in its local settings.
    *   If "Burger" is mapped to "Kitchen", it sends the print job to the Kitchen Printer IP.
    *   If "Tea" is mapped to "Barista", it sends it to the Barista Printer IP.

## 5. Implementation Note for Backend
Ensure your WebSocket server broadcasts this message efficiently. Since the Cashier is a connected client, you can target it by its `clientId` if known, or broadcast to all "admin-type" clients associated with the restaurant.

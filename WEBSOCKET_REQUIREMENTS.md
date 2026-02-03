# WebSocket Real-Time Sync Requirements

## Overview
Implement WebSocket server to enable real-time bidirectional communication between the cashier application and server. This will replace polling and enable instant updates across all connected clients.

## Technology Stack
- **Protocol**: WebSocket (ws:// for development, wss:// for production)
- **Port**: 8080 (same as HTTP server, upgrade connection)
- **Library Recommendation**: `ws` (Node.js), `socket.io`, or native WebSocket implementation

## Connection

### Endpoint
```
ws://localhost:8080/ws
```

### Connection Flow
1. Client connects to WebSocket endpoint
2. Server accepts connection and stores client reference
3. Client sends authentication/identification message (optional for now)
4. Server confirms connection
5. Bidirectional communication begins

### Connection Message (Client → Server)
```json
{
  "type": "connect",
  "clientId": "cashier-client-1",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### Connection Acknowledgment (Server → Client)
```json
{
  "type": "connected",
  "success": true,
  "message": "Connected to server",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

## Event Types

### 1. Device Status Update
**When**: Device timer starts/stops, mode changes, customer count changes, notes change
**Direction**: Bidirectional (Client ↔ Server)

**Client → Server** (when local change happens):
```json
{
  "type": "device_update",
  "deviceId": "pc1",
  "data": {
    "isRunning": true,
    "elapsedSeconds": 3600,
    "mode": "single",
    "customerCount": 2,
    "notes": "VIP customer"
  },
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients** (broadcast to all connected clients):
```json
{
  "type": "device_updated",
  "deviceId": "pc1",
  "data": {
    "isRunning": true,
    "elapsedSeconds": 3600,
    "mode": "single",
    "customerCount": 2,
    "notes": "VIP customer"
  },
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 2. Order Placed
**When**: New order is added to a device
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "order_placed",
  "deviceId": "pc1",
  "orders": [
    {
      "name": "كولا",
      "price": 1000,
      "quantity": 2,
      "notes": "بارد",
      "firstOrderTime": "2026-02-03T02:25:33+03:00",
      "lastOrderTime": "2026-02-03T02:25:33+03:00"
    }
  ],
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients**:
```json
{
  "type": "order_added",
  "deviceId": "pc1",
  "orders": [
    {
      "name": "كولا",
      "price": 1000,
      "quantity": 2,
      "notes": "بارد",
      "firstOrderTime": "2026-02-03T02:25:33+03:00",
      "lastOrderTime": "2026-02-03T02:25:33+03:00"
    }
  ],
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 3. Order Updated
**When**: Order quantity/price/notes are modified
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "order_updated",
  "deviceId": "pc1",
  "orderIndex": 0,
  "data": {
    "name": "كولا",
    "price": 1000,
    "quantity": 3,
    "notes": "بارد جداً",
    "lastOrderTime": "2026-02-03T02:25:33+03:00"
  },
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients**:
```json
{
  "type": "order_modified",
  "deviceId": "pc1",
  "orderIndex": 0,
  "data": {
    "name": "كولا",
    "price": 1000,
    "quantity": 3,
    "notes": "بارد جداً",
    "lastOrderTime": "2026-02-03T02:25:33+03:00"
  },
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 4. Order Deleted
**When**: Order is removed from device
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "order_deleted",
  "deviceId": "pc1",
  "orderIndex": 0,
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients**:
```json
{
  "type": "order_removed",
  "deviceId": "pc1",
  "orderIndex": 0,
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 5. Device Transfer
**When**: Device data is transferred from one device to another
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "device_transfer",
  "fromDeviceId": "pc1",
  "toDeviceId": "pc5",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients**:
```json
{
  "type": "device_transferred",
  "fromDeviceId": "pc1",
  "toDeviceId": "pc5",
  "message": "Device data transferred from pc1 to pc5",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 6. Device Created
**When**: New device is added to the system
**Direction**: Server → Clients

**Server → All Clients**:
```json
{
  "type": "device_created",
  "deviceId": "pc10",
  "data": {
    "name": "pc10",
    "isRunning": false,
    "elapsedSeconds": 0,
    "mode": "single",
    "customerCount": 1,
    "notes": "",
    "orders": []
  },
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 7. Device Deleted
**When**: Device is removed from the system
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "device_deleted",
  "deviceId": "pc1",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients**:
```json
{
  "type": "device_removed",
  "deviceId": "pc1",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 8. Device Reset
**When**: Device is reset (timer cleared, orders removed, but device remains)
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "device_reset",
  "deviceId": "pc1",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → All Clients**:
```json
{
  "type": "device_cleared",
  "deviceId": "pc1",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 9. Categories/Prices Update
**When**: Product categories or prices are updated
**Direction**: Server → Clients (admin action)

**Server → All Clients**:
```json
{
  "type": "categories_updated",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

```json
{
  "type": "prices_updated",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 10. Heartbeat/Ping-Pong
**When**: Every 30 seconds to keep connection alive
**Direction**: Bidirectional

**Client → Server**:
```json
{
  "type": "ping",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

**Server → Client**:
```json
{
  "type": "pong",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

## Server Implementation Requirements

### 1. Connection Management
- Maintain list of all connected clients
- Handle client disconnection gracefully
- Support reconnection with state recovery
- Implement connection timeout (5 minutes of inactivity)

### 2. Broadcasting
- When server receives an event from one client, broadcast to ALL other connected clients
- Do NOT send the event back to the originating client (they already have the update)
- Include timestamp in all broadcasts

### 3. Data Persistence
- All WebSocket events should ALSO update the database
- WebSocket is for real-time sync, database is source of truth
- If WebSocket fails, REST API should still work

### 4. Error Handling
**Server → Client** (when error occurs):
```json
{
  "type": "error",
  "code": "DEVICE_NOT_FOUND",
  "message": "Device pc1 does not exist",
  "timestamp": "2026-02-03T02:25:33+03:00"
}
```

### 5. Event Flow Example
1. Client A updates device PC1 timer
2. Client A sends `device_update` via WebSocket
3. Server receives message
4. Server updates database
5. Server broadcasts `device_updated` to Client B, Client C, etc. (NOT back to Client A)
6. Clients B and C update their UI immediately

## Client-Side Implementation (Will be done by Flutter team)

### Connection
- Connect to WebSocket on app startup
- Reconnect automatically on disconnect
- Show connection status in UI

### Event Handling
- Listen for all event types
- Update local state when receiving events
- Send events when local changes occur
- Implement optimistic updates (update UI immediately, rollback if server rejects)

### Conflict Resolution
- Use timestamps to determine which update is newer
- Server timestamp is source of truth
- If local change conflicts with server, server wins

## Testing Checklist

### Backend Team Should Test:
- [ ] Multiple clients can connect simultaneously
- [ ] Events broadcast to all clients except sender
- [ ] Connection survives network interruptions
- [ ] Database updates correctly on all events
- [ ] Error messages are sent for invalid events
- [ ] Heartbeat keeps connection alive
- [ ] Disconnected clients are cleaned up
- [ ] All event types work correctly
- [ ] Timestamps are in ISO 8601 format
- [ ] Arabic text (UTF-8) is handled correctly

## Performance Considerations
- Maximum 100 concurrent connections (can increase if needed)
- Message size limit: 1MB per message
- Broadcast latency: < 100ms
- Connection timeout: 5 minutes of inactivity

## Security (Future Enhancement)
- Add authentication token in connection message
- Validate client permissions for each action
- Rate limiting to prevent spam
- SSL/TLS for production (wss://)

## Example Server Pseudo-Code

```javascript
// WebSocket server setup
const wss = new WebSocketServer({ port: 8080, path: '/ws' });

// Store connected clients
const clients = new Set();

wss.on('connection', (ws) => {
  clients.add(ws);
  
  ws.on('message', async (message) => {
    const data = JSON.parse(message);
    
    // Update database based on event type
    await handleEvent(data);
    
    // Broadcast to all OTHER clients
    broadcast(data, ws);
  });
  
  ws.on('close', () => {
    clients.delete(ws);
  });
});

function broadcast(data, sender) {
  clients.forEach(client => {
    if (client !== sender && client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
}
```

## Timeline
- **Phase 1**: Basic connection and device updates (1-2 days)
- **Phase 2**: Order events (1 day)
- **Phase 3**: Transfer, delete, reset events (1 day)
- **Phase 4**: Testing and optimization (1 day)

## Questions for Backend Team
1. Which WebSocket library will you use?
2. Will WebSocket run on same port (8080) or different port?
3. Do you need authentication now or later?
4. What's your preferred error handling format?

---

**Note**: Once backend implementation is complete, notify the Flutter team to begin client-side integration.

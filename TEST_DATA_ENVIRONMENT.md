# Testing Environment Setup - Isolated Test Data

## Overview
Create separate test data environments without affecting production data.

---

## 1. Create Test Configuration File

**File:** `lib/test_config.dart`

```dart
class TestConfig {
  static const bool isTestMode = true;  // Toggle for testing
  static const String testBoxName = 'test_safeDevicesBox';
  static const String productionBoxName = 'safeDevicesBox';
  
  // Test API Settings
  static const int testApiPort = 5558;  // Different from production (5557)
  static const String testApiHost = 'localhost';
  
  // Test Mode Indicators
  static const bool enableTestLogging = true;
  static const bool useTestDatabase = true;
}
```

---

## 2. Modify AppState to Support Test Mode

**File:** `lib/app_state.dart` - Modify the `_getBox()` method (Lines 1179-1235)

```dart
static Future<Box> _getBox() async {
  // Add test mode check
  final useTestBox = TestConfig.useTestDatabase;
  final boxName = useTestBox ? TestConfig.testBoxName : TestConfig.productionBoxName;
  
  if (_isStaticSaving) {
    await Future.delayed(const Duration(milliseconds: 100));
    return _getBox();
  }
  
  try {
    if (_sharedBox != null && _sharedBox!.isOpen) {
      print('✓ Using ${useTestBox ? 'TEST' : 'PRODUCTION'} box: ${_sharedBox!.name}');
      return _sharedBox!;
    }
    
    if (_sharedBox != null && _sharedBox!.isOpen) {
      await _sharedBox!.close();
      print('Closed previous box');
    }
    
    // Use dynamic box name based on test mode
    print('Opening ${useTestBox ? 'TEST' : 'PRODUCTION'} box: $boxName...');
    _sharedBox = await Hive.openBox(boxName);
    _isBoxInitialized = true;
    print('✅ Successfully opened $boxName (${useTestBox ? 'TEST MODE' : 'PRODUCTION'})');
    return _sharedBox!;
    
  } catch (e) {
    print('Error opening box: $e');
    // ... rest of error handling
  }
}
```

---

## 3. Add Test Data Initialization

**File:** `lib/app_state.dart` - Add new method after `_ensureDefaultDevices()`

```dart
/// Initialize test data for external API testing
Future<void> initializeTestData() async {
  if (!TestConfig.useTestDatabase) {
    print('⚠️ Test data initialization ignored - not in test mode');
    return;
  }
  
  print('🧪 Initializing TEST DATA...');
  
  // Clear existing test data
  _devices.clear();
  _allReservations.clear();
  _orderPrices.clear();
  
  // Create test devices
  _createTestDevices();
  
  // Create test prices
  _createTestPrices();
  
  // Create test categories
  _createTestCategories();
  
  // Save to test database
  await _saveToPrefs();
  notifyListeners();
  
  print('✅ Test data initialized successfully');
}

void _createTestDevices() {
  // Test PC Device
  final testPc = DeviceData(
    name: 'TEST_Pc_1',
    isRunning: true,
    elapsedTime: const Duration(hours: 2, minutes: 30),
    mode: 'single',
    customerCount: 1,
  );
  testPc.orders.addAll([
    OrderItem(
      name: 'Test Item 1',
      price: 10.0,
      quantity: 2,
      firstOrderTime: DateTime.now().subtract(const Duration(minutes: 30)),
      lastOrderTime: DateTime.now().subtract(const Duration(minutes: 30)),
      notes: 'Test order',
    ),
    OrderItem(
      name: 'Test Item 2',
      price: 15.0,
      quantity: 1,
      firstOrderTime: DateTime.now().subtract(const Duration(minutes: 15)),
      lastOrderTime: DateTime.now().subtract(const Duration(minutes: 15)),
      notes: 'Another test',
    ),
  ]);
  _devices['TEST_Pc_1'] = testPc;
  
  // Test PS4 Device
  final testPs4 = DeviceData(
    name: 'TEST_Arabia_1',
    isRunning: false,
    mode: 'multi',
    customerCount: 2,
  );
  testPs4.orders.addAll([
    OrderItem(
      name: 'Gaming Item',
      price: 25.0,
      quantity: 1,
      firstOrderTime: DateTime.now().subtract(const Duration(hours: 1)),
      lastOrderTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ]);
  _devices['TEST_Arabia_1'] = testPs4;
  
  // Test Table Device
  final testTable = DeviceData(
    name: 'TEST_Table_1',
    isRunning: true,
    mode: 'single',
  );
  _devices['TEST_Table_1'] = testTable;
  
  print('Created 3 test devices');
}

void _createTestPrices() {
  // Test device prices
  _pcPrices['TEST_Pc_1'] = 1000.0;
  _tablePrices['TEST_Table_1'] = 500.0;
  _ps4Prices['TEST_Arabia_1'] = {'single': 1500.0, 'multi': 2000.0};
  
  // Test menu items
  _orderPrices['Test Item 1'] = 10.0;
  _orderPrices['Test Item 2'] = 15.0;
  _orderPrices['Gaming Item'] = 25.0;
  _orderPrices['Snack'] = 5.0;
  _orderPrices['Drink'] = 3.0;
  
  print('Created test prices for ${_orderPrices.length} items');
}

void _createTestCategories() {
  _customCategories['Test Category 1'] = ['Test Item 1', 'Test Item 2'];
  _customCategories['Test Category 2'] = ['Gaming Item', 'Snack'];
  _customCategories['Beverages'] = ['Drink'];
  
  print('Created ${_customCategories.length} test categories');
}

/// Clear all test data and restore production database
Future<void> clearTestData() async {
  if (!TestConfig.useTestDatabase) {
    print('⚠️ Not in test mode - cannot clear test data');
    return;
  }
  
  print('🧹 Clearing test data...');
  
  // Close current test box
  if (_sharedBox != null && _sharedBox!.isOpen) {
    try {
      // Get reference to test box
      final testBox = _sharedBox!;
      
      // Delete all keys from test box
      await testBox.deleteFromDisk();
      
      // Reset box reference
      _sharedBox = null;
      _isBoxInitialized = false;
      
      print('✅ Test database cleared');
    } catch (e) {
      print('Error clearing test data: $e');
    }
  }
}
```

---

## 4. Create Test API Server

**File:** `lib/test_api_server.dart`

```dart
import 'dart:io';
import 'dart:convert';
import 'app_state.dart';
import 'test_config.dart';

class TestApiServer {
  static final TestApiServer _instance = TestApiServer._internal();
  
  factory TestApiServer() => _instance;
  
  TestApiServer._internal();
  
  ServerSocket? _server;
  late AppState _appState;
  
  Future<void> startTestServer(AppState appState) async {
    _appState = appState;
    
    if (!TestConfig.useTestDatabase) {
      print('⚠️ Test API Server not started - not in test mode');
      return;
    }
    
    try {
      _server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        TestConfig.testApiPort,
      );
      
      print('🧪 TEST API Server started on port ${TestConfig.testApiPort}');
      
      _server!.listen((socket) {
        _handleTestConnection(socket);
      });
      
    } catch (e) {
      print('Error starting test API server: $e');
    }
  }
  
  void _handleTestConnection(Socket socket) {
    print('🔗 Test client connected');
    
    socket.listen(
      (data) {
        _handleTestRequest(socket, String.fromCharCodes(data));
      },
      onError: (error) {
        print('Test connection error: $error');
      },
      onDone: () {
        print('Test client disconnected');
        socket.close();
      },
    );
  }
  
  void _handleTestRequest(Socket socket, String request) {
    try {
      final json = jsonDecode(request);
      
      if (json['action'] == 'GET_TEST_DEVICES') {
        _sendTestDevices(socket);
      } else if (json['action'] == 'GET_TEST_PRICES') {
        _sendTestPrices(socket);
      } else if (json['action'] == 'PLACE_TEST_ORDER') {
        _handleTestOrder(socket, json);
      } else if (json['action'] == 'GET_TEST_STATUS') {
        _sendTestStatus(socket);
      }
    } catch (e) {
      print('Test request error: $e');
      _sendError(socket, 'Invalid test request');
    }
  }
  
  void _sendTestDevices(Socket socket) {
    final devices = _appState.devices;
    final response = {
      'success': true,
      'data': devices.map((k, v) => MapEntry(k, v.toJson())),
      'timestamp': DateTime.now().toIso8601String(),
    };
    socket.write(jsonEncode(response));
  }
  
  void _sendTestPrices(Socket socket) {
    final response = {
      'success': true,
      'prices': _appState.orderPrices,
      'ps4Prices': _appState.ps4Prices,
      'timestamp': DateTime.now().toIso8601String(),
    };
    socket.write(jsonEncode(response));
  }
  
  void _handleTestOrder(Socket socket, Map<String, dynamic> request) {
    try {
      final deviceId = request['deviceId'] as String;
      final items = request['items'] as List;
      
      final device = _appState.devices[deviceId];
      if (device == null) {
        _sendError(socket, 'Device not found: $deviceId');
        return;
      }
      
      // Add test order
      for (final item in items) {
        device.orders.add(
          OrderItem(
            name: item['name'],
            price: item['price'],
            quantity: item['quantity'],
            firstOrderTime: DateTime.now(),
            lastOrderTime: DateTime.now(),
            notes: '[TEST] ${item['notes'] ?? ''}',
          ),
        );
      }
      
      final response = {
        'success': true,
        'message': 'Test order placed successfully',
        'orderId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().toIso8601String(),
      };
      socket.write(jsonEncode(response));
      
      print('✅ Test order placed on device: $deviceId');
      
    } catch (e) {
      _sendError(socket, 'Test order error: $e');
    }
  }
  
  void _sendTestStatus(Socket socket) {
    final response = {
      'success': true,
      'testMode': TestConfig.useTestDatabase,
      'port': TestConfig.testApiPort,
      'deviceCount': _appState.devices.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
    socket.write(jsonEncode(response));
  }
  
  void _sendError(Socket socket, String error) {
    final response = {'success': false, 'error': error};
    socket.write(jsonEncode(response));
  }
  
  Future<void> stopTestServer() async {
    if (_server != null) {
      await _server!.close();
      print('🛑 Test API Server stopped');
    }
  }
}
```

---

## 5. Add Test Button to UI

**File:** `lib/main.dart` - Add to appropriate screen (e.g., Settings)

```dart
// Add this widget to your settings/debug screen
if (TestConfig.useTestDatabase) {
  FloatingActionButton(
    onPressed: () => _showTestMenu(context),
    backgroundColor: Colors.orange,
    child: const Text('TEST'),
    tooltip: 'Test Mode Controls',
  );
}

void _showTestMenu(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('🧪 Test Mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Database: ${TestConfig.testBoxName}'),
          Text('Port: ${TestConfig.testApiPort}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.initializeTestData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Test data initialized')),
              );
            },
            child: const Text('Initialize Test Data'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.clearTestData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Test data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Test Data'),
          ),
        ],
      ),
    ),
  );
}
```

---

## 6. Quick Reference Table

| Setting | Test Mode | Production |
|---------|-----------|------------|
| Database | `test_safeDevicesBox` | `safeDevicesBox` |
| API Port | 5558 | 5557 |
| Host | localhost | LAN IP |
| Data Isolation | ✅ Separate | Production |
| Device Prefix | TEST_* | Normal |
| Logging | Verbose | Normal |

---

## 7. How to Use

### Step 1: Enable Test Mode
```dart
// In test_config.dart
static const bool useTestDatabase = true;
static const bool isTestMode = true;
```

### Step 2: Initialize App with Test Data
```dart
// After app starts
final appState = Provider.of<AppState>(context, listen: false);
await appState.initializeTestData();
```

### Step 3: Start Test API Server
```dart
// In main.dart after initialization
if (TestConfig.useTestDatabase) {
  TestApiServer().startTestServer(appState);
}
```

### Step 4: Test External App Connection
```
Connect to: localhost:5558
Send requests to test API
Test devices will have TEST_ prefix
```

### Step 5: Clean Up
```dart
// Clear test data when done
await appState.clearTestData();
```

---

## 8. Test Data Verification

Check test data was created:

```dart
print('Test Devices: ${appState.devices.keys.toList()}');
// Output: [TEST_Pc_1, TEST_Arabia_1, TEST_Table_1]

print('Test Prices: ${appState.orderPrices.length}');
// Output: 5

print('Test Categories: ${appState.customCategories.length}');
// Output: 3
```

---

## 9. Switching Between Modes

### Enable Test Mode:
```dart
// test_config.dart
static const bool useTestDatabase = true;
```

### Enable Production:
```dart
// test_config.dart
static const bool useTestDatabase = false;
```

**Note:** Restart app after changing mode to switch databases.

---

## 10. Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/test_config.dart` | CREATE | Test mode configuration |
| `lib/test_api_server.dart` | CREATE | Test API server |
| `lib/app_state.dart` | MODIFY | Add test methods |
| `lib/main.dart` | MODIFY | Initialize test server |
| Settings Screen | MODIFY | Add test controls |

---

## Benefits

✅ **Data Isolation** - Test data separate from production  
✅ **Easy Switching** - Toggle between test/production modes  
✅ **Safe Testing** - No risk to production data  
✅ **Realistic Data** - Pre-populated test devices & orders  
✅ **API Testing** - Dedicated test API port  
✅ **Easy Cleanup** - Clear test data with one click  

---

**Last Updated:** February 2, 2026
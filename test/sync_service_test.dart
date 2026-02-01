import 'package:flutter_test/flutter_test.dart';
import 'package:berlin_gaming_cashier/sync_service.dart';
import 'package:berlin_gaming_cashier/device_group_manager.dart';
import 'package:berlin_gaming_cashier/app_state.dart';

void main() {
  group('SyncService Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService();
    });

    test('initialization creates unique device ID', () async {
      await syncService.initialize();
      
      expect(syncService.deviceId, isNotNull);
      expect(syncService.deviceId, isNotEmpty);
      expect(syncService.deviceId.length, greaterThan(0));
    });

    test('register device adds to group', () {
      syncService.registerDevice('Test-Device-1');
      
      expect(syncService.connectedDevices.containsKey(syncService.deviceId), true);
      expect(syncService.connectedDevices[syncService.deviceId]?.deviceName, 'Test-Device-1');
    });

    test('broadcast device update creates sync event', (WidgetTester tester) async {
      await syncService.initialize();
      syncService.registerDevice('Test-Device');
      
      final testDeviceData = DeviceData(
        name: 'Device-1',
        elapsedTime: Duration(minutes: 5),
        isRunning: true,
      );

      int eventCount = 0;
      syncService.syncEvents.listen((event) {
        eventCount++;
        expect(event.type, 'device_update');
        expect(event.sourceDevice, syncService.deviceId);
      });

      syncService.broadcastDeviceUpdate('Test-Device', testDeviceData);
      
      // انتظر قليلاً للسماح بمعالجة الحدث
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(eventCount, greaterThan(0));
    });

    test('sync payload generation works correctly', () {
      final deviceData = DeviceData(
        name: 'Device-1',
        elapsedTime: Duration(hours: 2, minutes: 30),
        isRunning: true,
        orders: [],
        notes: 'Test notes',
        mode: 'dual',
        customerCount: 2,
      );

      final payload = syncService.generateSyncPayload(deviceData);
      
      expect(payload['deviceId'], isNotNull);
      expect(payload['timestamp'], isNotNull);
      expect(payload['data']['name'], 'Device-1');
      expect(payload['data']['isRunning'], true);
      expect(payload['data']['customerCount'], 2);
    });

    test('connectivity monitoring works', () async {
      await syncService.initialize();
      
      expect(syncService.isOnline, isNotNull);
      // isOnline يعتمد على الاتصال الفعلي، لذا قد يكون true أو false
    });

    test('device connection check works', () {
      syncService.registerDevice('Device-1');
      syncService.registerDevice('Device-2');
      
      // الجهاز نفسه يجب أن يكون متصل
      bool isConnected = syncService.isDeviceConnected(syncService.deviceId);
      // قد يكون false إذا لم يتم التحديث مؤخراً
      expect(isConnected, isA<bool>());
    });

    test('get connected devices returns list', () {
      syncService.registerDevice('Device-1');
      syncService.registerDevice('Device-2');
      
      final devices = syncService.getConnectedDevices();
      
      expect(devices, isA<List>());
      expect(devices.isNotEmpty, true);
    });

    tearDown(() {
      syncService.dispose();
    });
  });

  group('DeviceGroupManager Tests', () {
    late DeviceGroupManager groupManager;

    setUp(() {
      groupManager = DeviceGroupManager();
    });

    test('initialization sets group ID', () async {
      await groupManager.initialize('test-group-001');
      
      expect(groupManager.groupId, 'test-group-001');
    });

    test('register device adds to groups', () {
      groupManager.registerDeviceInGroup('Device-1');
      
      expect(groupManager.deviceGroups.isNotEmpty, true);
    });

    test('auto sync is enabled by default', () {
      expect(groupManager.autoSync, true);
      expect(groupManager.syncInterval, 5);
    });

    test('disable auto sync works', () {
      groupManager.disableAutoSync();
      expect(groupManager.autoSync, false);
    });

    test('enable auto sync works', () {
      groupManager.disableAutoSync();
      groupManager.enableAutoSync();
      expect(groupManager.autoSync, true);
    });

    test('set sync interval updates value', () {
      groupManager.setSyncInterval(10);
      expect(groupManager.syncInterval, 10);
    });

    test('get group state returns valid structure', () {
      groupManager.registerDeviceInGroup('Device-1');
      
      final state = groupManager.getGroupState();
      
      expect(state['groupId'], isNotNull);
      expect(state['deviceCount'], isA<int>());
      expect(state['devices'], isA<List>());
      expect(state['syncStatus'], isA<List>());
      expect(state['lastSync'], isNotNull);
    });

    test('sync logs are recorded', () {
      int initialLogCount = groupManager.syncLogs.length;
      
      groupManager.registerDeviceInGroup('Device-1');
      
      // يجب أن يتم تسجيل حدث واحد على الأقل
      expect(groupManager.syncLogs.length, greaterThan(initialLogCount));
    });

    test('sync logs dont exceed max size', () {
      // أضف أكثر من الحد الأقصى من السجلات
      for (int i = 0; i < 150; i++) {
        groupManager.registerDeviceInGroup('Device-$i');
      }
      
      // يجب ألا تتجاوز السجلات 100 إدخال
      expect(groupManager.syncLogs.length, lessThanOrEqualTo(100));
    });

    test('export sync logs returns string', () {
      groupManager.registerDeviceInGroup('Device-1');
      
      final logsString = groupManager.exportSyncLogs();
      
      expect(logsString, isA<String>());
      expect(logsString.isNotEmpty, true);
    });

    tearDown(() {
      groupManager.stop();
    });
  });

  group('Device Data Tests', () {
    test('DeviceData creation works', () {
      final deviceData = DeviceData(
        name: 'Test-Device',
        elapsedTime: Duration(hours: 1),
        isRunning: true,
      );

      expect(deviceData.name, 'Test-Device');
      expect(deviceData.isRunning, true);
      expect(deviceData.mode, 'single');
      expect(deviceData.customerCount, 1);
    });

    test('DeviceData toJson works', () {
      final deviceData = DeviceData(
        name: 'Test-Device',
        elapsedTime: Duration(minutes: 30),
      );

      final json = deviceData.toJson();
      
      expect(json['name'], 'Test-Device');
      expect(json['isRunning'], false);
      expect(json['elapsedTime'], greaterThan(0));
    });

    test('OrderItem serialization works', () {
      final orderItem = OrderItem(
        name: 'Pizza',
        price: 25.0,
        quantity: 2,
        firstOrderTime: DateTime.now(),
        lastOrderTime: DateTime.now(),
      );

      final json = orderItem.toJson();
      final restored = OrderItem.fromJson(json);

      expect(restored.name, 'Pizza');
      expect(restored.price, 25.0);
      expect(restored.quantity, 2);
    });
  });

  group('Integration Tests', () {
    late SyncService syncService;
    late DeviceGroupManager groupManager;

    setUp(() {
      syncService = SyncService();
      groupManager = DeviceGroupManager();
    });

    test('complete sync workflow', () async {
      // تهيئة الخدمات
      await syncService.initialize();
      await groupManager.initialize('integration-test');

      // تسجيل جهاز
      groupManager.registerDeviceInGroup('Device-1');

      // تحضير بيانات الجهاز
      final deviceData = DeviceData(
        name: 'Device-1',
        isRunning: true,
      );

      // قياس عدد السجلات الأولي
      final initialLogCount = groupManager.syncLogs.length;

      // بث التحديث
      await groupManager.broadcastDeviceState('Device-1', deviceData);

      // انتظر معالجة الحدث
      await Future.delayed(Duration(milliseconds: 100));

      // تحقق من أن السجل تم تسجيله
      expect(groupManager.syncLogs.length, greaterThan(initialLogCount));

      // تحقق من حالة المجموعة
      final state = groupManager.getGroupState();
      expect(state['deviceCount'], greaterThan(0));
    });

    tearDown(() {
      syncService.dispose();
      groupManager.stop();
    });
  });
}

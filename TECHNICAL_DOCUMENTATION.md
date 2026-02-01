# التوثيق التقني المتقدم

## معمارية النظام

### الطبقات (Layers)

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│   (device_group_screen.dart)        │
│  - واجهات مستخدم                   │
│  - أحداث المستخدم                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Application Layer                │
│ (device_group_manager.dart)         │
│  - منطق التطبيق                    │
│  - تنسيق الخدمات                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Service Layer                    │
│  - sync_service.dart                │
│  - local_network_sync_service.dart  │
│  - إدارة الحالة                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Infrastructure Layer             │
│  - UDP/Network Communication        │
│  - File Storage (Hive)              │
│  - Device APIs                      │
└─────────────────────────────────────┘
```

---

## مسار البيانات (Data Flow)

### حالة النشاط العادية

```
User Action (تغيير على جهاز)
    ↓
GroupManager.broadcastDeviceState()
    ↓
SyncService.generateSyncPayload()
    ↓
LocalNetworkSyncService.broadcastSyncUpdate()
    ↓
UDP Send على المنفذ 5556
    ↓
الأجهزة الأخرى تستقبل البيانات
    ↓
LocalNetworkSyncService._handleSyncMessage()
    ↓
SyncService.receiveDeviceUpdate()
    ↓
GroupManager updates state
    ↓
UI تحديث تلقائي (Consumer)
    ↓
شاشة المستخدم تتحدث ✓
```

---

## دورة الحياة (Lifecycle)

### Initialization Phase
```
1. Flutter app starts
2. DeviceGroupManager created
3. SyncService initialized
   - Generate unique device ID
   - Setup connectivity monitoring
4. LocalNetworkSyncService initialized
   - Open UDP sockets
   - Start listening on port 5556
   - Start discovery broadcast
5. UI ready to use
```

### Running Phase
```
1. Discovery broadcast every 10s
2. Devices discovered automatically
3. Auto sync every 5s (default)
4. User interactions broadcast
5. Sync logs recorded
6. UI updates via Consumer
```

### Shutdown Phase
```
1. Dispose listeners
2. Stop timers
3. Close UDP sockets
4. Save state
5. Cleanup resources
```

---

## التواصل عبر الشبكة

### بروتوكول الاكتشاف

**المنفذ:** 5555
**البروتوكول:** UDP
**الفترة:** كل 10 ثواني

**رسالة الاكتشاف:**
```json
{
  "type": "discovery",
  "deviceId": "uuid-xxx-xxx",
  "deviceName": "Device-xxx",
  "port": 5556,
  "timestamp": "2026-01-22T10:30:00Z"
}
```

### بروتوكول المزامنة

**المنفذ:** 5556
**البروتوكول:** UDP
**الحجم الأقصى:** 64 KB

**رسالة التحديث:**
```json
{
  "type": "sync",
  "sourceDeviceId": "uuid-xxx-xxx",
  "payload": {
    "deviceId": "uuid-xxx-xxx",
    "timestamp": "2026-01-22T10:30:00Z",
    "data": {
      "name": "Device-1",
      "elapsedTime": 300,
      "isRunning": true,
      "orders": [...],
      "reservations": [...],
      "notes": "...",
      "mode": "single",
      "customerCount": 1
    }
  }
}
```

---

## معالجة الأخطاء

### أنواع الأخطاء

```
Network Errors
├── Connection Lost
│   └── Auto-retry with exponential backoff
├── Timeout
│   └── Mark device as offline
└── Invalid Data
    └── Log and ignore

Port Errors
├── Already in Use
│   └── Retry with different port
└── Permission Denied
    └── Log error and disable feature

Sync Errors
├── Device Not Found
│   └── Remove from connected list
├── Invalid Payload
│   └── Log and skip
└── Sync Timeout
    └── Retry or mark failed
```

### معالجة Exceptions

```dart
// في LocalNetworkSyncService
try {
  await _udpBroadcaster.send(...);
} catch (e) {
  if (e.toString().contains('already in use')) {
    // Port binding failed
    _addSyncLog('Port error', _syncService.deviceId);
  } else if (e.toString().contains('timeout')) {
    // Network timeout
    _addSyncLog('Timeout error', _syncService.deviceId);
  }
}
```

---

## الأداء والتحسينات

### معايير الأداء المتوقعة

```
Operation                    | Time      | Memory
---------------------------|-----------|----------
Discovery of single device  | 50-100ms  | 1-2 MB
Broadcast to 10 devices     | 200-500ms | 2-3 MB
Sync update processing      | 10-50ms   | 0.5 MB
UI update via Consumer      | 16ms      | -
Total sync cycle            | 5s        | 5-10 MB
```

### Optimization Techniques

#### 1. Batch Processing
```dart
// جمع التحديثات وإرسالها مرة واحدة
final updates = <DeviceUpdate>[];
updates.add(update1);
updates.add(update2);
await broadcastBatch(updates);
```

#### 2. Selective Broadcasting
```dart
// إرسال فقط التحديثات المهمة
if (hasSignificantChange(newState, oldState)) {
  await broadcast(newState);
}
```

#### 3. Resource Pooling
```dart
// استخدام DatagramSocket واحد للجميع
static final _socket = DatagramSocket.bind(...);
```

---

## الأمان

### معايير الأمان المُطبقة

#### 1. Device Identification
```dart
// معرف فريد لكل جهاز
final deviceId = Uuid().v4();  // UUID v4 قياسي
```

#### 2. Payload Validation
```dart
if (payload['data'] == null) {
  throw InvalidPayloadException();
}
```

#### 3. Session Management
```dart
// تتبع الجلسات
final session = SessionInfo(
  sessionId: uuid.v4(),
  groupId: groupId,
  deviceId: deviceId,
);
```

#### 4. Audit Logging
```dart
// سجل كامل لجميع العمليات
_addSyncLog('Action: $action', '$deviceId');
```

---

## التوسعات المستقبلية

### 1. التشفير (Encryption)

```dart
class EncryptedSyncService extends LocalNetworkSyncService {
  Future<void> broadcastEncrypted(Map<String, dynamic> data) async {
    final encrypted = AES256.encrypt(jsonEncode(data), key);
    await super.broadcastSyncUpdate({'encrypted': encrypted});
  }
  
  void handleEncryptedMessage(Datagram datagram) {
    final encrypted = jsonDecode(...);
    final decrypted = AES256.decrypt(encrypted['encrypted'], key);
    // معالجة البيانات
  }
}
```

### 2. المزامنة السحابية

```dart
class CloudSyncService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  Future<void> syncToCloud(DeviceGroupData data) async {
    await _db.ref().child('groups/${data.deviceId}').set(data.toJson());
  }
  
  Stream<DeviceGroupData> listenToCloud(String groupId) {
    return _db.ref().child('groups/$groupId').onValue.map((event) =>
      DeviceGroupData.fromJson(event.snapshot.value)
    );
  }
}
```

### 3. ضغط البيانات

```dart
class CompressedSyncService {
  List<int> compress(String data) {
    return gzip.encode(utf8.encode(data));
  }
  
  String decompress(List<int> data) {
    return utf8.decode(gzip.decode(data));
  }
}
```

### 4. النسخ الاحتياطي التلقائي

```dart
class AutoBackupService {
  Future<void> scheduleBackup() async {
    Timer.periodic(Duration(hours: 1), (_) async {
      final state = groupManager.getGroupState();
      await saveToFile(state);
    });
  }
  
  Future<void> restore(String backupPath) async {
    final data = await readFile(backupPath);
    // استعادة الحالة
  }
}
```

---

## الاختبار المتقدم

### Unit Tests

```dart
test('sync service handles multiple devices', () {
  for (int i = 0; i < 50; i++) {
    syncService.registerDevice('Device-$i');
  }
  
  expect(syncService.getConnectedDevices().length, 50);
});
```

### Integration Tests

```dart
testWidgets('complete device sync flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Start sync on device 1
  await groupManager.broadcastDeviceState('Device-1', data);
  
  // Verify update on device 2
  expect(find.byWidget(DeviceUpdated), findsOneWidget);
});
```

### Performance Tests

```dart
benchmark('1000 device updates', () {
  for (int i = 0; i < 1000; i++) {
    groupManager.broadcastDeviceState('Device-1', data);
  }
});
```

---

## استكشاف الأخطاء المتقدم

### Network Debugging

```bash
# مراقبة حركة الشبكة
adb shell tcpdump -i any -n 'udp port 5555 or udp port 5556'

# اختبار الاتصال
adb shell ping 192.168.1.1

# عرض المنافذ المفتوحة
netstat -an | findstr :5555
```

### Memory Profiling

```dart
// في main.dart
import 'dart:developer' as developer;

developer.Timeline.startSync('sync_broadcast');
await groupManager.broadcastDeviceState('Device-1', data);
developer.Timeline.finishSync();
```

### Performance Monitoring

```dart
final monitor = ResourceMonitor();

monitor.recordMessageSent();
monitor.recordSyncRequest();

final stats = monitor.getStats();
print('Average response time: ${stats['averageResponseTime']}ms');
```

---

## API Reference

### SyncService

```dart
// Core Methods
Future<void> initialize()
void registerDevice(String deviceName)
void broadcastDeviceUpdate(String deviceName, DeviceData deviceData)
void receiveDeviceUpdate(DeviceSyncData syncData)
Map<String, dynamic> generateSyncPayload(DeviceData deviceData)

// Getters
String get deviceId
bool get isOnline
List<DeviceSyncData> getConnectedDevices()
bool isDeviceConnected(String targetDeviceId)

// Events
Stream<SyncEvent> get syncEvents
Stream<DeviceSyncData> get deviceUpdates
```

### LocalNetworkSyncService

```dart
// Core Methods
Future<void> initialize()
Future<void> sendSyncUpdate(String targetDeviceId, Map payload)
Future<void> broadcastSyncUpdate(Map payload)
List<NetworkDeviceInfo> getDiscoveredDevices()
void stop()
```

### DeviceGroupManager

```dart
// Core Methods
Future<void> initialize(String groupId)
void registerDeviceInGroup(String deviceName)
Future<void> broadcastDeviceState(String deviceName, DeviceData deviceData)
Future<void> syncWithDevice(String targetDeviceId, DeviceData deviceData)

// Settings
void enableAutoSync()
void disableAutoSync()
void setSyncInterval(int seconds)

// State & Logs
Map<String, dynamic> getGroupState()
String exportSyncLogs()

// Cleanup
void stop()
```

---

## البيانات المرجعية

### منافذ الشبكة

| المنفذ | الاستخدام | البروتوكول |
|------|----------|----------|
| 5555 | اكتشاف الأجهزة | UDP Broadcast |
| 5556 | مزامنة البيانات | UDP Point-to-Point |

### متغيرات البيئة

```bash
# لتخصيص الإعدادات
SYNC_INTERVAL=10          # فترة المزامنة (ثواني)
MAX_DEVICES=50            # عدد الأجهزة الأقصى
DEBUG_SYNC=true           # تفعيل التصحيح
LOG_LEVEL=verbose         # مستوى السجلات
```

---

## الخلاصة التقنية

### المزايا التقنية
✓ معمارية modular وسهلة التوسع
✓ معالجة أخطاء قوية
✓ مراقبة أداء بطبقات متعددة
✓ قابلة للاختبار بسهولة
✓ موثقة بالكامل

### التحديات المحتملة
⚠ الاعتماد على WiFi المحلي
⚠ تحديد الجهاز والتخصيص
⚠ قابلية التوسع مع عدد كبير جداً من الأجهزة

### الحلول المقترحة
✅ استخدام هاشتاجات للتمييز
✅ تجميع الأجهزة في مجموعات
✅ استخدام خادم وسيط للشبكات الكبيرة

---

**آخر تحديث:** يناير 2026

# نظام التحكم المشترك الذكي بين الأجهزة المحمولة

## نظرة عامة
هذا النظام يوفر حلاً متكاملاً للتحكم المشترك الذكي بين أجهزة محمولة متعددة، حيث يتم تحديث جميع الأجهزة تلقائياً عند إجراء تغيير على أي جهاز.

## المكونات الرئيسية

### 1. SyncService (خدمة المزامنة)
**الملف:** `lib/sync_service.dart`

المسؤول عن:
- إدارة معرف الجهاز الفريد
- بث التحديثات بين الأجهزة
- مراقبة حالة الاتصال
- إنشاء أحمال العمل الموحدة

**الاستخدام:**
```dart
final syncService = SyncService();
await syncService.initialize();

// تسجيل جهاز
syncService.registerDevice('Device-1');

// بث تحديث
syncService.broadcastDeviceUpdate('Device-1', deviceData);

// الاستماع للأحداث
syncService.syncEvents.listen((event) {
  print('Event: ${event.type}');
});
```

### 2. LocalNetworkSyncService (خدمة المزامنة المحلية)
**الملف:** `lib/local_network_sync_service.dart`

المسؤول عن:
- اكتشاف الأجهزة على الشبكة المحلية
- إرسال واستقبال البيانات عبر UDP
- الحفاظ على قائمة الأجهزة المكتشفة

**المنافذ المستخدمة:**
- منفذ الاكتشاف: 5555
- منفذ المزامنة: 5556

**الاستخدام:**
```dart
final networkService = LocalNetworkSyncService();
await networkService.initialize();

// الحصول على الأجهزة المكتشفة
final devices = networkService.getDiscoveredDevices();

// بث التحديث لجميع الأجهزة
await networkService.broadcastSyncUpdate(payload);

// إرسال تحديث لجهاز محدد
await networkService.sendSyncUpdate(targetDeviceId, payload);
```

### 3. DeviceGroupManager (مدير مجموعة الأجهزة)
**الملف:** `lib/device_group_manager.dart`

المسؤول عن:
- إدارة مجموعات الأجهزة
- تنسيق المزامنة بين الخدمات
- تسجيل سجلات المزامنة
- إعدادات المزامنة التلقائية

**الميزات:**
- مزامنة تلقائية قابلة للتخصيص
- سجل مفصل للمزامنة
- حالة المجموعة الكاملة
- دعم المزامنة المباشرة والبث

**الاستخدام:**
```dart
final groupManager = DeviceGroupManager();
await groupManager.initialize('gaming-group-001');

// تسجيل جهاز
groupManager.registerDeviceInGroup('Device-1');

// بث تحديث
await groupManager.broadcastDeviceState('Device-1', deviceData);

// مزامنة مباشرة مع جهاز
await groupManager.syncWithDevice(targetDeviceId, deviceData);

// الحصول على حالة المجموعة
final state = groupManager.getGroupState();
```

### 4. DeviceGroupScreen (شاشة إدارة المجموعة)
**الملف:** `lib/device_group_screen.dart`

واجهة مستخدم شاملة تعرض:
- معلومات المجموعة
- قائمة الأجهزة المتصلة
- حالة المزامنة لكل جهاز
- سجلات المزامنة
- إعدادات المزامنة

## كيفية التكامل مع التطبيق الحالي

### 1. تحديث pubspec.yaml
تمت إضافة المكتبات التالية:
```yaml
firebase_core: ^2.24.0
firebase_database: ^10.2.0
connectivity_plus: ^5.0.0
uuid: ^4.0.0
web_socket_channel: ^2.4.0
```

### 2. دمج في main.dart
```dart
import 'device_group_manager.dart';

void main() async {
  // ... الكود الحالي ...
  
  // تهيئة مدير المجموعة
  final groupManager = DeviceGroupManager();
  await groupManager.initialize('gaming-group-001');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => groupManager),
        // ... الـ providers الأخرى ...
      ],
      child: const MyApp(),
    ),
  );
}
```

### 3. إضافة شاشة المجموعة للملاحة
```dart
// في شاشة الإعدادات أو القائمة الرئيسية
ListTile(
  title: const Text('إدارة مجموعة الأجهزة'),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeviceGroupScreen(),
      ),
    );
  },
)
```

## سير العمل الكامل

### عند التحكم بجهاز واحد:
1. يتم إجراء تغيير على الجهاز (تشغيل/إيقاف، إضافة أمر، إلخ)
2. يتم استدعاء `broadcastDeviceState()` في DeviceGroupManager
3. يتم بث التحديث عبر المزامنة المحلية
4. تستقبل جميع الأجهزة الأخرى التحديث
5. يتم تحديث حالة كل جهاز تلقائياً

### مثال عملي:
```dart
// في شاشة التحكم بالجهاز
Future<void> toggleDevice() async {
  setState(() {
    deviceData.isRunning = !deviceData.isRunning;
  });
  
  // بث التحديث لجميع الأجهزة
  final groupManager = context.read<DeviceGroupManager>();
  await groupManager.broadcastDeviceState('Device-1', deviceData);
}
```

## المزامنة التلقائية

### الإعدادات الافتراضية:
- **حالة المزامنة:** مفعلة
- **فترة المزامنة:** 5 ثواني
- **السجلات المحفوظة:** 100 إدخال

### التحكم بالمزامنة:
```dart
// تعطيل المزامنة التلقائية
groupManager.disableAutoSync();

// تفعيل المزامنة التلقائية
groupManager.enableAutoSync();

// تغيير فترة المزامنة
groupManager.setSyncInterval(10); // 10 ثواني
```

## اكتشاف الأجهزة

الخدمة تكتشف الأجهزة الأخرى على الشبكة المحلية تلقائياً عبر:

1. **بث الاكتشاف:** كل 10 ثواني
2. **استقبال الاكتشاف:** الاستماع على المنفذ 5555
3. **مدة الصحة:** 60 ثانية (يتم حذف الأجهزة غير المستجيبة)

```dart
// الحصول على قائمة الأجهزة المكتشفة
final networkService = LocalNetworkSyncService();
final devices = networkService.getDiscoveredDevices();

devices.forEach((device) {
  print('${device.deviceName} - ${device.ipAddress}');
});
```

## سجلات المزامنة

تتضمن السجلات:
- **الطابع الزمني:** وقت الحدث
- **الإجراء:** نوع الحدث (تسجيل، بث، مزامنة مباشرة، إلخ)
- **معرف الجهاز:** الجهاز المرتبط بالحدث

```dart
// تصدير السجلات
String logs = groupManager.exportSyncLogs();
print(logs);
```

## حالة الخطأ والاتصال

### معالجة انقطاع الاتصال:
- يتم الكشف عن انقطاع الاتصال تلقائياً
- يتم وضع علامة على الأجهزة كـ "منقطعة"
- يتم إعادة المحاولة عند استعادة الاتصال

### معالجة الأخطاء:
```dart
try {
  await groupManager.broadcastDeviceState('Device-1', deviceData);
} catch (e) {
  print('خطأ في البث: $e');
}
```

## الأمان

### الميزات الأمنية:
1. **معرفات فريدة:** كل جهاز يحصل على UUID فريد
2. **معرف المجموعة:** يضمن أن الأجهزة تنتمي لنفس المجموعة
3. **التحقق من الصحة:** التحقق من صحة البيانات قبل المعالجة
4. **سجل المزامنة:** تتبع كامل لجميع التحديثات

## أداء وقابلية التوسع

### التحسينات:
- **UDP للبث السريع:** أسرع من TCP للبث
- **استدعاءات غير متزامنة:** لا تحجب واجهة المستخدم
- **معالجة الدفعات:** تجميع التحديثات
- **تنظيف الموارد:** حذف الأجهزة المنقطعة تلقائياً

### الحدود الموصى بها:
- **عدد الأجهزة:** حتى 50 جهاز على نفس الشبكة
- **فترة المزامنة:** 1-30 ثانية
- **حجم البيانات:** حتى 64KB لكل تحديث

## خطوات البدء

### 1. تثبيت المكتبات:
```bash
flutter pub get
```

### 2. تهيئة الخدمات في main.dart:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final groupManager = DeviceGroupManager();
  await groupManager.initialize('your-group-id');
  
  runApp(MyApp(groupManager: groupManager));
}
```

### 3. استخدام في الشاشات:
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceGroupManager>(
      builder: (context, groupManager, _) {
        return Column(
          children: [
            // عرض الأجهزة المتصلة
            ...groupManager.deviceGroups.values.map((device) {
              return ListTile(
                title: Text(device.deviceName),
                subtitle: Text(device.isOnline ? 'متصل' : 'منقطع'),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
```

## الدعم والمراقبة

### سجلات المزامنة:
```dart
// عرض آخر 10 سجلات
final recentLogs = groupManager.syncLogs.skip(
  groupManager.syncLogs.length > 10 
    ? groupManager.syncLogs.length - 10 
    : 0
);
```

### حالة الاتصال:
```dart
// التحقق من اتصال جهاز
bool isConnected = syncService.isDeviceConnected(deviceId);

// الحصول على جميع الأجهزة المتصلة
List<DeviceSyncData> connected = syncService.getConnectedDevices();
```

## الخلاصة

هذا النظام يوفر:
✓ تحكم مشترك ذكي بين الأجهزة
✓ مزامنة تلقائية في الوقت الفعلي
✓ اكتشاف الأجهزة على الشبكة المحلية
✓ سجلات مفصلة للمزامنة
✓ واجهة إدارة شاملة
✓ معالجة أخطاء قوية
✓ أداء عالي وقابلية توسع

للمزيد من المعلومات، راجع الملفات المرفقة.

## دليل الدمج مع التطبيق الحالي

هذا الدليل يشرح كيفية دمج نظام التحكم المشترك الذكي مع تطبيق الكاشير الموجود.

### الخطوة 1: تحديث pubspec.yaml

تم بالفعل إضافة المكتبات المطلوبة إلى `pubspec.yaml`:
```yaml
connectivity_plus: ^5.0.0
uuid: ^4.0.0
web_socket_channel: ^2.4.0
```

**التأكد من التحديثات:**
```bash
flutter pub get
```

---

### الخطوة 2: تهيئة المزامنة في main.dart

**أضف الاستيراد:**
```dart
import 'device_group_manager.dart';
import 'sync_service.dart';
```

**أضف في دالة main():**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // الكود الموجود
  await windowManager.ensureInitialized();
  // ...

  // تهيئة مدير المجموعة (جديد)
  final groupManager = DeviceGroupManager();
  
  // تهيئة Hive والكود الآخر
  // ...
  
  // تشغيل التطبيق مع مدير المجموعة
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
        ChangeNotifierProvider.value(
          value: groupManager,
        ),
        // providers أخرى...
      ],
      child: const MyApp(),
    ),
  );
}
```

---

### الخطوة 3: إضافة الملاحة لشاشة الإدارة

**في settings_screen.dart أو في الملاحة الرئيسية:**

```dart
// أضف هذا الزر في قائمة الإعدادات
ListTile(
  leading: const Icon(Icons.devices_outlined),
  title: const Text('إدارة مجموعة الأجهزة'),
  subtitle: const Text('التحكم المشترك الذكي'),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeviceGroupScreen(),
      ),
    );
  },
),
```

---

### الخطوة 4: دمج المزامنة مع device_grid.dart

عند تغيير حالة الجهاز، قم ببث التحديث:

**في device_grid.dart:**

```dart
import 'device_group_manager.dart';

// في دالة تشغيل/إيقاف الجهاز
Future<void> toggleDevice(String deviceId) async {
  setState(() {
    // التغيير المحلي
    devices[deviceId].isRunning = !devices[deviceId].isRunning;
  });

  // بث التحديث لجميع الأجهزة الأخرى
  final groupManager = context.read<DeviceGroupManager>();
  if (groupManager.autoSync) {
    await groupManager.broadcastDeviceState(
      devices[deviceId].name,
      devices[deviceId],
    );
  }
}
```

---

### الخطوة 5: دمج المزامنة مع إدارة الطلبات

**في order_dialog.dart:**

```dart
import 'device_group_manager.dart';

// عند إضافة طلب جديد
Future<void> addOrder(OrderItem order) async {
  // الإضافة المحلية
  deviceData.orders.add(order);
  setState(() {});

  // بث التحديث
  final groupManager = context.read<DeviceGroupManager>();
  await groupManager.broadcastDeviceState(
    deviceData.name,
    deviceData,
  );
}
```

---

### الخطوة 6: الاستماع للتحديثات من الأجهزة الأخرى

**في أي شاشة تحتاج لتحديث:**

```dart
import 'device_group_manager.dart';

class DeviceMonitorScreen extends StatefulWidget {
  @override
  State<DeviceMonitorScreen> createState() => _DeviceMonitorScreenState();
}

class _DeviceMonitorScreenState extends State<DeviceMonitorScreen> {
  late StreamSubscription _updateSubscription;

  @override
  void initState() {
    super.initState();
    
    // الاستماع للتحديثات
    final groupManager = context.read<DeviceGroupManager>();
    _updateSubscription = groupManager.stream.listen((update) {
      // تحديث الواجهة
      setState(() {});
    });
  }

  @override
  void dispose() {
    _updateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceGroupManager>(
      builder: (context, groupManager, _) {
        return ListView.builder(
          itemCount: groupManager.deviceGroups.length,
          itemBuilder: (context, index) {
            final device = groupManager.deviceGroups.values.elementAt(index);
            return ListTile(
              title: Text(device.deviceName),
              subtitle: Text(
                device.isOnline ? 'متصل' : 'منقطع',
              ),
            );
          },
        );
      },
    );
  }
}
```

---

### الخطوة 7: تحديث شاشة الإحصائيات

**في statistics_screen.dart:**

```dart
import 'device_group_manager.dart';

// عرض إحصائيات مجموعة الأجهزة
Widget buildGroupStatistics() {
  return Consumer<DeviceGroupManager>(
    builder: (context, groupManager, _) {
      final state = groupManager.getGroupState();
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إحصائيات المجموعة',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildStatRow('عدد الأجهزة', '${state['deviceCount']}'),
              _buildStatRow('الأجهزة النشطة',
                '${(state['syncStatus'] as List).where((s) => s['isActive']).length}'),
              _buildStatRow('آخر تحديث',
                _formatTime(state['lastSync'] as String)),
            ],
          ),
        ),
      );
    },
  );
}

String _formatTime(String iso) {
  final dt = DateTime.parse(iso);
  return '${dt.hour}:${dt.minute}';
}

Widget _buildStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
```

---

### الخطوة 8: تعطيل/تفعيل المزامنة حسب الحاجة

**في settings_screen.dart:**

```dart
// إضافة خيار التحكم بالمزامنة
SwitchListTile(
  title: const Text('المزامنة التلقائية'),
  value: context.watch<DeviceGroupManager>().autoSync,
  onChanged: (value) {
    final groupManager = context.read<DeviceGroupManager>();
    if (value) {
      groupManager.enableAutoSync();
    } else {
      groupManager.disableAutoSync();
    }
  },
),

// خيار تغيير فترة المزامنة
ListTile(
  title: const Text('فترة المزامنة'),
  trailing: DropdownButton<int>(
    value: context.watch<DeviceGroupManager>().syncInterval,
    items: [1, 2, 5, 10, 15, 30].map((i) {
      return DropdownMenuItem(
        value: i,
        child: Text('$i ثانية'),
      );
    }).toList(),
    onChanged: (value) {
      if (value != null) {
        context.read<DeviceGroupManager>().setSyncInterval(value);
      }
    },
  ),
),
```

---

### الخطوة 9: إضافة الإخطارات عند تحديث جهاز

**في app_state.dart أو خدمة مخصصة:**

```dart
class NotificationService {
  static void notifyDeviceUpdate(String deviceName) {
    // استخدم audioplayers لتشغيل صوت التنبيه
    AudioPlayer().play(AssetSource('sounds/update_notification.mp3'));
    
    // أو اعرض رسالة
    print('تم تحديث الجهاز: $deviceName');
  }
}

// في device_group_manager.dart, اضف:
void _handleDeviceUpdate(DeviceSyncData syncData) {
  if (deviceGroups[syncData.deviceId] == null) {
    deviceGroups[syncData.deviceId] = DeviceGroupData(
      deviceId: syncData.deviceId,
      deviceName: syncData.deviceName,
      createdAt: DateTime.now(),
    );
    
    // إشعار بجهاز جديد
    NotificationService.notifyDeviceUpdate(syncData.deviceName);
  }
  
  deviceGroups[syncData.deviceId]?.updateState(syncData);
  _addSyncLog('Update received', syncData.deviceId);
  notifyListeners();
}
```

---

### الخطوة 10: النسخ الاحتياطي والاستعادة

**أضف في data_persistence_manager.dart:**

```dart
// حفظ حالة المزامنة
Future<void> saveSyncState(DeviceGroupManager groupManager) async {
  final state = groupManager.getGroupState();
  final json = jsonEncode(state);
  
  // احفظ في Hive أو SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_sync_state', json);
}

// استعادة حالة المزامنة
Future<void> restoreSyncState() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('last_sync_state');
  
  if (json != null) {
    final state = jsonDecode(json);
    // استعد الحالة
  }
}
```

---

### الخطوة 11: بدء التطبيق المحدث

```bash
# تنظيف البناء
flutter clean

# تحديث المكتبات
flutter pub get

# بناء الملفات المولدة
flutter pub run build_runner build

# تشغيل
flutter run
```

---

## قائمة التحقق من الدمج

- [ ] تحديث pubspec.yaml بالمكتبات الجديدة
- [ ] إضافة الاستيرادات في main.dart
- [ ] تهيئة مدير المجموعة في main()
- [ ] إضافة ملاحة شاشة الإدارة
- [ ] دمج البث عند تغيير الأجهزة
- [ ] دمج البث عند إضافة الطلبات
- [ ] الاستماع للتحديثات في الشاشات الرئيسية
- [ ] تحديث إحصائيات المجموعة
- [ ] إضافة خيارات التحكم بالمزامنة
- [ ] اختبار الدمج مع أجهزة متعددة

---

## اختبار الدمج

### 1. اختبار أساسي
```bash
flutter run
# تحقق من ظهور قائمة المجموعة في الإعدادات
```

### 2. اختبار المزامنة
```bash
# شغّل على جهازين
flutter run -d <device1>
flutter run -d <device2>

# غيّر شيء على جهاز واحد
# تحقق من التحديث على الآخر
```

### 3. اختبار الأداء
```bash
flutter run --release
# راقب استهلاك الموارد
```

---

## حل المشاكل الشائعة

### خطأ: "DeviceGroupManager not found"
```dart
// تأكد من إضافة في MultiProvider
ChangeNotifierProvider.value(
  value: groupManager,
)
```

### خطأ: "Port already in use"
```bash
# تحقق من المنافذ المستخدمة
netstat -ano | findstr :5555
# عطّل التطبيقات التي تستخدم هذه المنافذ
```

### لا تظهر التحديثات
```dart
// تأكد من استدعاء broadcastDeviceState
// وأن autoSync مفعل
groupManager.enableAutoSync();
```

---

## الخطوات التالية

1. اختبر مع عدة أجهزة
2. راقب السجلات للأخطاء
3. ضبّط إعدادات المزامنة
4. أضف ميزات إضافية حسب الحاجة

---

**التطبيق جاهز للاستخدام الآن! 🎉**






import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_persistence_manager.dart';
import 'printer_service.dart';

class OrderItem {
  String name;
  double price;
  int quantity;
  DateTime firstOrderTime;
  DateTime lastOrderTime;
  String? notes;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.firstOrderTime,
    required this.lastOrderTime,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'firstOrderTime': firstOrderTime.toIso8601String(),
        'lastOrderTime': lastOrderTime.toIso8601String(),
        'notes': notes,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        name: json['name'],
        price: json['price'],
        quantity: json['quantity'],
        firstOrderTime: DateTime.parse(json['firstOrderTime']),
        lastOrderTime: DateTime.parse(json['lastOrderTime']),
        notes: json['notes'],
      );
}

class ReservationItem {
  String name;
  double price;
  int quantity;
  DateTime reservationTime;
  String notes;

  ReservationItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.reservationTime,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'reservationTime': reservationTime.toIso8601String(),
        'notes': notes,
      };

  factory ReservationItem.fromJson(Map<String, dynamic> json) => ReservationItem(
        name: json['name'],
        price: json['price'],
        quantity: json['quantity'],
        reservationTime: DateTime.parse(json['reservationTime']),
        notes: json['notes'],
      );
}

class DeviceData {
  String name;
  Duration elapsedTime;
  bool isRunning;
  List<OrderItem> orders;
  List<ReservationItem> reservations;
  String notes;
  String mode; // الوضع: فردي أو زوجي
  int customerCount; // عدد الزبائن (الجُدِيد)

  DeviceData({
    required this.name,
    this.elapsedTime = Duration.zero,
    this.isRunning = false,
    List<OrderItem>? orders,
    List<ReservationItem>? reservations,
    this.notes = '',
    this.mode = 'single', // الوضع الافتراضي فردي
    this.customerCount = 1, // الافتراضي عدد الزبائن 1
  }) : orders = orders ?? [],
       reservations = reservations ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'elapsedTime': elapsedTime.inSeconds,
        'isRunning': isRunning,
        'orders': orders.map((e) => e.toJson()).toList(),
        'reservations': reservations.map((e) => e.toJson()).toList(),
        'notes': notes,
        'mode': mode,
        'customerCount': customerCount, // حفظ العدد
      };

  factory DeviceData.fromJson(Map<String, dynamic> json) => DeviceData(
        name: json['name'],
        elapsedTime: Duration(seconds: json['elapsedTime']),
        isRunning: json['isRunning'],
        orders: (json['orders'] as List)
            .map((e) => OrderItem.fromJson(e))
            .toList(),
        reservations: (json['reservations'] as List? ?? [])
            .map((e) => ReservationItem.fromJson(e))
            .toList(),
        notes: json['notes'] ?? '',
        mode: json['mode'] ?? 'single',
        customerCount: json['customerCount'] ?? 1, // قراءة العدد
      );
}

class AppState extends ChangeNotifier {
  Map<String, DeviceData> _devices = {};
  Map<String, Timer?> _timers = {};
  
  // قائمة الأجهزة المحذوفة لتجنب إعادة إنشائها
  Set<String> _deletedDevices = {};

  // قائمة الحجوزات المستقلة
  List<ReservationItem> _allReservations = [];
  
  // للتحكم في عمليات الحفظ المتزامنة
  bool _isSaving = false;
  static bool _isStaticSaving = false; // متغير static للدوال المشتركة
  static Box? _sharedBox;
  static bool _isBoxInitialized = false;
  
  // 🔄 نظام الحفظ التلقائي الدوري
  Timer? _autoSaveTimer;
  DateTime _lastSaveTime = DateTime.now();
  
  // أسعار الأجهزة
  double _pcPrice = 1500.0; // سعر افتراضي عام للـ PC
  
  // أسعار PC فردية لكل جهاز
  Map<String, double> _pcPrices = {};
  
  // أسعار الطاولات فردية لكل طاولة  
  Map<String, double> _tablePrices = {};
  
  // أسعار البيليارد فردية لكل طاولة بيليارد
  Map<String, double> _billiardPrices = {};
  
  // أسعار PS4 فردية لكل جهاز (اسم الجهاز -> {فردي، زوجي})
  Map<String, Map<String, double>> _ps4Prices = {
    'Arabia 1': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 2': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 3': {'single': 3000.0, 'multi': 4000.0},
    'Arabia 4': {'single': 3000.0, 'multi': 4000.0},
    'Arabia 5': {'single': 3000.0, 'multi': 4000.0},
    'Arabia 6': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 7': {'single': 2000.0, 'multi': 3000.0},
    'Arabia 8': {'single': 2000.0, 'multi': 3000.0},
  };
  
  // الأقسام المخصصة
  Map<String, List<String>> _customCategories = {};
  
  // المصروفات اليومية
  List<Map<String, dynamic>> _todayExpenses = [];
  
  // الإيرادات اليدوية
  List<Map<String, dynamic>> _manualRevenues = [];
  
  // الأشهر المكتملة
  Set<String> _completedMonths = {};
  
  // بيانات الأشهر المكتملة (تحتفظ بإيرادات ومصروفات كل شهر)
  Map<String, Map<String, dynamic>> _monthlyData = {};
  
  // الديون
  List<Map<String, dynamic>> _debts = [];
  
  // أسماء الأقسام الافتراضية المخصصة
  Map<String, String> _defaultCategoryNames = {};
  
  // أسعار الطلبات
  Map<String, double> _orderPrices = {};
  
  // إعدادات الثيم
  bool _isDarkMode = true;

  AppState() {
    print('🚀 بدء تحميل البيانات من النظام المحسن...');
    _loadFromPrefs();
    initializeAutoSave(); // 🚀 تفعيل نظام الحفظ التلقائي فور بناء الكلاس
    
    // حفظ فوري للتأكد من عمل النظام
    Future.delayed(Duration(seconds: 3), () async {
      await _saveToPrefs();
      print('✅ تم التحقق من عمل نظام الحفظ');
    });
  }

  // Getters للأسعار
  double get pcPrice => _pcPrice; // السعر العام (للتوافق مع الكود القديم)
  Map<String, Map<String, double>> get ps4Prices => Map.from(_ps4Prices);
  
  // دوال للحصول على أسعار فردية
  double getPcPrice(String deviceName) {
    return _pcPrices[deviceName] ?? _pcPrice; // إذا لم يوجد سعر فردي، استخدم العام
  }
  
  double getTablePrice(String deviceName) {
    return _tablePrices[deviceName] ?? _pcPrice; // إذا لم يوجد سعر فردي، استخدم سعر PC العام
  }
  
  double getBilliardPrice(String deviceName) {
    return _billiardPrices[deviceName] ?? _pcPrice; // إذا لم يوجد سعر فردي، استخدم سعر PC العام
  }
  
  // دالة للحصول على سعر جهاز PS4 محدد
  double getPs4Price(String deviceName, String mode) {
    return _ps4Prices[deviceName]?[mode] ?? 0;
  }
  
  // Getter للأجهزة
  Map<String, DeviceData> get devices => Map.from(_devices);
  
  // Getter للأجهزة المحذوفة  
  Set<String> get deletedDevices => Set.from(_deletedDevices);
  
  // 🚀 تهيئة نظام الحفظ التلقائي
  void initializeAutoSave() {
    _startAutoSave();
    print('🔄 تم تفعيل نظام الحفظ التلقائي - كل 30 ثانية');
  }
  
  // 🔄 بدء الحفظ التلقائي الدوري
  void _startAutoSave() {
    _autoSaveTimer?.cancel(); // إلغاء أي timer سابق
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (DateTime.now().difference(_lastSaveTime).inSeconds > 25) {
        print('🔄 حفظ تلقائي دوري...');
        _saveToPrefs();
      }
    });
  }
  
  // Getters وSetters لأسعار الطلبات
  Map<String, double> get orderPrices => Map.from(_orderPrices);
  
  double getOrderPrice(String itemName) {
    return _orderPrices[itemName] ?? 0.0;
  }
  
  void updateOrderPrice(String itemName, double price) {
    _orderPrices[itemName] = price;
    _saveToPrefs();
    notifyListeners();
  }
  
  void updateOrderPrices(Map<String, double> prices) {
    _orderPrices.addAll(prices);
    _saveToPrefs();
    notifyListeners();
  }
  
  void removeOrderItem(String itemName) {
    _orderPrices.remove(itemName);
    _saveToPrefs();
    notifyListeners();
  }
  
  // دوال إدارة الديون
  List<Map<String, dynamic>> get debts => List.from(_debts);
  
  double getTotalDebts() {
    return _debts.fold(0.0, (sum, debt) => sum + (debt['amount'] ?? 0.0));
  }
  
  void addDebt(String name, double amount) {
    _debts.add({
      'name': name,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    });
    _saveToPrefs();
    notifyListeners();
  }
  
  void updateDebt(int index, String name, double amount) {
    if (index >= 0 && index < _debts.length) {
      _debts[index] = {
        'name': name,
        'amount': amount,
        'date': _debts[index]['date'], // الاحتفاظ بتاريخ الإضافة الأصلي
      };
      _saveToPrefs();
      notifyListeners();
    }
  }
  
  void removeDebt(int index) {
    if (index >= 0 && index < _debts.length) {
      _debts.removeAt(index);
      _saveToPrefs();
      notifyListeners();
    }
  }
  
  void clearAllDebts() {
    _debts.clear();
    _saveToPrefs();
    notifyListeners();
  }
  
  // الحصول على جميع العناصر المتاحة في قسم معين
  List<String> getAvailableItemsForCategory(String categoryName) {
    List<String> items = [];
    
    // للأقسام المخصصة فقط
    if (_customCategories.containsKey(categoryName)) {
      items = _customCategories[categoryName]!.where((item) => 
        _orderPrices[item] != null && _orderPrices[item]! > 0
      ).toList();
    }
    
    return items;
  }
  
  // دوال الأقسام المخصصة
  Map<String, List<String>> get customCategories => Map.from(_customCategories);
  Map<String, String> get defaultCategoryNames => Map.from(_defaultCategoryNames);

  void updateDefaultCategoryName(String originalKey, String newName) {
    _defaultCategoryNames[originalKey] = newName;
    _saveToPrefs();
    notifyListeners();
  }

  void addNewCategory(String categoryName) {
    print('📂 إضافة قسم جديد: $categoryName');
    _customCategories[categoryName] = [];
    
    // حفظ فوري + طارئ للأقسام الجديدة
    _saveToPrefs();
    _emergencySave();
    notifyListeners();
    
    print('✅ تم حفظ القسم الجديد: $categoryName');
  }

  // دوال إدارة المصروفات
  List<Map<String, dynamic>> get todayExpenses => List.from(_todayExpenses);
  
  // جمع جميع الحجوزات من كل الأجهزة
  List<ReservationItem> get reservations {
    List<ReservationItem> allReservations = [];
    for (var device in _devices.values) {
      allReservations.addAll(device.reservations);
    }
    return allReservations;
  }

  void addExpense(Map<String, dynamic> expense) {
    _todayExpenses.add(expense);
    _saveToPrefs();
    notifyListeners();
  }

  void removeExpense(dynamic item) {
    if (item is int) {
      // إذا كان الرقم فهرس
      if (item >= 0 && item < _todayExpenses.length) {
        _todayExpenses.removeAt(item);
        _saveToPrefs();
        notifyListeners();
      }
    } else if (item is Map<String, dynamic>) {
      // إذا كان كائن المصروف
      _todayExpenses.remove(item);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clearTodayExpenses() {
    _todayExpenses.clear();
    _saveToPrefs();
    notifyListeners();
  }

  // دوال إدارة الإيرادات اليدوية
  List<Map<String, dynamic>> get manualRevenues => List.from(_manualRevenues);

  // دوال إدارة الأشهر المكتملة
  Set<String> get completedMonths => Set.from(_completedMonths);

  void addRevenue(Map<String, dynamic> revenue) {
    _manualRevenues.add(revenue);
    _saveToPrefs();
    notifyListeners();
  }

  void removeRevenue(dynamic item) {
    if (item is int) {
      // إذا كان الرقم فهرس
      if (item >= 0 && item < _manualRevenues.length) {
        _manualRevenues.removeAt(item);
        _saveToPrefs();
        notifyListeners();
      }
    } else if (item is Map<String, dynamic>) {
      // إذا كان كائن الإيراد
      _manualRevenues.remove(item);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clearManualRevenues() {
    _manualRevenues.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void addCompletedMonth(String monthId) {
    _completedMonths.add(monthId);
    _saveToPrefs();
    notifyListeners();
  }

  void saveMonthData(String monthId, List<Map<String, dynamic>> revenues, List<Map<String, dynamic>> expenses) {
    _monthlyData[monthId] = {
      'revenues': List.from(revenues),
      'expenses': List.from(expenses),
      'totalRevenue': revenues.fold(0.0, (sum, r) => sum + (r['amount'] as num)),
      'totalExpenses': expenses.fold(0.0, (sum, e) => sum + (e['amount'] as num)),
      'completedDate': DateTime.now().toIso8601String(),
    };
    _saveToPrefs();
    notifyListeners();
  }

  Map<String, dynamic>? getMonthData(String monthId) {
    return _monthlyData[monthId];
  }

  Map<String, Map<String, dynamic>> getAllMonthsData() {
    return Map.from(_monthlyData);
  }

  void saveSelectedMonth(String monthId) {
    _saveSelectedMonthToPrefs(monthId);
  }

  void clearCurrentMonthData() {
    _manualRevenues.clear();
    _todayExpenses.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void updateCompletedMonth(String oldMonthId, String newMonthId) {
    if (_completedMonths.contains(oldMonthId)) {
      _completedMonths.remove(oldMonthId);
      _completedMonths.add(newMonthId);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeCompletedMonth(String monthId) {
    if (_completedMonths.contains(monthId)) {
      _completedMonths.remove(monthId);
      _saveToPrefs();
      notifyListeners();
    }
  }
  
  void addItemToCategory(String categoryName, String itemName, double price) {
    print('🍽️ إضافة عنصر جديد: $itemName إلى القسم: $categoryName');
    
    if (!_customCategories.containsKey(categoryName)) {
      _customCategories[categoryName] = [];
      print('إنشاء قسم جديد: $categoryName');
    }
    _customCategories[categoryName]!.add(itemName);
    _orderPrices[itemName] = price;
    
    // حفظ فوري + طارئ للعناصر الجديدة
    _saveToPrefs();
    _emergencySave();
    notifyListeners();
    
    print('✅ تم حفظ العنصر: $itemName بسعر: $price');
  }
  
  void removeItemFromCategory(String categoryName, String itemName) {
    print('⚙️ حذف عنصر: $itemName من القسم: $categoryName');
    
    _customCategories[categoryName]?.remove(itemName);
    _orderPrices.remove(itemName);
    
    // حفظ فوري + طارئ بعد الحذف
    _saveToPrefs();
    _emergencySave();
    notifyListeners();
    
    print('✅ تم حذف وحفظ العنصر: $itemName');
  }
  
  void removeCategory(String categoryName) {
    // حذف جميع عناصر القسم من الأسعار
    _customCategories[categoryName]?.forEach((item) {
      _orderPrices.remove(item);
    });
    _customCategories.remove(categoryName);
    _saveToPrefs();
    notifyListeners();
  }
  
  void updateCategoryName(String oldName, String newName) {
    if (_customCategories.containsKey(oldName) && !_customCategories.containsKey(newName)) {
      List<String> items = _customCategories[oldName]!;
      _customCategories.remove(oldName);
      _customCategories[newName] = items;
      
      // تحديث ربط الأقسام في خدمة الطباعة
      PrinterService().updateCategoryName(oldName, newName);
      
      _saveToPrefs();
      notifyListeners();
      print('🔄 تم تحديث اسم القسم من "$oldName" إلى "$newName" مع الحفاظ على الربط بالطابعات');
    }
  }
  
  List<String> getCategoryItems(String categoryName) {
    return List<String>.from(_customCategories[categoryName] ?? []);
  }
  
  // Getter للثيم
  bool get isDarkMode => _isDarkMode;

  // دوال تحديث الأسعار
  void updatePcPrice(double price) {
    _pcPrice = price;
    notifyListeners();
    _saveToPrefs();
  }

  // تحديث سعر جهاز PS4 محدد
  void updatePs4Price(String deviceName, String mode, double price) {
    if (_ps4Prices.containsKey(deviceName)) {
      _ps4Prices[deviceName]![mode] = price;
      notifyListeners();
      _saveToPrefs();
    }
  }
  
  // تحديث أسعار جهاز PS4 (فردي وزوجي معاً)
  void updatePs4Prices(String deviceName, double singlePrice, double multiPrice) {
    if (!_ps4Prices.containsKey(deviceName)) {
      _ps4Prices[deviceName] = {};
    }
    _ps4Prices[deviceName]!['single'] = singlePrice;
    _ps4Prices[deviceName]!['multi'] = multiPrice;
    notifyListeners();
    _saveToPrefs();
  }
  
  // تحديث سعر جهاز PC فردي
  void updatePcDevicePrice(String deviceName, double price) {
    _pcPrices[deviceName] = price;
    notifyListeners();
    _saveToPrefs();
  }
  
  // تحديث سعر طاولة فردية
  void updateTablePrice(String deviceName, double price) {
    _tablePrices[deviceName] = price;
    notifyListeners();
    _saveToPrefs();
  }
  
  // تحديث سعر طاولة بيليارد فردية
  void updateBilliardPrice(String deviceName, double price) {
    _billiardPrices[deviceName] = price;
    notifyListeners();
    _saveToPrefs();
  }

  // إدارة الأجهزة
  
  // إضافة جهاز جديد
  Future<void> addDevice(String deviceName, String deviceType) async {
    print('=== addDevice called for: $deviceName ===');
    print('Device exists in _devices: ${_devices.containsKey(deviceName)}');
    print('Device exists in deletedDevices: ${_deletedDevices.contains(deviceName)}');
    
    // إذا كان الجهاز محذوفاً، احذفه من _devices أولاً للتأكد
    if (_deletedDevices.contains(deviceName)) {
      _devices.remove(deviceName);
      print('Removed $deviceName from _devices (was deleted but still existed)');
    }
    
    // التحقق من عدم وجود جهاز بنفس الاسم في الأجهزة النشطة
    if (_devices.containsKey(deviceName) && !_deletedDevices.contains(deviceName)) {
      throw Exception('يوجد جهاز بهذا الاسم مسبقاً');
    }
    
    // إزالة الجهاز من قائمة المحذوفة إذا كان موجوداً فيها
    if (_deletedDevices.contains(deviceName)) {
      _deletedDevices.remove(deviceName);
      print('Removed $deviceName from deleted devices list');
    }
    
    // إضافة الجهاز
    _devices[deviceName] = DeviceData(name: deviceName);
    print('Added device: $deviceName');
    
    // إضافة أسعار افتراضية للجهاز إذا كان PS4
    if (deviceType == 'PS4') {
      _ps4Prices[deviceName] = {'single': 2000.0, 'multi': 3000.0};
      print('Added PS4 pricing for: $deviceName');
    }
    
    notifyListeners();
    
    // تأخير أطول لتجنب التضارب
    await Future.delayed(const Duration(milliseconds: 500));
    await _saveToPrefs();
    
    print('=== addDevice completed for: $deviceName ===');
  }
  
  // حذف جهاز
  Future<void> removeDevice(String deviceName) async {
    print('=== removeDevice called for: $deviceName ===');
    
    if (!_devices.containsKey(deviceName)) {
      print('Device not found: $deviceName');
      throw Exception('الجهاز غير موجود');
    }
    
    print('Device exists before removal: ${_devices.containsKey(deviceName)}');
    print('Deleted devices before: $_deletedDevices');
    
    // إيقاف المؤقت إذا كان يعمل
    if (_timers[deviceName] != null) {
      _timers[deviceName]!.cancel();
      _timers.remove(deviceName);
    }
    
    // حذف الجهاز
    _devices.remove(deviceName);
    
    // إضافة الجهاز لقائمة المحذوفة
    _deletedDevices.add(deviceName);
    print('Added to deleted devices: $deviceName');
    print('Deleted devices after: $_deletedDevices');
    
    // حذف الأسعار المرتبطة بالجهاز
    _ps4Prices.remove(deviceName);
    
    print('Devices remaining: ${_devices.keys.toList()}');
    
    notifyListeners();
    
    // تأخير صغير لتجنب التضارب
    await Future.delayed(const Duration(milliseconds: 100));
    await _saveToPrefs();
    
    print('removeDevice: Save completed for $deviceName');
    print('=== removeDevice finished for: $deviceName ===');
  }
  
  // تعديل اسم جهاز
  Future<void> renameDevice(String oldName, String newName) async {
    if (!_devices.containsKey(oldName)) {
      throw Exception('الجهاز غير موجود');
    }
    
    if (_devices.containsKey(newName)) {
      throw Exception('يوجد جهاز بهذا الاسم مسبقاً');
    }
    
    // نسخ بيانات الجهاز القديم
    final deviceData = _devices[oldName]!;
    deviceData.name = newName;
    
    // إضافة الجهاز بالاسم الجديد
    _devices[newName] = deviceData;
    
    // نقل المؤقت إذا كان يعمل
    if (_timers[oldName] != null) {
      _timers[newName] = _timers[oldName];
      _timers.remove(oldName);
    }
    
    // نقل الأسعار إذا كانت موجودة
    if (_ps4Prices.containsKey(oldName)) {
      _ps4Prices[newName] = _ps4Prices[oldName]!;
      _ps4Prices.remove(oldName);
    }
    
    // حذف الجهاز القديم
    _devices.remove(oldName);
    
    notifyListeners();
    
    // تأخير صغير لتجنب التضارب
    await Future.delayed(const Duration(milliseconds: 100));
    await _saveToPrefs();
  }
  
  // دالة للترتيب الطبيعي للأسماء مع الأرقام
  int _naturalSort(String a, String b) {
    // استخراج النص والرقم من اسم الجهاز
    // نمط يتعامل مع: "Pc1", "Pc 1", "Arabia1", "Arabia 1", "Table1", "Table 1"
    RegExp regExp = RegExp(r'^([a-zA-Z]+)\s*(\d+)$');
    RegExpMatch? matchA = regExp.firstMatch(a.trim());
    RegExpMatch? matchB = regExp.firstMatch(b.trim());
    
    // إذا كان كلا الاسمين يحتويان على أرقام
    if (matchA != null && matchB != null) {
      String prefixA = matchA.group(1)!.toLowerCase();
      String prefixB = matchB.group(1)!.toLowerCase();
      int numA = int.parse(matchA.group(2)!);
      int numB = int.parse(matchB.group(2)!);
      
      // إذا كان النص متماثلاً، قارن الأرقام
      if (prefixA == prefixB) {
        return numA.compareTo(numB);
      }
      
      // إذا كان النص مختلفاً، قارن النص أولاً
      return prefixA.compareTo(prefixB);
    }
    
    // إذا كان أحد الأسماء أو كليهما لا يحتوي على رقم
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  // الحصول على قائمة بأسماء الأجهزة حسب النوع
  List<String> getDevicesByType(String type) {
    List<String> devices;
    switch (type.toLowerCase()) {
      case 'pc':
        // البحث عن أي جهاز يبدأ بـ Pc أو pc (واستبعاد المحذوفة)
        devices = _devices.keys
            .where((name) => name.toLowerCase().startsWith('pc') && !_deletedDevices.contains(name))
            .toList();
        break;
      case 'ps4':
        // البحث عن أي جهاز يبدأ بـ Arabia أو arabia (للـ PS4) (واستبعاد المحذوفة)
        devices = _devices.keys
            .where((name) => name.toLowerCase().startsWith('arabia') && !_deletedDevices.contains(name))
            .toList();
        break;
      case 'table':
        // البحث عن أي جهاز يبدأ بـ Table أو table (واستبعاد المحذوفة)
        devices = _devices.keys
            .where((name) => name.toLowerCase().startsWith('table') && !_deletedDevices.contains(name))
            .toList();
        break;
      case 'billiard':
        // البحث عن أي جهاز يبدأ بـ Billiard أو billiard (واستبعاد المحذوفة)
        devices = _devices.keys
            .where((name) => name.toLowerCase().startsWith('billiard') && !_deletedDevices.contains(name))
            .toList();
        break;
      default:
        return [];
    }
    
    // ترتيب الأجهزة ترتيباً طبيعياً (الأرقام بشكل صحيح)
    devices.sort(_naturalSort);
    
    //print('getDevicesByType($type): Found ${devices.length} $type devices: $devices');
    
    return devices;
  }
  
  // التحقق من إمكانية حذف جهاز (التأكد من عدم وجود جلسات نشطة)
  bool canDeleteDevice(String deviceName) {
    final device = _devices[deviceName];
    if (device == null) return false;
    
    // لا يمكن حذف الجهاز إذا كان يعمل أو لديه طلبات أو حجوزات
    return !device.isRunning && 
           device.orders.isEmpty && 
           device.reservations.isEmpty;
  }

  // دالة تبديل الثيم
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveToPrefs();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
    _saveToPrefs();
  }

  DeviceData getDeviceData(String name) {
    // لا تنشئ الجهاز إذا كان محذوفاً
    if (_deletedDevices.contains(name)) {
      // في هذه الحالة، قم بإنشاء جهاز مؤقت بدلاً من رمي استثناء
      // هذا لتجنب أخطاء في الواجهة عند الوصول لبيانات جهاز محذوف
      return DeviceData(name: name);
    }
    
    // إنشاء الجهاز فقط إذا لم يكن موجوداً وغير محذوف
    return _devices[name] ??= DeviceData(name: name);
  }

  int getCustomerCount(String deviceName) {
    return getDeviceData(deviceName).customerCount;
  }

  void setCustomerCount(String deviceName, int count) {
    final device = getDeviceData(deviceName);
    device.customerCount = count;
    notifyListeners();
    _saveToPrefs();
  }

  void startTimer(String deviceName) {
    if (_timers[deviceName] != null) return;
    final device = getDeviceData(deviceName);
    device.isRunning = true;
    
    print('⏰ بدء المؤقت للجهاز: $deviceName');

    // عداد للحفظ كل 30 ثانية بدلاً من كل ثانية
    var saveCounter = 0;
    
    _timers[deviceName] = Timer.periodic(const Duration(seconds: 1), (_) {
      device.elapsedTime += const Duration(seconds: 1);
      saveCounter++;
      
      notifyListeners();
      
      // حفظ كل 30 ثانية أو عند الدقائق المهمة (5، 10، 15 دقيقة)
      final minutes = device.elapsedTime.inMinutes;
      if (saveCounter >= 30 || minutes % 5 == 0 && device.elapsedTime.inSeconds % 60 == 0) {
        _saveToPrefs();
        saveCounter = 0;
        print('💾 حفظ تلقائي للمؤقت: $deviceName - الوقت: ${device.elapsedTime.toString().substring(0, 7)}');
      }
    });

    // حفظ فوري عند بدء المؤقت
    notifyListeners();
    _saveToPrefs();
    print('✅ تم بدء وحفظ المؤقت: $deviceName');
  }

  void stopTimer(String deviceName) {
    final device = getDeviceData(deviceName);
    device.isRunning = false;
    _timers[deviceName]?.cancel();
    _timers.remove(deviceName);
    
    print('⏸️ إيقاف المؤقت للجهاز: $deviceName - إجمالي الوقت: ${device.elapsedTime.toString().substring(0, 7)}');
    
    // حفظ فوري + طارئ عند إيقاف المؤقت (مهم جداً!)
    notifyListeners();
    _saveToPrefs();
    _emergencySave();
    
    print('✅ تم حفظ إيقاف المؤقت: $deviceName');
  }

  void resetTimerOnly(String deviceName) {
    final device = getDeviceData(deviceName);
    device.elapsedTime = Duration.zero;
    device.isRunning = false;
    _timers[deviceName]?.cancel();
    _timers.remove(deviceName);
    notifyListeners();
    _saveToPrefs();
  }

  Duration getElapsedTime(String deviceName) {
    return getDeviceData(deviceName).elapsedTime;
  }

  bool isRunning(String deviceName) {
    return getDeviceData(deviceName).isRunning;
  }

  List<OrderItem> getOrders(String deviceName) {
    return getDeviceData(deviceName).orders;
  }

  void addOrUpdateOrder(String deviceName, OrderItem newOrder) {
    final device = getDeviceData(deviceName);
    var orders = device.orders;
    int index = orders.indexWhere((o) => o.name == newOrder.name);
    if (index >= 0) {
      final existing = orders[index];
      existing.quantity += newOrder.quantity;
      existing.lastOrderTime = DateTime.now();
    } else {
      orders.add(newOrder);
    }
    notifyListeners();
    _saveToPrefs();
  }

  /// إضافة عدة طلبات دفعة واحدة
  void addOrders(String deviceName, List<OrderItem> newOrders) {
    final device = getDeviceData(deviceName);
    for (var newOrder in newOrders) {
      int index = device.orders.indexWhere((o) => o.name == newOrder.name);
      if (index >= 0) {
        final existing = device.orders[index];
        existing.quantity += newOrder.quantity;
        existing.lastOrderTime = DateTime.now();
      } else {
        device.orders.add(newOrder);
      }
    }
    notifyListeners();
    _saveToPrefs();
  }

  void removeOrder(String deviceName, OrderItem order) {
    final device = getDeviceData(deviceName);
    device.orders.remove(order);
    notifyListeners();
    _saveToPrefs();
  }

  void removeOrderByIndex(String deviceName, int index) {
    final device = getDeviceData(deviceName);
    if (index >= 0 && index < device.orders.length) {
      device.orders.removeAt(index);
      notifyListeners();
      _saveToPrefs();
    }
  }

  void updateOrder(String deviceName, int index, OrderItem updatedOrder) {
    final device = getDeviceData(deviceName);
    if (index >= 0 && index < device.orders.length) {
      device.orders[index] = updatedOrder;
      notifyListeners();
      _saveToPrefs();
    }
  }

  // طرق إدارة الحجوزات
  List<ReservationItem> getReservations(String deviceName) {
    return getDeviceData(deviceName).reservations;
  }

  void addReservation(String deviceName, ReservationItem reservation) {
  final device = getDeviceData(deviceName);
  device.reservations.add(reservation);
  _allReservations.add(reservation);
  notifyListeners();
  _saveToPrefs();
  }

  void removeReservationByIndex(String deviceName, int index) {
    final device = getDeviceData(deviceName);
    if (index >= 0 && index < device.reservations.length) {
      final removed = device.reservations.removeAt(index);
      _allReservations.remove(removed);
      notifyListeners();
      _saveToPrefs();
    }
  }

  void updateReservation(String deviceName, int index, ReservationItem updatedReservation) {
    final device = getDeviceData(deviceName);
    if (index >= 0 && index < device.reservations.length) {
      _allReservations.remove(device.reservations[index]);
      device.reservations[index] = updatedReservation;
      _allReservations.add(updatedReservation);
      notifyListeners();
      _saveToPrefs();
    }
  }

  void clearDevice(String deviceName) {
    print('=== clearDevice called for: $deviceName ===');
    print('Device exists before removal: ${_devices.containsKey(deviceName)}');
    print('Deleted devices before: $_deletedDevices');
    
    _timers[deviceName]?.cancel();
    _timers.remove(deviceName);
    
    // التأكد من حذف الجهاز نهائياً من _devices
    _devices.remove(deviceName);
    print('Device removed from _devices. Still exists: ${_devices.containsKey(deviceName)}');
    
    // إضافة الجهاز لقائمة المحذوفة لمنع إعادة إنشائه
    _deletedDevices.add(deviceName);
    print('Added to deleted devices: $deviceName');
    print('Deleted devices after: $_deletedDevices');
    
    // حذف الأسعار المرتبطة بالجهاز
    _ps4Prices.remove(deviceName);
    
    print('Devices remaining: ${_devices.keys.toList()}');
    
    notifyListeners();
    
    // حفظ فوري ومتزامن
    _saveToPrefs().then((_) {
      print('clearDevice: Save completed for $deviceName');
      print('Final check - Device exists in _devices: ${_devices.containsKey(deviceName)}');
    }).catchError((error) {
      print('clearDevice: Save failed for $deviceName: $error');
    });
    
    print('=== clearDevice finished for: $deviceName ===');
  }

  // وظيفة جديدة لتصفير الطاولة دون حذفها
  void resetDevice(String deviceName) {
    print('=== resetDevice called for: $deviceName ===');
    
    // إيقاف العداد إذا كان يعمل
    _timers[deviceName]?.cancel();
    _timers.remove(deviceName);
    
    // الحصول على بيانات الجهاز
    final device = getDeviceData(deviceName);
    
    // تصفير جميع البيانات مع الحفاظ على الجهاز
    device.orders.clear();
    device.reservations.clear();
    device.isRunning = false;
    device.elapsedTime = Duration.zero;
    device.notes = '';
    device.mode = 'single'; // إعادة تعيين الوضع إلى فردي
    device.customerCount = 1; // إعادة تعيين عدد الزبائن إلى 1
    
    print('Device $deviceName reset successfully');
    print('Orders: ${device.orders.length}, Reservations: ${device.reservations.length}');
    print('IsRunning: ${device.isRunning}, ElapsedTime: ${device.elapsedTime}');
    print('Mode: ${device.mode}, CustomerCount: ${device.customerCount}');
    
    notifyListeners();
    
    // حفظ البيانات
    _saveToPrefs().then((_) {
      print('resetDevice: Save completed for $deviceName');
    }).catchError((error) {
      print('resetDevice: Save failed for $deviceName: $error');
    });
    
    print('=== resetDevice finished for: $deviceName ===');
  }

  Future<bool> clearAllDevicesWithConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text(
            'هل أنت متأكد من تفريغ جميع الطاولات؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      clearAllDevices();
      return true;
    }
    return false;
  }

  void clearAllDevices() {
    for (var deviceName in _devices.keys.toList()) {
      _timers[deviceName]?.cancel();
      _timers.remove(deviceName);
      _devices.remove(deviceName);
      
      // إضافة الجهاز لقائمة المحذوفة لمنع إعادة إنشائه
      _deletedDevices.add(deviceName);
      
      // حذف الأسعار المرتبطة بالجهاز
      _ps4Prices.remove(deviceName);
    }
    notifyListeners();
    _saveToPrefs();
  }

  String getNote(String deviceName) {
    return getDeviceData(deviceName).notes;
  }

  void setNote(String deviceName, String note) {
    final device = getDeviceData(deviceName);
    device.notes = note;
    notifyListeners();
    _saveToPrefs();
  }

  String getMode(String deviceName) {
    return getDeviceData(deviceName).mode;
  }

  void setMode(String deviceName, String newMode) {
    final device = getDeviceData(deviceName);
    print('=== setMode called ===');
    print('Device: $deviceName');
    print('Old Mode: ${device.mode}');
    print('New Mode: $newMode');
    device.mode = newMode;
    print('Mode set successfully: ${device.mode}');
    notifyListeners();
    _saveToPrefs();
  }

  void transferDeviceData(String fromDevice, String toDevice) {
    if (!_devices.containsKey(fromDevice)) return;
    final fromData = _devices[fromDevice]!;
    final toData = _devices[toDevice] ?? DeviceData(name: toDevice);

    toData.elapsedTime = fromData.elapsedTime;
    toData.isRunning = fromData.isRunning;

    for (var order in fromData.orders) {
      int index = toData.orders.indexWhere((o) => o.name == order.name);
      if (index >= 0) {
        toData.orders[index].quantity += order.quantity;
        toData.orders[index].lastOrderTime = DateTime.now();
      } else {
        toData.orders.add(order);
      }
    }

    toData.notes = fromData.notes;
    toData.mode = fromData.mode;
    toData.customerCount = fromData.customerCount;

    _devices.remove(fromDevice);
    _devices[toDevice] = toData;

    _timers[fromDevice]?.cancel();
    _timers.remove(fromDevice);

    if (toData.isRunning) {
      startTimer(toDevice);
    }

    notifyListeners();
    _saveToPrefs();
  }

  static Future<Box> _getBox() async {
    // تجنب المحاولات المتعددة المتزامنة
    if (_isStaticSaving) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _getBox(); // إعادة المحاولة
    }
    
    try {
      // إذا كان لدينا صندوق مهيأ ومفتوح، استخدمه
      if (_sharedBox != null && _sharedBox!.isOpen) {
        print('استخدام الصندوق المفتوح مسبقاً: ${_sharedBox!.name}');
        return _sharedBox!;
      }
      
      // إغلاق أي صندوق قديم
      if (_sharedBox != null && _sharedBox!.isOpen) {
        await _sharedBox!.close();
        print('تم إغلاق الصندوق القديم');
      }
      
  // فتح Box جديد باسم ثابت لضمان حفظ البيانات بشكل صحيح
  const boxName = 'safeDevicesBox';
  print('محاولة فتح $boxName...');
  _sharedBox = await Hive.openBox(boxName);
  _isBoxInitialized = true;
  print('✅ تم فتح $boxName بنجاح في المسار الآمن');
  return _sharedBox!;
      
    } catch (e) {
      print('Error opening box: $e');
      
      // معالجة مشاكل ملفات القفل
      if (e.toString().contains('PathAccessException') || 
          e.toString().contains('lock failed') ||
          e.toString().contains('cannot access the file')) {
        
        print('Lock file issue detected in _getBox, waiting...');
        // انتظار قصير ومحاولة مع Box مختلف
        await Future.delayed(const Duration(milliseconds: 200));
        
        try {
          // محاولة فتح نفس الصندوق الثابت كحل طارئ
          const fallbackBoxName = 'safeDevicesBox';
          print('🚨 محاولة فتح صندوق الطوارئ: $fallbackBoxName');
          _sharedBox = await Hive.openBox(fallbackBoxName);
          _isBoxInitialized = true;
          print('✅ تم فتح صندوق الطوارئ بنجاح: $fallbackBoxName');
          return _sharedBox!;
        } catch (fallbackError) {
          print('Fallback box also failed: $fallbackError');
          // كحل أخير، استخدام SharedPreferences
          throw Exception('Hive completely unavailable, falling back to SharedPreferences');
        }
      } else {
        // أخطاء أخرى غير متعلقة بملفات القفل
        _sharedBox = null;
        _isBoxInitialized = false;
        throw e;
      }
    }
  }

  Future<void> _saveToPrefs() async {
    // تجنب الحفظ المتزامن
    if (_isSaving) return;
    _isSaving = true;
    
    // محاولة الحفظ مع Hive أولاً، وإذا فشل استخدام SharedPreferences
    bool hiveSaveSuccess = false;
    
    // 🚀 نظام الحفظ المحسن - حفظ فوري مع البيانات الأساسية
    try {
      final allData = {
        'devices': _devices.map((key, value) => MapEntry(key, value.toJson())),
        'pcPrice': _pcPrice,
        'ps4Prices': _ps4Prices,
        'pcPrices': _pcPrices,
        'tablePrices': _tablePrices,
        'billiardPrices': _billiardPrices,
        'orderPrices': _orderPrices,
        'customCategories': _customCategories,
        'defaultCategoryNames': _defaultCategoryNames,
        'todayExpenses': _todayExpenses,
        'manualRevenues': _manualRevenues,
        'completedMonths': _completedMonths.toList(),
        'debts': _debts,
        'deletedDevices': _deletedDevices.toList(),
        'isDarkMode': _isDarkMode,
        'lastSaveTime': DateTime.now().toIso8601String(),
      };
      
      // حفظ فوري في نظام الحفظ المحسن
      await DataPersistenceManager().saveAllData(allData);
    } catch (e) {
      print('خطأ في النظام المحسن: $e');
    }
    
    Box? box;
    try {
      // استخدام الدالة الآمنة للحصول على Box
      box = await _getBox();
      
      // التأكد من أن Box مفتوح
      if (!box.isOpen) {
        print('Warning: Box is not open, trying to reopen...');
        // إعادة تعيين وإعادة فتح
        _sharedBox = null;
        _isBoxInitialized = false;
        box = await _getBox();
      }
      
  final data = _devices.map((key, value) => MapEntry(key, value.toJson()));
  await box.put('devicesData', jsonEncode(data));
  // حفظ الحجوزات بشكل مستقل
  await box.put('reservationsData', jsonEncode(_allReservations.map((e) => e.toJson()).toList()));
      
      // حفظ الأسعار
      final pricesData = {
        'pcPrice': _pcPrice,
        'ps4Prices': _ps4Prices,
        'pcPrices': _pcPrices,
        'tablePrices': _tablePrices,
        'billiardPrices': _billiardPrices,
      };
      await box.put('pricesData', jsonEncode(pricesData));
      
      // حفظ أسعار الطلبات
      await box.put('orderPricesData', jsonEncode(_orderPrices));
    
      // حفظ الأقسام المخصصة
      await box.put('customCategoriesData', jsonEncode(_customCategories));
      
      // حفظ أسماء الأقسام الافتراضية
      await box.put('defaultCategoryNamesData', jsonEncode(_defaultCategoryNames));
      
      // حفظ المصروفات
      await box.put('todayExpensesData', jsonEncode(_todayExpenses));
      
      // حفظ الإيرادات اليدوية
      await box.put('manualRevenuesData', jsonEncode(_manualRevenues));
      
      // حفظ الأشهر المكتملة
      await box.put('completedMonthsData', jsonEncode(_completedMonths.toList()));
      
      // حفظ بيانات الأشهر المكتملة الكاملة
      await box.put('monthlyDataMap', jsonEncode(_monthlyData));
      
      // حفظ الديون
      await box.put('debtsData', jsonEncode(_debts));
      
      // حفظ قائمة الأجهزة المحذوفة
      await box.put('deletedDevicesData', jsonEncode(_deletedDevices.toList()));
      
      // حفظ إعدادات الثيم
      await box.put('isDarkMode', _isDarkMode);
      
      hiveSaveSuccess = true;
      _lastSaveTime = DateTime.now(); // تسجيل وقت الحفظ
      print('✅ حفظ Hive ناجح في ${_lastSaveTime.toString().substring(11, 19)}');
      
      // لا نغلق الصندوق هنا لتجنب مشاكل الوصول المتزامن
    } catch (e) {
      print('Error saving to Hive: $e');
      
      // معالجة أخطاء ملفات القفل
      if (e.toString().contains('PathAccessException') || 
          e.toString().contains('cannot access the file') ||
          e.toString().contains('lock') ||
          e.toString().contains('Hive completely unavailable')) {
        print('Hive unavailable, using SharedPreferences backup immediately...');
        
        // تخطي محاولة الاسترداد واستخدام SharedPreferences مباشرة
        hiveSaveSuccess = false;
        
        // إعادة تعيين متغيرات Hive
        try {
          if (_sharedBox != null && _sharedBox!.isOpen) {
            await _sharedBox!.close();
          }
        } catch (closeError) {
          print('Error closing box during recovery: $closeError');
        }
        
        _sharedBox = null;
        _isBoxInitialized = false;
      } else {
        // أخطاء أخرى
        _sharedBox = null;
        _isBoxInitialized = false;
      }
    } finally {
      // إذا فشل حفظ Hive، استخدام SharedPreferences كبديل
      if (!hiveSaveSuccess) {
        try {
          await _saveToSharedPrefs();
          print('Fallback to SharedPreferences successful');
        } catch (e) {
          print('SharedPreferences fallback also failed: $e');
        }
      }
      _isSaving = false;
    }
  }

  // دالة حفظ احتياطية باستخدام SharedPreferences
  Future<void> _saveToSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ البيانات الأساسية فقط
      final data = _devices.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('devicesData_backup', jsonEncode(data));
      
      // حفظ الأسعار
      final pricesData = {
        'pcPrice': _pcPrice,
        'ps4Prices': _ps4Prices,
        'pcPrices': _pcPrices,
        'tablePrices': _tablePrices,
        'billiardPrices': _billiardPrices,
      };
      await prefs.setString('pricesData_backup', jsonEncode(pricesData));
      
      // حفظ إعدادات الثيم
      await prefs.setBool('isDarkMode_backup', _isDarkMode);
      
      print('SharedPreferences backup save completed');
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
    }
  }

  void _saveSelectedMonthToPrefs(String monthId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedMonth', monthId);
      print('✅ تم حفظ الشهر المختار: $monthId');
    } catch (e) {
      print('Error saving selected month: $e');
    }
  }

  Future<String?> getSelectedMonth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selectedMonth');
    } catch (e) {
      print('Error loading selected month: $e');
      return null;
    }
  }

  Future<void> _loadFromPrefs() async {
    // استرجاع الحجوزات المستقلة
    final boxReservations = await _getBox();
    final reservationsString = boxReservations.get('reservationsData');
    if (reservationsString != null) {
      final List<dynamic> reservationsData = jsonDecode(reservationsString);
      _allReservations = reservationsData.map((e) => ReservationItem.fromJson(e)).toList();
    }
    bool hiveLoadSuccess = false;
    
    // 🚀 محاولة تحميل من النظام المحسن أولاً
    try {
      final savedData = await DataPersistenceManager().loadAllData();
      if (savedData != null) {
        await _loadFromSavedData(savedData);
        print('✅ تم تحميل البيانات من النظام المحسن بنجاح!');
        hiveLoadSuccess = true;
      }
    } catch (e) {
      print('تحذير النظام المحسن: $e');
    }
    
    // إذا فشل النظام المحسن، استخدام Hive التقليدي
    if (!hiveLoadSuccess) {
      try {
        // استخدام الدالة الآمنة للحصول على Box
        final box = await _getBox();
      final jsonString = box.get('devicesData');
      if (jsonString != null) {
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        _devices = jsonData.map((key, value) =>
            MapEntry(key, DeviceData.fromJson(value as Map<String, dynamic>)));

        for (var entry in _devices.entries) {
          if (entry.value.isRunning) {
            startTimer(entry.key);
          }
        }
      }
    
    // تحميل الأسعار
    final pricesString = box.get('pricesData');
    if (pricesString != null) {
      final Map<String, dynamic> pricesData = jsonDecode(pricesString);
      _pcPrice = pricesData['pcPrice']?.toDouble() ?? 1500;
      
      // تحميل أسعار PS4 الجديدة أو استخدام القيم الافتراضية
      if (pricesData['ps4Prices'] != null) {
        final Map<String, dynamic> savedPs4Prices = Map<String, dynamic>.from(pricesData['ps4Prices']);
        _ps4Prices.clear();
        savedPs4Prices.forEach((deviceName, prices) {
          _ps4Prices[deviceName] = Map<String, double>.from(prices);
        });
      }
      
      // تحميل أسعار PC الفردية
      if (pricesData['pcPrices'] != null) {
        _pcPrices = Map<String, double>.from(pricesData['pcPrices']);
      }
      
      // تحميل أسعار الطاولات الفردية
      if (pricesData['tablePrices'] != null) {
        _tablePrices = Map<String, double>.from(pricesData['tablePrices']);
      }
      
      // تحميل أسعار البيليارد الفردية
      if (pricesData['billiardPrices'] != null) {
        _billiardPrices = Map<String, double>.from(pricesData['billiardPrices']);
      }
    }
    
    // تحميل أسعار الطلبات
    final orderPricesString = box.get('orderPricesData');
    if (orderPricesString != null) {
      final Map<String, dynamic> orderPricesData = jsonDecode(orderPricesString);
      _orderPrices.addAll(orderPricesData.map((key, value) => MapEntry(key, value.toDouble())));
    }
    
    // تحميل الأقسام المخصصة
    final customCategoriesString = box.get('customCategoriesData');
    if (customCategoriesString != null) {
      final Map<String, dynamic> customCategoriesData = jsonDecode(customCategoriesString);
      _customCategories = customCategoriesData.map((key, value) => 
        MapEntry(key, List<String>.from(value)));
    }
    
    // تحميل أسماء الأقسام الافتراضية
    final defaultCategoryNamesString = box.get('defaultCategoryNamesData');
    if (defaultCategoryNamesString != null) {
      final Map<String, dynamic> defaultCategoryNamesData = jsonDecode(defaultCategoryNamesString);
      _defaultCategoryNames.addAll(defaultCategoryNamesData.map((key, value) => MapEntry(key, value.toString())));
    }
    
    // تحميل المصروفات
    final expensesString = box.get('todayExpensesData');
    if (expensesString != null) {
      final List<dynamic> expensesData = jsonDecode(expensesString);
      _todayExpenses = List<Map<String, dynamic>>.from(expensesData);
    }
    
    // تحميل الإيرادات اليدوية
    final revenuesString = box.get('manualRevenuesData');
    if (revenuesString != null) {
      final List<dynamic> revenuesData = jsonDecode(revenuesString);
      _manualRevenues = List<Map<String, dynamic>>.from(revenuesData);
    }
    
    // تحميل الأشهر المكتملة
    final completedMonthsString = box.get('completedMonthsData');
    if (completedMonthsString != null) {
      final List<dynamic> completedMonthsData = jsonDecode(completedMonthsString);
      _completedMonths = Set<String>.from(completedMonthsData);
    }
    
    // تحميل بيانات الأشهر المكتملة
    final monthlyDataString = box.get('monthlyDataMap');
    if (monthlyDataString != null) {
      final Map<String, dynamic> monthlyDataRaw = jsonDecode(monthlyDataString);
      _monthlyData = monthlyDataRaw.map((key, value) => 
        MapEntry(key, Map<String, dynamic>.from(value as Map))
      );
    }
    
    // تحميل الديون
    final debtsString = box.get('debtsData');
    if (debtsString != null) {
      final List<dynamic> debtsData = jsonDecode(debtsString);
      _debts = List<Map<String, dynamic>>.from(debtsData);
    }
    
      // تحميل قائمة الأجهزة المحذوفة
      final deletedDevicesString = box.get('deletedDevicesData');
      if (deletedDevicesString != null) {
        final List<dynamic> deletedDevicesData = jsonDecode(deletedDevicesString);
        _deletedDevices = Set<String>.from(deletedDevicesData);
        print('=== LOADED DELETED DEVICES: $_deletedDevices ===');
      } else {
        print('=== NO DELETED DEVICES DATA FOUND - STARTING FRESH ===');
        _deletedDevices = <String>{};
      }      // تحميل إعدادات الثيم
      _isDarkMode = box.get('isDarkMode', defaultValue: true);
      
      // لا نغلق الصندوق هنا ليبقى متاحاً للاستخدام
      
      // إنشاء الأجهزة الافتراضية إذا لم توجد أي أجهزة
      _ensureDefaultDevices();
      
      hiveLoadSuccess = true;
      print('Hive load successful');
      
      notifyListeners();
      } catch (e) {
        // في حالة حدوث خطأ، استخدم القيم الافتراضية
        print('Error loading from Hive: $e');
        hiveLoadSuccess = false;
      }
    }

    // إذا فشل تحميل Hive، حاول من SharedPreferences
    if (!hiveLoadSuccess) {
      try {
        await _loadFromSharedPrefs();
        print('Fallback load from SharedPreferences successful');
      } catch (e) {
        print('SharedPreferences fallback load also failed: $e');
        // إنشاء الأجهزة الافتراضية كحل أخير
        _ensureDefaultDevices();
      }
      
      notifyListeners();
    }
  }

  // دالة تحميل احتياطية من SharedPreferences
  Future<void> _loadFromSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل البيانات الأساسية
      final jsonString = prefs.getString('devicesData_backup');
      if (jsonString != null) {
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        _devices = jsonData.map((key, value) =>
            MapEntry(key, DeviceData.fromJson(value as Map<String, dynamic>)));

        for (var entry in _devices.entries) {
          if (entry.value.isRunning) {
            startTimer(entry.key);
          }
        }
      }
      
      // تحميل الأسعار
      final pricesString = prefs.getString('pricesData_backup');
      if (pricesString != null) {
        final Map<String, dynamic> pricesData = jsonDecode(pricesString);
        _pcPrice = pricesData['pcPrice'] ?? 1500.0;
        
        if (pricesData['ps4Prices'] != null) {
          _ps4Prices = Map<String, Map<String, double>>.from(
            (pricesData['ps4Prices'] as Map).map((key, value) => 
              MapEntry(key, Map<String, double>.from(value))
            )
          );
        }
        
        if (pricesData['pcPrices'] != null) {
          _pcPrices = Map<String, double>.from(pricesData['pcPrices']);
        }
        
        if (pricesData['tablePrices'] != null) {
          _tablePrices = Map<String, double>.from(pricesData['tablePrices']);
        }
        
        if (pricesData['billiardPrices'] != null) {
          _billiardPrices = Map<String, double>.from(pricesData['billiardPrices']);
        }
      }
      
      // تحميل إعدادات الثيم
      _isDarkMode = prefs.getBool('isDarkMode_backup') ?? true;
      
      // إنشاء الأجهزة الافتراضية إذا لم توجد أي أجهزة
      _ensureDefaultDevices();
      
      print('SharedPreferences backup load completed');
    } catch (e) {
      print('Error loading from SharedPreferences: $e');
      throw e;
    }
  }
  
  void _ensureDefaultDevices() {
    print('=== _ensureDefaultDevices called ===');
    print('Current deleted devices at start: $_deletedDevices');
    print('Current devices count: ${_devices.length}');
    
    // إنشاء الأجهزة الافتراضية إذا لم توجد (وتجنب المحذوفة)
    bool shouldSave = false;
    
    // إنشاء أجهزة PC
    for (int i = 1; i <= 16; i++) {
      final deviceName = 'Pc $i';
      if (!_devices.containsKey(deviceName) && !_deletedDevices.contains(deviceName)) {
        print('Creating PC: $deviceName');
        _devices[deviceName] = DeviceData(name: deviceName);
        shouldSave = true;
      } else if (_deletedDevices.contains(deviceName)) {
        print('Skipping deleted PC: $deviceName');
      }
    }
    
    // إنشاء أجهزة PS4
    for (int i = 1; i <= 8; i++) {
      final deviceName = 'Arabia $i';
      if (!_devices.containsKey(deviceName) && !_deletedDevices.contains(deviceName)) {
        print('Creating PS4: $deviceName');
        _devices[deviceName] = DeviceData(name: deviceName);
        // إضافة أسعار افتراضية للPS4
        _ps4Prices[deviceName] = {'single': 2000.0, 'multi': 3000.0};
        shouldSave = true;
      } else if (_deletedDevices.contains(deviceName)) {
        print('Skipping deleted PS4: $deviceName');
      }
    }
    
    // إنشاء طاولات
    for (int i = 1; i <= 6; i++) {
      final deviceName = 'Table $i';
      if (!_devices.containsKey(deviceName) && !_deletedDevices.contains(deviceName)) {
        print('Creating default table: $deviceName');
        _devices[deviceName] = DeviceData(name: deviceName);
        shouldSave = true;
      } else if (_deletedDevices.contains(deviceName)) {
        print('Skipping deleted table: $deviceName');
      } else if (_devices.containsKey(deviceName)) {
        print('Table already exists: $deviceName');
      }
    }
    
    print('Devices after creation: ${_devices.keys.toList()}');
    print('Should save: $shouldSave');
    
    // حفظ الأجهزة الجديدة إذا تم إضافة أي منها
    if (shouldSave) {
      print('Saving new devices...');
      _saveToPrefs();
    }
    
    print('=== _ensureDefaultDevices finished ===');
  }

  double calculatePrice(String deviceName, Duration elapsed, String mode) {
    double ratePerHour = 0;

    if (deviceName.startsWith('Pc')) {
      // استخدام السعر الفردي للجهاز PC
      ratePerHour = getPcPrice(deviceName);
    } else if (deviceName.startsWith('Arabia')) {
      // استخدام البنية الجديدة لأسعار PS4
      ratePerHour = getPs4Price(deviceName, mode);
      print('calculatePrice for $deviceName: mode=$mode, rate=$ratePerHour');
    } else if (deviceName.startsWith('Table')) {
      // استخدام السعر الفردي للطاولة
      ratePerHour = getTablePrice(deviceName);
    } else if (deviceName.startsWith('Billiard')) {
      // استخدام السعر الفردي للبيليارد
      ratePerHour = getBilliardPrice(deviceName);
    } else {
      ratePerHour = 0;
    }

    double price = (elapsed.inSeconds / 3600.0) * ratePerHour;
    return price;
  }
  
  static Future<void> safeCloseBox() async {
    try {
      if (_sharedBox != null && _sharedBox!.isOpen) {
        await _sharedBox!.close();
        _sharedBox = null;
        _isBoxInitialized = false;
      }
    } catch (e) {
      print('Error safely closing box: $e');
    }
  }

  // دالة تحميل البيانات من النظام المحسن
  Future<void> _loadFromSavedData(Map<String, dynamic> data) async {
    try {
      // تحميل الأجهزة
      if (data['devices'] != null) {
        final devicesData = Map<String, dynamic>.from(data['devices']);
        _devices = devicesData.map((key, value) =>
            MapEntry(key, DeviceData.fromJson(Map<String, dynamic>.from(value))));
        
        // إعادة تشغيل المؤقتات للأجهزة العاملة
        for (var entry in _devices.entries) {
          if (entry.value.isRunning) {
            startTimer(entry.key);
          }
        }
      }
      
      // تحميل الأسعار
      _pcPrice = (data['pcPrice'] ?? 1500.0).toDouble();
      
      if (data['ps4Prices'] != null) {
        _ps4Prices.clear();
        final ps4Data = Map<String, dynamic>.from(data['ps4Prices']);
        ps4Data.forEach((deviceName, prices) {
          _ps4Prices[deviceName] = Map<String, double>.from(prices);
        });
      }
      
      if (data['pcPrices'] != null) {
        _pcPrices = Map<String, double>.from(data['pcPrices']);
      }
      
      if (data['tablePrices'] != null) {
        _tablePrices = Map<String, double>.from(data['tablePrices']);
      }
      
      if (data['billiardPrices'] != null) {
        _billiardPrices = Map<String, double>.from(data['billiardPrices']);
      }
      
      if (data['orderPrices'] != null) {
        _orderPrices = Map<String, double>.from(data['orderPrices']);
      }
      
      // تحميل الأقسام المخصصة
      if (data['customCategories'] != null) {
        final categoriesData = Map<String, dynamic>.from(data['customCategories']);
        _customCategories = categoriesData.map((key, value) => 
            MapEntry(key, List<String>.from(value)));
      }
      
      // تحميل أسماء الأقسام الافتراضية
      if (data['defaultCategoryNames'] != null) {
        _defaultCategoryNames = Map<String, String>.from(data['defaultCategoryNames']);
      }
      
      // تحميل المصروفات
      if (data['todayExpenses'] != null) {
        _todayExpenses = List<Map<String, dynamic>>.from(data['todayExpenses']);
      }
      
      // تحميل الإيرادات اليدوية
      if (data['manualRevenues'] != null) {
        _manualRevenues = List<Map<String, dynamic>>.from(data['manualRevenues']);
      }
      
      // تحميل الأشهر المكتملة
      if (data['completedMonths'] != null) {
        _completedMonths = Set<String>.from(data['completedMonths']);
      }
      
      // تحميل الديون
      if (data['debts'] != null) {
        _debts = List<Map<String, dynamic>>.from(data['debts']);
      }
      
      // تحميل الأجهزة المحذوفة
      if (data['deletedDevices'] != null) {
        _deletedDevices = Set<String>.from(data['deletedDevices']);
        print('✅ تم تحميل الأجهزة المحذوفة: $_deletedDevices');
      }
      
      // تحميل المصروفات
      if (data['todayExpenses'] != null) {
        _todayExpenses = List<Map<String, dynamic>>.from(data['todayExpenses']);
        print('✅ تم تحميل المصروفات: ${_todayExpenses.length} مصروف');
      }
      
      // تحميل الإيرادات اليدوية
      if (data['manualRevenues'] != null) {
        _manualRevenues = List<Map<String, dynamic>>.from(data['manualRevenues']);
        print('✅ تم تحميل الإيرادات: ${_manualRevenues.length} إيراد');
      }
      
      // تحميل الأشهر المكتملة
      if (data['completedMonths'] != null) {
        _completedMonths = Set<String>.from(data['completedMonths']);
        print('✅ تم تحميل الأشهر المكتملة: ${_completedMonths.length} شهر');
      }
      
      // تحميل الديون
      if (data['debts'] != null) {
        _debts = List<Map<String, dynamic>>.from(data['debts']);
        print('✅ تم تحميل الديون: ${_debts.length} دين');
      }
      
      // تحميل إعدادات الثيم
      _isDarkMode = data['isDarkMode'] ?? true;
      
      print('✅ تم تحميل جميع البيانات من النظام المحسن');
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    // 🔒 حفظ طارئ نهائي قبل الإغلاق
    print('🔄 بدء الحفظ الطارئ النهائي...');
    _emergencySave();
    
    // إيقاف جميع المؤقتات
    _timers.values.forEach((timer) => timer?.cancel());
    _timers.clear();
    
    // إغلاق صناديق Hive إذا كانت مفتوحة
    safeCloseBox();
    
    super.dispose();
  }

  // 🚨 حفظ طارئ شامل وآمن - يحفظ كل شيء!
  void _emergencySave() {
    try {
      print('🔥 بدء الحفظ الطارئ الشامل - جميع البيانات!');
      
      // ✅ جمع جميع البيانات الحرجة بدون استثناء
      final allData = {
        // 🏢 بيانات الأجهزة والطاولات
        'devices': _devices.map((key, value) => MapEntry(key, value.toJson())),
        'deletedDevices': _deletedDevices.toList(),
        
        // 💰 جميع أنواع الأسعار
        'pcPrice': _pcPrice,
        'ps4Prices': _ps4Prices,
        'pcPrices': _pcPrices,
        'tablePrices': _tablePrices,
        'billiardPrices': _billiardPrices,
        'orderPrices': _orderPrices,
        
        // 📂 الأقسام والفئات المخصصة
        'customCategories': _customCategories,
        'defaultCategoryNames': _defaultCategoryNames,
        
        // 💸 المصروفات والإيرادات
        'todayExpenses': _todayExpenses,
        'manualRevenues': _manualRevenues,
        
        // 📅 البيانات التاريخية
        'completedMonths': _completedMonths.toList(),
        'debts': _debts,
        
        // ⚙️ الإعدادات
        'isDarkMode': _isDarkMode,
        
        // 🕐 معلومات الحفظ
        'emergencySave': true,
        'saveTime': DateTime.now().toIso8601String(),
        'dataIntegrity': 'complete_backup',
      };
      
      DataPersistenceManager().saveAllData(allData).timeout(const Duration(seconds: 3));
      print('✅ تم الحفظ الطارئ المحسن بنجاح');
    } catch (e) {
      // إذا فشل، استخدم الطريقة القديمة
      try {
        _saveToSharedPrefs().timeout(const Duration(seconds: 2));
        print('✅ تم الحفظ الطارئ التقليدي بنجاح');
      } catch (e2) {
        print('⚠️ تحذير: فشل جميع أنظمة الحفظ الطارئ: $e2');
      }
    }
  }
}
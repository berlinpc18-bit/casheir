




import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'printer_service.dart';
import 'api_sync_manager.dart'; // Add import
import 'package:uuid/uuid.dart';
import 'websocket_manager.dart';
import 'api_sync_manager.dart';

class OrderItem {
  String id;
  String name;
  double price;
  int quantity;
  DateTime firstOrderTime;
  DateTime lastOrderTime;
  String? notes;

  OrderItem({
    String? id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.firstOrderTime,
    required this.lastOrderTime,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        // Truncate to seconds to match server precision and avoid duplicate detection failure
        'firstOrderTime': firstOrderTime.toIso8601String().split('.')[0], 
        'lastOrderTime': lastOrderTime.toIso8601String().split('.')[0],
        'notes': notes,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id']?.toString(), // Use existing ID if available
        name: json['name']?.toString() ?? 'Error',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        firstOrderTime: json['firstOrderTime'] != null 
            ? DateTime.parse(json['firstOrderTime']) 
            : DateTime.now(),
        lastOrderTime: json['lastOrderTime'] != null 
            ? DateTime.parse(json['lastOrderTime']) 
            : DateTime.now(),
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
        'time': elapsedTime.inSeconds,
        'isRunning': isRunning,
        'orders': orders.map((e) => e.toJson()).toList(),
        'reservations': reservations.map((e) => e.toJson()).toList(),
        'notes': notes,
        'mode': mode,
        'customerCount': customerCount,
      };

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      name: json['name'] ?? 'Unknown Device',
      elapsedTime: Duration(seconds: json['time'] ?? json['elapsedTime'] ?? json['elapsedSeconds'] ?? 0),
      isRunning: json['isRunning'] ?? json['is_running'] ?? false,
      orders: (json['orders'] as List?)
          ?.map((e) => OrderItem.fromJson(e))
          .toList() ?? [],
      reservations: (json['reservations'] as List? ?? [])
          .map((e) => ReservationItem.fromJson(e))
          .toList(),
      notes: json['notes'] ?? json['note'] ?? '', // Support both plural and singular from server
      mode: json['mode'] ?? 'single',
      customerCount: json['customerCount'] ?? json['customer_count'] ?? 1,
    );
  }
}

class AppState extends ChangeNotifier {


  Map<String, DeviceData> _devices = {};
  Map<String, Timer?> _timers = {};
  
  // Helper to sync device status to server
  void _syncDeviceToApi(String deviceId) {
    print('🔄 (Sync) Triggering sync for $deviceId');
    final device = getDeviceData(deviceId);
    
    // HTTP Sync
    ApiSyncManager().updateDeviceStatus(
      deviceId,
      isRunning: device.isRunning,
      time: device.elapsedTime.inSeconds,
      mode: device.mode,
      customerCount: device.customerCount,
      notes: device.notes,
    );
    
    // WebSocket Sync (Broadcast to other clients)
    WebSocketManager().sendMessage({
      'type': 'device_update',
      'deviceId': deviceId,
      'data': {
        'isRunning': device.isRunning,
        'time': device.elapsedTime.inSeconds,
        'mode': device.mode,
        'customerCount': device.customerCount,
        'notes': device.notes,
      },
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Helper to sync orders to server (HTTP ONLY)
  void _syncOrdersToApi(String deviceId) {
    print('🔄 (Sync) Triggering orders HTTP sync for $deviceId');
    final device = getDeviceData(deviceId);
    final ordersJson = device.orders.map((e) => e.toJson()).toList();
    
    // HTTP Sync ONLY - WebSocket is now handled per-action for efficiency and to avoid duplicates
    ApiSyncManager().syncOrdersToApi(deviceId, ordersJson);
  }
  
  // قائمة الأجهزة المحذوفة لتجنب إعادة إنشائها
  Set<String> _deletedDevices = {};
  // قائمة الحجوزات المستقلة
  List<ReservationItem> _allReservations = [];
  
  // للتحكم في عمليات الحفظ المتزامنة
  bool _isSaving = false;
  
  // Track devices that should force pop their details page (e.g. after remote transfer/reset)
  Set<String> _mustPopDevices = {};
  
  // Track devices being transferred to prevent deletion
  Set<String> _transferringDevices = {};
  
  bool shouldPop(String deviceName) {
    if (_mustPopDevices.contains(deviceName)) {
      _mustPopDevices.remove(deviceName);
      return true;
    }
    return false;
  }

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
  
  // حالة الاتصال
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  void setOnlineStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      notifyListeners();
    }
  }

  AppState() {
    print('🚀 بدء تحميل البيانات من النظام المحسن...');
    _loadFromPrefs();
    initializeAutoSave(); // 🚀 تفعيل نظام الحفظ التلقائي فور بناء الكلاس
    WebSocketManager().init(this); // Initialize WebSocket
    
    
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
  Map<String, DeviceData> get devices {
    print('🔍 UI accessing devices - Count: ${_devices.length}, Keys: ${_devices.keys.join(", ")}');
    return Map.from(_devices);
  }
  
  // Getter للأجهزة المحذوفة  
  Set<String> get deletedDevices {
    print('🗑️ Deleted devices set: ${_deletedDevices.join(", ")}');
    return Set.from(_deletedDevices);
  }
  
  // 🚀 تهيئة نظام الحفظ التلقائي
  void initializeAutoSave() {
    _startAutoSave();
    print('🔄 تم تفعيل نظام الحفظ التلقائي - كل 30 ثانية');
  }
  
  // 🔄 Auto-save disabled in server-only mode
  void _startAutoSave() {
    print('Server-only mode: Auto-save disabled');
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
    // Sync to server
    ApiSyncManager().updatePricesOnServer({'orderPrices': {itemName: price}});
  }
  
  void updateOrderPrices(Map<String, double> prices) {
    _orderPrices.addAll(prices);
    _saveToPrefs();
    notifyListeners();
    // Sync to server
    ApiSyncManager().updatePricesOnServer({'orderPrices': prices});
  }
  
  void removeOrderItem(String itemName) {
    _orderPrices.remove(itemName);
    _saveToPrefs();
    notifyListeners();
    // Sync removal (sending price 0 or special flag might be needed, or full sync)
    // Server spec didn't specify removal, assuming full sync handles it or price 0
    ApiSyncManager().updatePricesOnServer({'orderPrices': {itemName: 0.0}}); 
  }
  
  // دوال إدارة الديون
  List<Map<String, dynamic>> get debts => List.from(_debts);
  
  double getTotalDebts() {
    return _debts.fold(0.0, (sum, debt) => sum + (debt['amount'] ?? 0.0));
  }
  
  void addDebt(String name, double amount, {String notes = ''}) {
    final debt = {
      'name': name,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'notes': notes,
    };
    _debts.add(debt);
    _saveToPrefs();
    notifyListeners();
    
    // Sync to server using expected field names
    ApiSyncManager().addDebtToServer({
      'customer_name': name,
      'amount': amount,
      'notes': notes,
    });
  }
  
  void updateDebt(int index, String name, double amount, {String notes = 'Updated'}) {
    if (index >= 0 && index < _debts.length) {
      final oldDebt = _debts[index];
      final id = oldDebt['id'] ?? oldDebt['name'] ?? name;
      
      _debts[index] = {
        'id': id,
        'name': name,
        'amount': amount,
        'notes': notes,
        'date': oldDebt['date'],
      };
      
      _saveToPrefs();
      notifyListeners();
      
      // Sync to server
      ApiSyncManager().updateDebtOnServer(id.toString(), {
        'amount': amount,
        'notes': notes,
      });
    }
  }
  
  void removeDebt(int index) {
    if (index >= 0 && index < _debts.length) {
      final debt = _debts[index];
      final id = debt['id'] ?? debt['name'];
      
      _debts.removeAt(index);
      _saveToPrefs();
      notifyListeners();
      
      // Settle debt on server by setting amount to 0
      ApiSyncManager().updateDebtOnServer(id.toString(), {
        'amount': 0.0,
        'notes': 'Setted/Removed from App',
      });
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
    
    // Sync to server
    ApiSyncManager().addCategoryToServer(categoryName);
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
    // Sync to server
    ApiSyncManager().addExpenseToServer(expense);
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
    
    // Sync to server
    ApiSyncManager().addProductToServer({
      'name': itemName, 
      'category': categoryName, 
      'price': price,
      'description': 'Added via App'
    });
    
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
    
    // Sync to server
    ApiSyncManager().deleteProductFromServer(itemName);
    
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
    // Sync to server
    ApiSyncManager().deleteCategoryFromServer(categoryName);
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
    // Sync to server
    ApiSyncManager().updatePricesOnServer({'pc_price_default': price});
  }

  // تحديث سعر جهاز PS4 محدد
  void updatePs4Price(String deviceName, String mode, double price) {
    if (_ps4Prices.containsKey(deviceName)) {
      _ps4Prices[deviceName]![mode] = price;
      notifyListeners();
      _saveToPrefs();
      // Sync to server (partial update)
      // We need to send both modes if possible, but here we only have one updated.
      // Ideally we send the full object for this device.
      ApiSyncManager().updatePricesOnServer({
        'ps4_prices': {
           deviceName: _ps4Prices[deviceName]
        }
      });
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
    // Sync to server
    ApiSyncManager().updatePricesOnServer({
      'ps4_prices': {
         deviceName: {'single': singlePrice, 'multi': multiPrice}
      }
    });
  }
  
  // تحديث سعر جهاز PC فردي
  void updatePcDevicePrice(String deviceName, double price) {
    _pcPrices[deviceName] = price;
    notifyListeners();
    _saveToPrefs();
    // Sync to server
    ApiSyncManager().updatePricesOnServer({
      'pc_prices_individual': { deviceName: price }
    });
  }
  
  // تحديث سعر طاولة فردية
  void updateTablePrice(String deviceName, double price) {
    _tablePrices[deviceName] = price;
    notifyListeners();
    _saveToPrefs();
    // Sync to server
    ApiSyncManager().updatePricesOnServer({
      'table_prices': { deviceName: price }
    });
  }
  
  // تحديث سعر طاولة بيليارد فردية
  void updateBilliardPrice(String deviceName, double price) {
    _billiardPrices[deviceName] = price;
    notifyListeners();
    _saveToPrefs();
    // Sync to server
    ApiSyncManager().updatePricesOnServer({
      'billiard_prices': { deviceName: price }
    });
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
    
    // Sync to server
    // User requested same Hive schema, so we send the full object structure
    await ApiSyncManager().addDeviceToServer(
      DeviceData(name: deviceName).toJson() // Send full object
    );
    
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
    
    // WebSocket Sync
    WebSocketManager().sendMessage({
      'type': 'device_deleted',
      'deviceId': deviceName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Sync to server
    await ApiSyncManager().deleteDeviceFromServer(deviceName);


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
    
    // Sync to server: Delete old, Add new (since name is ID)
    await ApiSyncManager().deleteDeviceFromServer(oldName);
    await ApiSyncManager().addDeviceToServer({
      'name': newName,
      'type': 'Unknown', // Need to infer type if possible or pass it
      'ip_address': '127.0.0.1'
    });
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
    _syncDeviceToApi(deviceName);
  }

  void startTimer(String deviceName, {bool sync = true}) {
    if (_timers[deviceName] != null) return;
    final device = getDeviceData(deviceName);
    device.isRunning = true;
    
    print('⏰ بدء المؤقت للجهاز: $deviceName (Sync: $sync)');

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
        final durationStr = device.elapsedTime.toString().split('.').first;
        print('💾 حفظ تلقائي للمؤقت: $deviceName - الوقت: $durationStr');
        _syncDeviceToApi(deviceName); // Auto-sync to API
      }
    });

    notifyListeners();
    
    if (sync) {
      // حفظ فوري عند بدء المؤقت (فقط إذا كان التزامن مطلوباً)
      _saveToPrefs();
      print('✅ تم بدء وحفظ المؤقت: $deviceName');
      _syncDeviceToApi(deviceName);
    }
  }

  void stopTimer(String deviceName) {
    try {
      final device = getDeviceData(deviceName);
      device.isRunning = false;
      _timers[deviceName]?.cancel();
      _timers.remove(deviceName);
      
      // Calculate display time safely
      final durationStr = device.elapsedTime.toString().split('.').first;
      print('⏸️ إيقاف المؤقت للجهاز: $deviceName - إجمالي الوقت: $durationStr');
      
      // حفظ فوري + طارئ عند إيقاف المؤقت (مهم جداً!)
      notifyListeners();
      _saveToPrefs();
      _emergencySave();
      
      print('✅ تم حفظ إيقاف المؤقت: $deviceName');
      _syncDeviceToApi(deviceName);
    } catch (e) {
      print('❌ خطأ في إيقاف المؤقت: $e');
    }
  }

  void resetTimerOnly(String deviceName) {
    final device = getDeviceData(deviceName);
    device.elapsedTime = Duration.zero;
    device.isRunning = false;
    _timers[deviceName]?.cancel();
    _timers.remove(deviceName);
    notifyListeners();
    _saveToPrefs();
    _syncDeviceToApi(deviceName);
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
      
      // Sync update via WebSocket
      WebSocketManager().sendMessage({
        'type': 'order_updated',
        'deviceId': deviceName,
        'orderIndex': index,
        'data': existing.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      orders.add(newOrder);
      
      // Sync add via WebSocket
      WebSocketManager().sendMessage({
        'type': 'order_placed',
        'deviceId': deviceName,
        'orders': [newOrder.toJson()],
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    notifyListeners();
    _saveToPrefs();
    _syncOrdersToApi(deviceName);
  }

  /// إضافة عدة طلبات دفعة واحدة
  void addOrders(String deviceName, List<OrderItem> newOrders) {
    final device = getDeviceData(deviceName);
    List<OrderItem> actuallyAdded = [];
    
    for (var newOrder in newOrders) {
      int index = device.orders.indexWhere((o) => 
        o.name == newOrder.name && o.firstOrderTime.isAtSameMomentAs(newOrder.firstOrderTime)
      );
      if (index >= 0) {
        final existing = device.orders[index];
        existing.quantity += newOrder.quantity;
        existing.lastOrderTime = DateTime.now();
        
        WebSocketManager().sendMessage({
          'type': 'order_updated',
          'deviceId': deviceName,
          'orderIndex': index,
          'data': existing.toJson(),
        });
      } else {
        device.orders.add(newOrder);
        actuallyAdded.add(newOrder);
      }
    }
    
    if (actuallyAdded.isNotEmpty) {
      WebSocketManager().sendMessage({
        'type': 'order_placed',
        'deviceId': deviceName,
        'orders': actuallyAdded.map((o) => o.toJson()).toList(),
      });
    }
    
    notifyListeners();
    _saveToPrefs();
    _syncOrdersToApi(deviceName);
  }

  /// Broadcasts new orders without saving them locally (used when API already did the work)
  void broadcastNewOrders(String deviceName, List<OrderItem> orders) {
    if (orders.isEmpty) return;
    
    print('📡 Broadcasting ${orders.length} new orders for $deviceName');
    WebSocketManager().sendMessage({
      'type': 'order_placed',
      'deviceId': deviceName,
      'orders': orders.map((o) => o.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Add orders locally and broadcast, but skip API sync (used when API already saved them)
  void addOrdersWithoutApiSync(String deviceName, List<OrderItem> newOrders) {
    final device = getDeviceData(deviceName);
    List<OrderItem> actuallyAdded = [];
    
    for (var newOrder in newOrders) {
      int index = device.orders.indexWhere((o) => 
        o.name == newOrder.name && o.firstOrderTime.toIso8601String().split('.')[0] == newOrder.firstOrderTime.toIso8601String().split('.')[0]
      );
      if (index >= 0) {
        final existing = device.orders[index];
        existing.quantity += newOrder.quantity;
        existing.lastOrderTime = DateTime.now();
        
        // NO WebSocket message here! 
        // Server handles broadcasting for HTTP actions to avoid duplication.
      } else {
        device.orders.add(newOrder);
        actuallyAdded.add(newOrder);
      }
    }
    
    if (actuallyAdded.isNotEmpty) {
      // STOP SENDING VIA SOCKET HERE!
      // Server now handles broadcasting automatically upon HTTP request.
      // Sending this causes double-processing/duplication on the server.
      /*
      WebSocketManager().sendMessage({
        'type': 'order_placed',
        'deviceId': deviceName,
        'orders': actuallyAdded.map((o) => o.toJson()).toList(),
      });
      */
    }
    
    notifyListeners();
    _saveToPrefs();
    // Note: NO _syncOrdersToApi call here since API already has the data
  }

  void removeOrder(String deviceName, OrderItem order) {
    final device = getDeviceData(deviceName);
    device.orders.remove(order);
    notifyListeners();
    _saveToPrefs();
    _syncOrdersToApi(deviceName);
  }

  void removeOrderByIndex(String deviceName, int index) {
    final device = getDeviceData(deviceName);
    if (index >= 0 && index < device.orders.length) {
      device.orders.removeAt(index);
      
      // Sync delete via WebSocket
      WebSocketManager().sendMessage({
        'type': 'order_deleted',
        'deviceId': deviceName,
        'orderIndex': index,
      });
      
      notifyListeners();
      _saveToPrefs();
      _syncOrdersToApi(deviceName);
    }
  }

  void updateOrder(String deviceName, int index, OrderItem updatedOrder) {
    final device = getDeviceData(deviceName);
    if (index >= 0 && index < device.orders.length) {
      device.orders[index] = updatedOrder;
      
      // Sync update via WebSocket
      WebSocketManager().sendMessage({
        'type': 'order_updated',
        'deviceId': deviceName,
        'orderIndex': index,
        'data': updatedOrder.toJson(),
      });
      
      notifyListeners();
      _saveToPrefs();
      _syncOrdersToApi(deviceName);
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
    try {
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
      
      // Clear price overrides
      _pcPrices.remove(deviceName);
      _tablePrices.remove(deviceName);
      _billiardPrices.remove(deviceName);
      _ps4Prices.remove(deviceName);

      _mustPopDevices.add(deviceName); // Signal UI to pop if on this page
      
      print('Device $deviceName reset successfully');
      
      notifyListeners();
      
      // حفظ البيانات
      _saveToPrefs().then((_) {
        print('resetDevice: Save completed for $deviceName');
        _syncDeviceToApi(deviceName);
        _syncOrdersToApi(deviceName);
        
        // WebSocket Sync
        WebSocketManager().sendMessage({
          'type': 'device_reset',
          'deviceId': deviceName,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }).catchError((error) {
        print('resetDevice: Save failed for $deviceName: $error');
      });
      
      print('=== resetDevice finished for: $deviceName ===');
    } catch (e) {
      print('❌ Error in resetDevice: $e');
    }
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
    if (device.notes == note) return; // Skip if no change
    
    device.notes = note;
    notifyListeners();
    _saveToPrefs();
    _syncDeviceToApi(deviceName);
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
    _syncDeviceToApi(deviceName);
  }

  void transferDeviceData(String fromDevice, String toDevice) {
    if (!_devices.containsKey(fromDevice)) return;
    final fromData = _devices[fromDevice]!;
    final toData = _devices[toDevice] ?? DeviceData(name: toDevice);

    // Transfer all data to destination
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

    // Transfer reservations
    toData.reservations.addAll(fromData.reservations);

    toData.notes = fromData.notes;
    toData.mode = fromData.mode;
    toData.customerCount = fromData.customerCount;

    // Transfer price settings if they exist
    if (_pcPrices.containsKey(fromDevice)) _pcPrices[toDevice] = _pcPrices.remove(fromDevice)!;
    if (_tablePrices.containsKey(fromDevice)) _tablePrices[toDevice] = _tablePrices.remove(fromDevice)!;
    if (_billiardPrices.containsKey(fromDevice)) _billiardPrices[toDevice] = _billiardPrices.remove(fromDevice)!;
    if (_ps4Prices.containsKey(fromDevice)) _ps4Prices[toDevice] = _ps4Prices.remove(fromDevice)!;

    // Reset source device to clean state (don't delete it)
    fromData.isRunning = false;
    fromData.elapsedTime = Duration.zero;
    fromData.orders.clear();
    fromData.reservations.clear();
    fromData.notes = '';
    fromData.mode = 'single';
    fromData.customerCount = 1;
    
    _timers[fromDevice]?.cancel();
    _timers.remove(fromDevice);

    _devices[toDevice] = toData;

    if (toData.isRunning) {
      startTimer(toDevice);
    }

    _mustPopDevices.add(fromDevice); // Signal UI to pop if on this page
    notifyListeners();
    _saveToPrefs();
    
    // Mark device as transferring to prevent deletion from socket
    _transferringDevices.add(fromDevice);
    
    // Sync transfer to API
    _syncTransferToApi(fromDevice, toDevice);
    
    // Remove from transferring set after a delay
    Future.delayed(Duration(seconds: 2), () {
      _transferringDevices.remove(fromDevice);
    });
  }
  
  Future<void> _syncTransferToApi(String fromDevice, String toDevice) async {
    try {
      final apiSync = ApiSyncManager();
      await apiSync.transferDeviceViaApi(fromDevice, toDevice);
      print('✅ Device transfer synced to API: $fromDevice -> $toDevice');
      
      // Force immediate HTTP sync for BOTH devices to ensure server state is 100% correct
      // Sync destination (now has the data)
      _syncDeviceToApi(toDevice);
      _syncOrdersToApi(toDevice);
      
      // Sync source (now empty)
      _syncDeviceToApi(fromDevice);
      _syncOrdersToApi(fromDevice);

      // WebSocket Sync
      WebSocketManager().sendMessage({
        'type': 'device_transfer', // Client -> Server uses 'device_transfer'
        'fromDeviceId': fromDevice,
        'toDeviceId': toDevice,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Failed to sync transfer to API: $e');
    }
  }

  // Hive removed - server-only mode

  Future<void> _saveToPrefs() async {
    // No local persistence - server-only mode
    // Data is managed in memory only
    print('Server-only mode: No local persistence');
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
    // Server-only mode: No local loading from Hive
    // Data is loaded fresh from server on each app start
    print('Server-only mode: Skipping local data loading from Hive');
    _ensureDefaultDevices();
    notifyListeners();
  }

  // دالة تحميل احتياطية من SharedPreferences
  // _loadFromSharedPrefs removed - server-only mode
  
  void _ensureDefaultDevices() {
    // Server-only mode: Don't create default devices
    // Trust server completely - if server is empty, app should be empty
    print('Server-only mode: Skipping default device creation');
  }

  double calculatePrice(String deviceName, Duration elapsed, String mode) {
    double ratePerHour = 0;
    final lowerName = deviceName.toLowerCase();

    if (lowerName.startsWith('pc')) {
      // استخدام السعر الفردي للجهاز PC
      ratePerHour = getPcPrice(deviceName);
    } else if (lowerName.startsWith('arabia')) {
      // استخدام البنية الجديدة لأسعار PS4
      ratePerHour = getPs4Price(deviceName, mode);
      // print('calculatePrice for $deviceName: mode=$mode, rate=$ratePerHour');
    } else if (lowerName.startsWith('table')) {
      // استخدام السعر الفردي للطاولة
      ratePerHour = getTablePrice(deviceName);
    } else if (lowerName.startsWith('billiard')) {
      // استخدام السعر الفردي للبيليارد
      ratePerHour = getBilliardPrice(deviceName);
    } else {
      ratePerHour = 0;
      print('Warning: Unknown device type for pricing: $deviceName');
    }

    double price = (elapsed.inSeconds / 3600.0) * ratePerHour;
    return price;
  }



  // safeCloseBox removed - server-only mode

  @override
  void dispose() {
    // 🔒 حفظ طارئ نهائي قبل الإغلاق
    print('🔄 بدء الحفظ الطارئ النهائي...');
    _emergencySave();
    
    // إيقاف جميع المؤقتات
    _timers.values.forEach((timer) => timer?.cancel());
    _timers.clear();
    
    super.dispose();
  }

  // 🚨 Emergency save - no-op in server-only mode
  void _emergencySave() {
    print('Server-only mode: Emergency save not needed');
  }

  // ============= API Sync Methods =============
  // These methods allow AppState to be updated from API responses

  /// Update device from API response
  void updateDeviceFromApi(String deviceId, Map<String, dynamic> data) {
    try {
      final name = data['name'] ?? deviceId;
      final localKey = name;
      
      // Resurrect device if it was locally deleted
      if (_deletedDevices.contains(localKey)) {
        print('♻️ Resurrecting locally deleted device: $localKey');
        _deletedDevices.remove(localKey);
      }

      if (_devices.containsKey(localKey)) {
        // 🔥 CRITICAL: Update EXISTING object to maintain timer references!
        // DO NOT do: _devices[localKey] = DeviceData.fromJson(data);
        final existing = _devices[localKey]!;
        final newData = DeviceData.fromJson(data);
        
        bool changed = false;
        if (existing.isRunning != newData.isRunning) {
          existing.isRunning = newData.isRunning;
          changed = true;
        }
        
        // Jitter Buffer: Don't overwrite time if difference is small (< 5s)
        // AND: Protect local time from being reset to 0 by a "lazy" server update
        final timeDiff = (existing.elapsedTime.inSeconds - newData.elapsedTime.inSeconds).abs();
        bool shouldUpdateTime = false;
        
        if (newData.elapsedTime.inSeconds > 0) {
          // Force update if server time is ahead or significantly different
          // Reduce Jitter Buffer to 2s to catch up faster
          if (timeDiff > 2 || !existing.isRunning) {
            shouldUpdateTime = true;
          }
        }
 else if (existing.elapsedTime.inSeconds > 0 && newData.elapsedTime.inSeconds == 0) {
           // ⚠️ Server sent 0 but we have local time. 
           // If it's a regular update (not a reset), IGNORE the 0 to prevent "Time Restart" bug.
           print('⚠️ Ignoring 0-time update from API for ${existing.name} (Local time: ${existing.elapsedTime.inSeconds}s)');
        }
        
        if (shouldUpdateTime) {
          existing.elapsedTime = newData.elapsedTime;
          changed = true;
        }
        
        existing.mode = newData.mode;
        existing.customerCount = newData.customerCount;
        existing.notes = newData.notes;
        
        // Update orders as well
        if (data.containsKey('orders')) {
          existing.orders = newData.orders;
          changed = true;
        }

        // 🔥 Start timer if server says running but not running locally
        if (existing.isRunning && _timers[localKey] == null) {
           print('⏰ Auto-Starting timer for $localKey (Sync from server)');
           startTimer(localKey, sync: false); // Don't sync back immediately to avoid loop
        } else if (!existing.isRunning && _timers[localKey] != null) {
           print('⏸️ Auto-Stopping timer for $localKey (Sync from server)');
           // Use low-level stop to avoid trigger sync
           _timers[localKey]?.cancel();
           _timers.remove(localKey);
           notifyListeners();
        }

        print('✅ Updated device $localKey from API (Maintaining memory reference)');
        if (changed) notifyListeners();
      } else {
        // ADD NEW
        final newDevice = DeviceData.fromJson(data);
        _devices[localKey] = newDevice;
        
        // Start timer if running on server
        if (newDevice.isRunning) {
           print('⏰ Auto-Starting timer for NEW device $localKey');
           startTimer(localKey, sync: false);
        }
        
        notifyListeners();
        print('✅ ADDED NEW device $localKey from API');
      }
    } catch (e) {
      print('❌ Error updating device from API: $e');
    }
  }

  /// Update device orders from API response
  /// Update device orders from API response (using Device Name as ID locally)
  void updateDeviceOrdersFromApi(String deviceName, List<dynamic> ordersData) {
    try {
      // Use deviceName as key (it IS the key in our local schema)
      if (_devices.containsKey(deviceName)) {
        final orders = ordersData
            .whereType<Map<String, dynamic>>()
            .map((e) => OrderItem.fromJson(e))
            .toList();
        _devices[deviceName]!.orders = orders;

        // Note: No broadcast here either to avoid additive duplication on other clients
        
        notifyListeners();
        print('✅ Updated orders for $deviceName from API');
      }
    } catch (e) {
      print('❌ Error updating orders from API: $e');
    }
  }

  /// Update reservations from API response
  void updateReservationsFromApi(List<dynamic> reservationsData) {
    try {
      _allReservations = reservationsData
          .whereType<Map<String, dynamic>>()
          .map((e) => ReservationItem.fromJson(e))
          .toList();
      notifyListeners();
      print('✅ Updated reservations from API');
    } catch (e) {
      print('❌ Error updating reservations from API: $e');
    }
  }

  /// Update prices from API response
  /// Update prices from API response
  void updatePricesFromApi(Map<String, dynamic> pricesData) {
    try {
      // Handle both camelCase (PUT response) and snake_case (GET response)
      _pcPrice = (pricesData['pcPrice'] ?? pricesData['pc_price_default'] ?? 1500).toDouble();
      
      final ps4Data = pricesData['ps4Prices'] ?? pricesData['ps4_prices'];
      if (ps4Data != null) {
        _ps4Prices.clear();
        final Map<String, dynamic> savedPs4Prices = Map<String, dynamic>.from(ps4Data);
        savedPs4Prices.forEach((deviceName, prices) {
          _ps4Prices[deviceName] = Map<String, double>.from(prices);
        });
      }
      
      final pcData = pricesData['pcPrices'] ?? pricesData['pc_prices_individual'] ?? pricesData['pc_prices'];
      if (pcData != null) {
        _pcPrices = Map<String, double>.from(pcData);
      }
      
      final tableData = pricesData['tablePrices'] ?? pricesData['table_prices'];
      if (tableData != null) {
        _tablePrices = Map<String, double>.from(tableData);
      }
      
      final billiardData = pricesData['billiardPrices'] ?? pricesData['billiard_prices'] ?? pricesData['billiard_price'];
      if (billiardData != null) {
        if (billiardData is Map) {
             _billiardPrices = Map<String, double>.from(billiardData);
        } else if (billiardData is num) {
             // Handle simple global price if needed, but we store per device
             // Only if map structure matches expectations.
        }
      }
      
      // Fix: Sync product prices (orderPrices)
      final orderData = pricesData['orderPrices'] ?? pricesData['order_prices'];
      if (orderData != null) {
        _orderPrices = Map<String, double>.from(orderData);
      }
      
      notifyListeners();
      print('✅ Updated prices from API (Includes ${_orderPrices.length} product prices)');
    } catch (e) {
      print('❌ Error updating prices from API: $e');
    }
  }

  /// Update categories and product prices from API response hierarchy
  void updateCategoriesFromApi(List<dynamic> categoriesData) {
    try {
      print('🔄 updateCategoriesFromApi called with ${categoriesData.length} categories');
      _customCategories.clear();
      
      for (var catData in categoriesData.whereType<Map<String, dynamic>>()) {
        final categoryName = catData['name'] as String?;
        if (categoryName != null) {
          final itemsList = catData['items'] as List?;
          List<String> itemNames = [];
          
          if (itemsList != null) {
              for (var item in itemsList) {
                  if (item is String) {
                      itemNames.add(item);
                  } else if (item is Map<String, dynamic>) {
                      // Extract name and price from nested product object
                      final name = item['name'] as String?;
                      final price = (item['price'] ?? 0.0).toDouble();
                      if (name != null) {
                          itemNames.add(name);
                          _orderPrices[name] = price;
                      }
                  }
              }
          }
          
          _customCategories[categoryName] = itemNames;
          print('  ✅ Category "$categoryName" loaded with ${itemNames.length} items');
        }
      }
      notifyListeners();
      print('✅ Updated categories & menu items from API - Total: ${_customCategories.length} categories');
    } catch (e) {
      print('❌ Error updating categories from API: $e');
    }
  }

  /// Update debts from API response
  void updateDebtsFromApi(Map<String, dynamic> debtsData) {
    try {
      print('🔄 updateDebtsFromApi: Received data with keys: ${debtsData.keys.toList()}');
      _debts = [];
      
      // Attempt 1: Look for 'data' key (Map or List)
      if (debtsData.containsKey('data')) {
          final data = debtsData['data'];
          if (data is Map) {
              data.forEach((name, amount) {
                  _debts.add({
                      'name': name,
                      'amount': (amount as num).toDouble(),
                      'id': name,
                      'date': DateTime.now().toIso8601String(),
                  });
              });
          } else if (data is List) {
              for (var d in data) {
                  if (d is Map<String, dynamic>) _debts.add(Map<String, dynamic>.from(d));
              }
          }
      } 
      // Attempt 2: Look for 'debts' key
      else if (debtsData.containsKey('debts') && debtsData['debts'] is List) {
        for (var d in debtsData['debts']) {
            if (d is Map<String, dynamic>) _debts.add(Map<String, dynamic>.from(d));
        }
      }
      // Attempt 3: Direct Name -> Amount mapping at the root
      else {
          debtsData.forEach((name, amount) {
              if (amount is num && name != 'success' && name != 'status' && name != 'count' && name != 'totalDebt' && name != 'timestamp') {
                  _debts.add({
                      'name': name,
                      'amount': amount.toDouble(),
                      'id': name,
                      'date': DateTime.now().toIso8601String(),
                  });
              }
          });
      }
      
      notifyListeners();
      print('✅ Updated debts - Count: ${_debts.length}');
    } catch (e) {
      print('❌ Error updating debts from API: $e');
    }
  }

  /// Update expenses from API response
  void updateExpensesFromApi(List<dynamic> expensesData) {
    try {
      _todayExpenses = [];
      for (var expenseData in expensesData.whereType<Map<String, dynamic>>()) {
        _todayExpenses.add(expenseData);
      }
      notifyListeners();
      print('✅ Updated expenses from API');
    } catch (e) {
      print('❌ Error updating expenses from API: $e');
    }
  }

  // ============================================
  // 🔌 WebSocket Handlers (Direct State Update)
  // ============================================

  void updateDeviceStatusFromSocket(String deviceId, {
    required bool isRunning,
    required int time,
    required String mode,
    required int customerCount,
    required String notes,
  }) {
    final device = _devices[deviceId];
    
    if (device != null) {
      // Check for actual changes to avoid unnecessary rebuilds and jitter
      bool changed = false;
      
      if (device.isRunning != isRunning) {
        device.isRunning = isRunning;
        changed = true;
      }
      
      // 🔥 JITTER BUFFER & ZERO PROTECTION: 
      // 1. Only update if server's time is significantly different (diff > 5s).
      // 2. PROTECT local time: If server sends 0 but we have local time, ignore it.
      //    True resets come through 'device_reset' socket type, not 'device_update'.
      final timeDiff = (device.elapsedTime.inSeconds - time).abs();
      bool shouldUpdateTime = false;
      
      if (time > 0) {
        if (timeDiff > 5 || !isRunning) {
          shouldUpdateTime = true;
        }
      } else if (device.elapsedTime.inSeconds > 0 && time == 0) {
        print('⚠️ Ignoring 0-time socket update for ${device.name} (Local: ${device.elapsedTime.inSeconds}s)');
      }
      
      if (shouldUpdateTime) {
        device.elapsedTime = Duration(seconds: time);
        changed = true;
      }
      
      if (device.mode != mode) {
        device.mode = mode;
        changed = true;
      }
      
      if (device.customerCount != customerCount) {
        device.customerCount = customerCount;
        changed = true;
      }
      
      if (device.notes != notes) {
        device.notes = notes;
        changed = true;
      }
      
      if (changed) {
        // Manage local timer for visual smoothness
        if (isRunning) {
            if (!(_timers[deviceId]?.isActive ?? false)) {
                 _startLocalTimerOnly(deviceId);
            }
        } else {
            _timers[deviceId]?.cancel();
            _timers.remove(deviceId);
        }
        
        notifyListeners();
        print('🔌 Device $deviceId updated from socket (Fields synced)');
      }
    } else {
      // Handle new device arriving via socket
      final newDevice = DeviceData(
        name: deviceId,
        isRunning: isRunning,
        elapsedTime: Duration(seconds: time),
        mode: mode,
        customerCount: customerCount,
        notes: notes,
      );
      _devices[deviceId] = newDevice;
      
      if (isRunning) {
        _startLocalTimerOnly(deviceId);
      }
      
      notifyListeners();
      print('🔌 Created NEW device $deviceId from socket');
    }
  }
  
  void _startLocalTimerOnly(String deviceName) {
      if (_timers[deviceName] != null) return;
      final device = getDeviceData(deviceName);
      
      _timers[deviceName] = Timer.periodic(const Duration(seconds: 1), (_) {
          device.elapsedTime += const Duration(seconds: 1);
          notifyListeners();
      });
  }

  void addOrdersFromSocket(String deviceId, List<OrderItem> newOrders) {
    print('🔌 Adding orders from socket to $deviceId: ${newOrders.length} items');
    if (!_devices.containsKey(deviceId)) return;
    final device = _devices[deviceId]!;
    
    for (var newOrder in newOrders) {
        // 1. Check EXACT match by ID 
        final idExists = device.orders.any((o) => o.id == newOrder.id);
        
        if (idExists) {
             print('⏩ Skipped duplicate/echo order from socket (ID Match)');
             continue; 
        }

        // 2. Check Logic for Merging (Fuzzy Name Match)
        // Normalize names: Trim spaces and lowercase to ensure "Tea " matches "Tea"
        final existingIndex = device.orders.indexWhere((o) => 
            o.name.trim().toLowerCase() == newOrder.name.trim().toLowerCase()
        );
        
        if (existingIndex >= 0) {
            final existing = device.orders[existingIndex];
            
            // Robust Echo Detection:
            // If the local item was updated very recently (< 10 seconds), 
            // and the incoming item has no ID (or ID mismatch), assumes it's an echo of our own action.
            final secondsSinceLastUpdate = DateTime.now().difference(existing.lastOrderTime).inSeconds.abs();
            
            print('🔍 Checking Duplicate/Echo for ${newOrder.name}:');
            print('   - ID Match: ${existing.id == newOrder.id}');
            print('   - Updated locally: ${secondsSinceLastUpdate}s ago');

            if (secondsSinceLastUpdate < 10) {
                 print('⏩ Skipped echo (Recently updated locally): ${newOrder.name}');
            } else {
                 print('➕ Merging new order quantity from socket: ${newOrder.name} (ID: ${newOrder.id})');
                 existing.quantity += newOrder.quantity;
                 existing.lastOrderTime = DateTime.now();
            }
        } else {
            // New item -> Add it
            device.orders.add(newOrder);
            print('💡 Added new order item from socket: ${newOrder.name} (ID: ${newOrder.id})');
        }
    }
    notifyListeners();
  }

  void updateOrdersFromSocket(String deviceId, List<OrderItem> orders) {
    print('🔌 updateOrdersFromSocket start: $deviceId with ${orders.length} items');
    // Ensure device exists
    if (!_devices.containsKey(deviceId)) {
        _devices[deviceId] = DeviceData(name: deviceId);
        print('🔌 Created device $deviceId for orders');
    }
    
    final device = _devices[deviceId]!;
    // Use clear/addAll to preserve potential listeners to the list itself
    device.orders.clear();
    device.orders.addAll(orders);
    
    notifyListeners();
    print('✅ updateOrdersFromSocket complete: $deviceId now has ${device.orders.length} items');
  }
  
  void updateOrderFromSocket(String deviceId, int index, OrderItem updatedOrder) {
      if (!_devices.containsKey(deviceId)) return;
      final device = _devices[deviceId]!;
      
      if (index >= 0 && index < device.orders.length) {
          device.orders[index] = updatedOrder;
          notifyListeners();
          print('🔌 Order #$index updated from socket on $deviceId');
      }
  }
  
  void removeOrderFromSocket(String deviceId, int index) {
      if (!_devices.containsKey(deviceId)) return;
      final device = _devices[deviceId]!;
      
      if (index >= 0 && index < device.orders.length) {
          device.orders.removeAt(index);
          notifyListeners();
           print('🔌 Order #$index removed from socket on $deviceId');
      }
  }

  void removeDeviceFromSocket(String deviceId) {
    // Don't delete if device is being transferred
    if (_transferringDevices.contains(deviceId)) {
      print('⏩ Ignoring device removal for $deviceId - transfer in progress');
      return;
    }
    
    if (_devices.containsKey(deviceId)) {
      _timers[deviceId]?.cancel();
      _timers.remove(deviceId);
      _devices.remove(deviceId);
      _deletedDevices.add(deviceId);
      notifyListeners();
      print('🔌 Device removed from socket: $deviceId');
    }
  }

  void resetDeviceFromSocket(String deviceId) {
    if (!_devices.containsKey(deviceId)) {
       // If it doesn't exist, we don't need to reset it, 
       // but we add it to deleted to prevent ghost updates
       _deletedDevices.add(deviceId);
       return;
    }
    _timers[deviceId]?.cancel();
    _timers.remove(deviceId);
      final device = _devices[deviceId]!;
      device.orders.clear();
      device.reservations.clear();
      device.isRunning = false;
      device.elapsedTime = Duration.zero;
      device.notes = '';
      device.mode = 'single';
      device.customerCount = 1;
      
      // Clear price overrides
      _pcPrices.remove(deviceId);
      _tablePrices.remove(deviceId);
      _billiardPrices.remove(deviceId);
      _ps4Prices.remove(deviceId);

      _mustPopDevices.add(deviceId); // Signal UI to pop if on this page
      notifyListeners();
      print('🔌 Device reset from socket: $deviceId');
  }

  void transferDeviceDataFromSocket(String fromDevice, String toDevice) {
    if (!_devices.containsKey(fromDevice)) return;
    final fromData = _devices[fromDevice]!;
    final toData = _devices[toDevice] ?? DeviceData(name: toDevice);

    // Transfer all data to destination
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

    // Transfer reservations
    toData.reservations.addAll(fromData.reservations);

    toData.notes = fromData.notes;
    toData.mode = fromData.mode;
    toData.customerCount = fromData.customerCount;

    // Transfer price settings if they exist
    if (_pcPrices.containsKey(fromDevice)) _pcPrices[toDevice] = _pcPrices.remove(fromDevice)!;
    if (_tablePrices.containsKey(fromDevice)) _tablePrices[toDevice] = _tablePrices.remove(fromDevice)!;
    if (_billiardPrices.containsKey(fromDevice)) _billiardPrices[toDevice] = _billiardPrices.remove(fromDevice)!;
    if (_ps4Prices.containsKey(fromDevice)) _ps4Prices[toDevice] = _ps4Prices.remove(fromDevice)!;

    // Reset source device to clean state (don't delete it)
    fromData.isRunning = false;
    fromData.elapsedTime = Duration.zero;
    fromData.orders.clear();
    fromData.reservations.clear();
    fromData.notes = '';
    fromData.mode = 'single';
    fromData.customerCount = 1;
    
    _timers[fromDevice]?.cancel();
    _timers.remove(fromDevice);

    _devices[toDevice] = toData;

    if (toData.isRunning) {
      _startLocalTimerOnly(toDevice); // Use local timer only
    }

    _mustPopDevices.add(fromDevice); // Signal UI to pop if on this page
    notifyListeners();
    print('🔌 Device transfer processed from socket: $fromDevice -> $toDevice');
  }
}
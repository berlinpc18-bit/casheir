import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'websocket_manager.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'app_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  static bool _isInitialized = false;
  
  factory PrinterService() => _instance;
  PrinterService._internal();

  // تأكد من تحميل الإعدادات قبل الاستخدام
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      print('🔄 Initializing PrinterService for first time...');
      await _loadPrinterSettings();
      _isInitialized = true;
      print('✅ PrinterService initialized successfully');
    }
  }
  
  // للتحقق من حالة التحميل
  bool get isInitialized => _isInitialized;
  
  // إعادة تهيئة الخدمة (لإعادة تحميل الإعدادات)
  Future<void> resetAndReload() async {
    print('🔄 Resetting PrinterService and reloading settings...');
    _isInitialized = false;
    await ensureInitialized();
  }

  // إعدادات الطابعات
  String _kitchenPrinterIP = '';  // طابعة المطبخ
  String _baristaPrinterIP = '';  // طابعة الباريستا
  String _cashierPrinterIP = '';  // طابعة الحساب
  String _shishaPrinterIP = '';   // طابعة اراكيل
  String _backupPrinterIP = '';   // طابعة احتياطية
  bool _useNetworkPrinters = false;
  
  // إعدادات تفعيل الطابعات
  bool _printKitchenReceipts = true;
  bool _printBaristaReceipts = true;
  bool _printCashierReceipts = true;
  bool _printShishaReceipts = true;
  bool _printBackupReceipts = false;
  
  // خريطة ربط الأقسام بالطابعات المخصصة
  Map<String, String> _categoryToPrinter = {};

  // جلب الإعدادات الحالية
  String get kitchenPrinterIP => _kitchenPrinterIP;
  String get baristaPrinterIP => _baristaPrinterIP;
  String get cashierPrinterIP => _cashierPrinterIP;
  String get shishaPrinterIP => _shishaPrinterIP;
  String get backupPrinterIP => _backupPrinterIP;
  bool get useNetworkPrinters => _useNetworkPrinters;
  bool get printKitchenReceipts => _printKitchenReceipts;
  bool get printBaristaReceipts => _printBaristaReceipts;
  bool get printCashierReceipts => _printCashierReceipts;
  bool get printShishaReceipts => _printShishaReceipts;
  bool get printBackupReceipts => _printBackupReceipts;
  Map<String, String> get categoryToPrinter => Map.from(_categoryToPrinter);

  // تحديث إعدادات الطابعات
  Future<void> updatePrinterSettings({
    String? kitchenIP,
    String? baristaIP,
    String? cashierIP,
    String? shishaIP,
    String? backupIP,
    bool? useNetwork,
    bool? enableKitchen,
    bool? enableBarista,
    bool? enableCashier,
    bool? enableShisha,
    bool? enableBackup,
    Map<String, String>? categoryMapping,
  }) async {
    await ensureInitialized(); // تأكد من تحميل الإعدادات أولاً
    if (kitchenIP != null) _kitchenPrinterIP = kitchenIP;
    if (baristaIP != null) _baristaPrinterIP = baristaIP;
    if (cashierIP != null) _cashierPrinterIP = cashierIP;
    if (shishaIP != null) _shishaPrinterIP = shishaIP;
    if (backupIP != null) _backupPrinterIP = backupIP;
    if (useNetwork != null) _useNetworkPrinters = useNetwork;
    if (enableKitchen != null) _printKitchenReceipts = enableKitchen;
    if (enableBarista != null) _printBaristaReceipts = enableBarista;
    if (enableCashier != null) _printCashierReceipts = enableCashier;
    if (enableShisha != null) _printShishaReceipts = enableShisha;
    if (enableBackup != null) _printBackupReceipts = enableBackup;
    if (categoryMapping != null) _categoryToPrinter = categoryMapping;
    
    await _savePrinterSettings();
  }

  // ربط قسم بطابعة معينة
  void assignCategoryToPrinter(String category, String printerType) {
    _categoryToPrinter[category] = printerType;
    _savePrinterSettings();
  }

  // إزالة ربط قسم من طابعة
  void removeCategoryAssignment(String category) {
    _categoryToPrinter.remove(category);
    _savePrinterSettings();
  }

  // الحصول على الطابعة المخصصة لقسم معين
  String? getPrinterForCategory(String category) {
    return _categoryToPrinter[category];
  }

  // تحديث اسم القسم في خريطة الربط
  void updateCategoryName(String oldName, String newName) {
    if (_categoryToPrinter.containsKey(oldName)) {
      String? printerType = _categoryToPrinter[oldName];
      _categoryToPrinter.remove(oldName);
      if (printerType != null) {
        _categoryToPrinter[newName] = printerType;
      }
      _savePrinterSettings();
      print('🔄 تم تحديث اسم القسم في الطابعات: $oldName -> $newName (طابعة: $printerType)');
    }
  }

  // تحديث ربط الأقسام بناءً على إعدادات الطابعات
  void updateCategoryMappingFromPrinterSettings(
    List<String> kitchenCategories,
    List<String> baristaCategories,
    List<String> cashierCategories,
    List<String> shishaCategories,
    List<String> backupCategories,
  ) {
    // مسح الربط القديم
    _categoryToPrinter.clear();
    
    // ربط أقسام المطبخ
    for (String category in kitchenCategories) {
      _categoryToPrinter[category] = 'kitchen';
    }
    
    // ربط أقسام الباريستا
    for (String category in baristaCategories) {
      _categoryToPrinter[category] = 'barista';
    }
    
    // ربط أقسام الكاشير
    for (String category in cashierCategories) {
      _categoryToPrinter[category] = 'cashier';
    }
    
    // ربط أقسام اراكيل
    for (String category in shishaCategories) {
      _categoryToPrinter[category] = 'shisha';
    }
    
    // ربط أقسام الطابعة الاحتياطية
    for (String category in backupCategories) {
      _categoryToPrinter[category] = 'backup';
    }
    
    _savePrinterSettings();
  }

  // حفظ الإعدادات
  Future<void> _savePrinterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ عناوين IP الطابعات
      await prefs.setString('kitchen_printer_ip', _kitchenPrinterIP);
      await prefs.setString('cashier_printer_ip', _cashierPrinterIP);
      await prefs.setString('barista_printer_ip', _baristaPrinterIP);
      await prefs.setString('shisha_printer_ip', _shishaPrinterIP);
      await prefs.setString('backup_printer_ip', _backupPrinterIP);
      
      // حفظ إعدادات استخدام الطابعات
      await prefs.setBool('use_network_printers', _useNetworkPrinters);
      await prefs.setBool('print_kitchen_receipts', _printKitchenReceipts);
      await prefs.setBool('print_cashier_receipts', _printCashierReceipts);
      await prefs.setBool('print_barista_receipts', _printBaristaReceipts);
      await prefs.setBool('print_shisha_receipts', _printShishaReceipts);
      await prefs.setBool('print_backup_receipts', _printBackupReceipts);
      
      // حفظ ربط الأقسام بالطابعات
      String categoryMappingJson = '{}';
      if (_categoryToPrinter.isNotEmpty) {
        try {
          categoryMappingJson = jsonEncode(_categoryToPrinter);
        } catch (e) {
          print('Error encoding category mapping: $e');
          categoryMappingJson = '{}';
        }
      }
      await prefs.setString('category_to_printer_mapping', categoryMappingJson);
      
      // فرض الحفظ الفوري
      await prefs.commit();
      
      // تأخير بسيط للتأكد من الحفظ الكامل
      await Future.delayed(Duration(milliseconds: 200));
      
      print('✅ Settings saved successfully!');
      print('📊 Category mapping: $_categoryToPrinter');
      print('🖨️ Kitchen enabled: $_printKitchenReceipts');
      print('☕ Barista enabled: $_printBaristaReceipts');
      print('💰 Cashier enabled: $_printCashierReceipts');
      print('🚬 Shisha enabled: $_printShishaReceipts');
      print('💾 Backup enabled: $_printBackupReceipts');
      
    } catch (e) {
      print('❌ Error saving settings: $e');
      rethrow; // إعادة رفع الخطأ للتعامل معه في المستوى الأعلى
    }
  }

  // تحميل الإعدادات
  Future<void> _loadPrinterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('🔄 Loading printer settings...');
      
      // تحميل عناوين IP الطابعات
      _kitchenPrinterIP = prefs.getString('kitchen_printer_ip') ?? '';
      _cashierPrinterIP = prefs.getString('cashier_printer_ip') ?? '';
      _baristaPrinterIP = prefs.getString('barista_printer_ip') ?? '';
      _shishaPrinterIP = prefs.getString('shisha_printer_ip') ?? '';
      _backupPrinterIP = prefs.getString('backup_printer_ip') ?? '';
      
      // تحميل إعدادات استخدام الطابعات
      _useNetworkPrinters = prefs.getBool('use_network_printers') ?? false;
      _printKitchenReceipts = prefs.getBool('print_kitchen_receipts') ?? true;
      _printCashierReceipts = prefs.getBool('print_cashier_receipts') ?? true;
      _printBaristaReceipts = prefs.getBool('print_barista_receipts') ?? true;
      _printShishaReceipts = prefs.getBool('print_shisha_receipts') ?? true;
      _printBackupReceipts = prefs.getBool('print_backup_receipts') ?? false;
      
      // تحميل ربط الأقسام بالطابعات
      String categoryMappingJson = prefs.getString('category_to_printer_mapping') ?? '{}';
      
      print('📄 Raw category mapping JSON: $categoryMappingJson');
      
      try {
        if (categoryMappingJson.isNotEmpty && categoryMappingJson != '{}') {
          Map<String, dynamic> decoded = jsonDecode(categoryMappingJson);
          _categoryToPrinter = Map<String, String>.from(decoded);
        } else {
          _categoryToPrinter = {};
        }
      } catch (e) {
        _categoryToPrinter = {};
        print('❌ Error parsing category mapping JSON: $e');
      }
      
      print('✅ Settings loaded successfully!');
      print('📊 Category mapping: $_categoryToPrinter');
      print('🖨️ Kitchen enabled: $_printKitchenReceipts');
      print('☕ Barista enabled: $_printBaristaReceipts');
      print('💰 Cashier enabled: $_printCashierReceipts');
      print('🚬 Shisha enabled: $_printShishaReceipts');
      print('💾 Backup enabled: $_printBackupReceipts');
      
    } catch (e) {
      print('❌ Critical error loading settings: $e');
      // استخدام القيم الافتراضية
      _kitchenPrinterIP = '';
      _cashierPrinterIP = '';
      _baristaPrinterIP = '';
      _shishaPrinterIP = '';
      _backupPrinterIP = '';
      _useNetworkPrinters = false;
      _printKitchenReceipts = true;
      _printCashierReceipts = true;
      _printBaristaReceipts = true;
      _printShishaReceipts = true;
      _printBackupReceipts = false;
      _categoryToPrinter = {};
      
      print('🔧 Using default settings due to error');
    }
  }

  // طباعة ذكية - توجيه الطلبات للطابعة المناسبة حسب القسم
  Future<void> printOrdersByCategory(
    List<OrderItem> orders,
    Map<String, String> orderCategories, {
    String? tableName,
    pw.ImageProvider? logoImage,
  }) async {
    if (orders.isEmpty) return;
    

    // إذا كان الجهاز أندرويد، أرسل الأمر للسيرفر ليطبعه بدلاً من الطباعة محلياً
    if (Platform.isAndroid) {
      print('📱 Android Device Detected: Sending print request to Server...');
      
      try {
        final orderJsonList = orders.map((o) => o.toJson()).toList();
        
        WebSocketManager().sendMessage({
          'type': 'print_order',
          'deviceId': tableName ?? 'Android Client',
          'tableName': tableName ?? 'Android Client',
          'orders': orderJsonList,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        print('✅ Print request sent to server successfully');
        return; // توقف هنا، لا تكمل الطباعة المحلية
      } catch (e) {
        print('❌ Failed to send print request to server: $e');
      }
    }

    // تأكد من تحميل الإعدادات أولاً
    await ensureInitialized();

    // تصنيف الطلبات حسب الطابعة المخصصة
    Map<String, List<OrderItem>> ordersByPrinter = {};
    
    for (int i = 0; i < orders.length; i++) {
      OrderItem order = orders[i];
      String category = orderCategories[order.name] ?? 'unknown';
      String? printerType = getPrinterForCategory(category);
      
      // إذا لم يكن هناك طابعة مخصصة، لا تطبع شيء (تجاهل العنصر)
      if (printerType == null) {
        print('⚠️ لا توجد طابعة مخصصة للعنصر: ${order.name} (قسم: $category)');
        continue; // تجاهل هذا العنصر
      }
      
      ordersByPrinter.putIfAbsent(printerType, () => []);
      ordersByPrinter[printerType]!.add(order);
    }

    // طباعة كل مجموعة على الطابعة المخصصة لها
    for (String printerType in ordersByPrinter.keys) {
      List<OrderItem> printerOrders = ordersByPrinter[printerType]!;
      await _printToSpecificPrinter(printerOrders, printerType, tableName: tableName, logoImage: logoImage);
    }
  }

  // طباعة على طابعة محددة
  Future<void> _printToSpecificPrinter(
    List<OrderItem> orders,
    String printerType, {
    String? tableName,
    pw.ImageProvider? logoImage,
  }) async {
    if (orders.isEmpty) return;

    switch (printerType) {
      case 'kitchen':
        if (_printKitchenReceipts) {
          await _printKitchenReceipt(orders, 'المطبخ', tableName: tableName, logoImage: logoImage);
        }
        break;
      case 'barista':
        if (_printBaristaReceipts) {
          await _printKitchenReceipt(orders, 'الباريستا', tableName: tableName, logoImage: logoImage);
        }
        break;
      case 'shisha':
        if (_printShishaReceipts) {
          await _printKitchenReceipt(orders, 'اراكيل', tableName: tableName, logoImage: logoImage);
        }
        break;
      case 'backup':
        if (_printBackupReceipts) {
          await _printKitchenReceipt(orders, 'احتياطية', tableName: tableName, logoImage: logoImage);
        }
        break;
      case 'cashier':
        if (_printCashierReceipts) {
          await _printKitchenReceipt(orders, 'الكاشير', tableName: tableName, logoImage: logoImage);
        }
        break;
      default:
        // عناصر غير مخصصة - لا تطبع
        print('⚠️ عنصر غير مخصص: لن يتم طباعته');
        break;
    }
  }

  // دالة مساعدة لطباعة فاتورة مطبخ مع اسم الطابعة
  Future<void> _printKitchenReceipt(
    List<OrderItem> orders,
    String printerName, {
    String? tableName,
    pw.ImageProvider? logoImage,
  }) async {
    // استخدام نفس تصميم الحساب للجميع
    final pdf = await _createUnifiedReceipt(
      orders, 
      title: 'طلب $printerName',
      tableName: tableName,
      printerName: printerName,
      logoImage: logoImage,
    );
    
    String printerIP = printerName;

    
    await _printToNetworkPrinter(
      pdf, 
      printerIP,
      name: 'طلب $printerName - ${tableName ?? 'البيع المباشر'}',
    );
  }

  // طباعة فاتورة المطبخ/الباريستا (للطلبات) - بالتصميم الموحد
  Future<void> printKitchenOrder(
    List<OrderItem> orders, {
    String? tableName,
    pw.ImageProvider? logoImage,
  }) async {
    if (!_printKitchenReceipts || orders.isEmpty) return;

    final pdf = await _createUnifiedReceipt(
      orders, 
      title: 'طلب المطبخ',
      tableName: tableName,
      printerName: 'المطبخ',
      logoImage: logoImage,
    );
    
    await _printToNetworkPrinter(
      pdf, 
      _kitchenPrinterIP,
      name: 'فاتورة مطبخ - ${tableName ?? 'البيع المباشر'}',
    );
  }

  // طباعة حساب الكاشير (للحسابات النهائية) - بالتصميم الموحد
  Future<void> printCashierBill(
    List<OrderItem> orders, {
    String? title,
    String? tableName,
    pw.ImageProvider? logoImage,
  }) async {

    // Android Support: Send Bill to Server
    if (Platform.isAndroid) {
      try {
        final orderJsonList = orders.map((o) => o.toJson()).toList();
        
        WebSocketManager().sendMessage({
          'type': 'print_bill',
          'deviceId': tableName ?? 'Android Client',
          'tableName': tableName ?? 'Android Client',
          'title': title ?? 'فاتورة نهائية',
          'orders': orderJsonList,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        print('✅ Bill print request sent to server');
        return;
      } catch (e) {
        print('❌ Failed to send bill request: $e');
      }
    }

    if (!_printCashierReceipts || orders.isEmpty) return;

    final pdf = await _createUnifiedReceipt(
      orders, 
      title: title ?? 'حساب الكاشير',
      tableName: tableName,
      printerName: 'الكاشير',
      logoImage: logoImage,
      showTotal: true, // إظهار الإجمالي ورسالة الشكر في فاتورة الحساب
    );
    
    await _printToNetworkPrinter(
      pdf, 
       'طابعة الكاشير',
      name: 'حساب الكاشير - ${tableName ?? 'البيع المباشر'}',
    );
  }

  // إنشاء فاتورة موحدة لجميع الطابعات بنفس تصميم الحساب
  Future<pw.Document> _createUnifiedReceipt(
    List<OrderItem> orders, {
    String? title,
    String? tableName,
    String? printerName,
    pw.ImageProvider? logoImage,
    bool showTotal = false, // إظهار الإجمالي فقط في فاتورة الحساب
  }) async {
    final pdf = pw.Document();
    // استخدام خط Noto Naskh Arabic الذي يدعم العربية والإنجليزية معاً بشكل مثالي
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicMedium(); // خط نوتو نسخ - أفضل خط للعربية والإنجليزية
    final titleFont = await PdfGoogleFonts.notoNaskhArabicBold(); // خط نوتو نسخ العريض للعناوين
    final bodyFont = await PdfGoogleFonts.notoNaskhArabicRegular(); // خط نوتو نسخ العادي للنصوص
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(now);
    const hallName = 'BERLIN GAME';

pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat(
      58 * PdfPageFormat.mm,   // عرض طابعة 58mm
      250 * PdfPageFormat.mm,  // ارتفاع كبير وآمن
      marginAll: 4,
    ),
    build: (context) => [
      pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [

            // ===== LOGO =====
            if (logoImage != null) ...[
              pw.Center(
                child: pw.Image(logoImage, height: 70, width: 70),
              ),
              pw.SizedBox(height: 4),
            ],

            // ===== HALL NAME =====
            pw.Text(
              hallName,
              style: pw.TextStyle(
                font: titleFont,
                fontSize: 22,
                letterSpacing: 1,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 2),

            // ===== TABLE =====
            if (tableName != null && tableName.isNotEmpty)
              pw.Text(
                'الطاولة: $tableName',
                style: pw.TextStyle(font: arabicFont, fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),

            pw.SizedBox(height: 2),

            // ===== DATE =====
            pw.Text(
              'التاريخ: $formattedDate',
              style: pw.TextStyle(font: bodyFont, fontSize: 11),
              textAlign: pw.TextAlign.center,
            ),

            if (title != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],

            pw.Divider(thickness: 1),

            // ===== TABLE HEADER =====
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  children: [
                    _th('المنتج', titleFont),
                    _th('الكمية', titleFont),
                    _th('السعر', titleFont),
                  ],
                ),

                // ===== ORDERS =====
                ...orders.map((order) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(order.name,
                              style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                          if (order.notes != null && order.notes!.isNotEmpty)
                            pw.Text(
                              order.name == 'ملاحظة'
                                  ? order.notes!
                                  : 'ملاحظة: ${order.notes}',
                              style: pw.TextStyle(font: bodyFont, fontSize: 9),
                            ),
                        ],
                      ),
                    ),
                    _td(order.quantity.toString() , bodyFont),
                    _td('${(order.price * order.quantity).toInt()} د.ع', bodyFont),
                  ],
                )),
              ],
            ),

            // ===== TOTAL =====
            if (showTotal) ...[
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('إجمالي العناصر',
                        style: pw.TextStyle(font: titleFont, fontSize: 11)),
                    pw.Text(
                      '${orders.fold(0, (s, o) => s + o.quantity)}',
                      style: pw.TextStyle(font: titleFont, fontSize: 11),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المجموع الكلي',
                        style: pw.TextStyle(font: titleFont, fontSize: 13)),
                    pw.Text(
                      '${((orders.fold(0.0, (s, o) => s + (o.price * o.quantity)) / 250).round().toDouble() * 250).toInt()} د.ع',
                      style: pw.TextStyle(font: titleFont, fontSize: 14),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 4),
              pw.Text(
                'تم التقريب ل 250',
                style: pw.TextStyle(font: bodyFont, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'شكراً لزيارتكم',
                style: pw.TextStyle(font: arabicFont, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
            ],

            pw.SizedBox(height: 8),
            pw.Text(
              'تم الطباعة: ${DateTime.now().toString().substring(11, 19)}',
              style: pw.TextStyle(font: bodyFont, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    ],
  ),
);

    return pdf;
  }
pw.Widget _th(String text, pw.Font font) => pw.Padding(
  padding: const pw.EdgeInsets.all(4),
  child: pw.Text(
    text,
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
);

pw.Widget _td(String text, pw.Font font) => pw.Padding(
  padding: const pw.EdgeInsets.all(4),
  child: pw.Text(
    text,
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(
      font: font,
      fontSize: 10,
    ),
  ),
);





  // دالة للتحقق من صلاحيات الطباعة (فقط super_admin)
  Future<bool> _canPrint() async {
    final authService = AuthService();
    if (!await authService.isLoggedIn()) {
       print('🚫 Printing blocked: Not logged in');
       return false;
    }
    
    final username = await authService.getLoggedInUsername();
    if (username != 'super_admin') {
      print('🚫 Printing blocked: User "$username" is not super_admin');
      return false;
    }
    return true;
  }

  // طباعة على طابعة الشبكة باستخدام عنوان IP المكون
  Future<void> _printToNetworkPrinter(
    pw.Document pdf, 
    String printerIP, {
    String? name,
  }) async {
    // التحقق من الصلاحيات قبل الطباعة
    if (!await _canPrint()) return;

    try {
      // if (printerIP.isEmpty) {
      //   print('⚠️ لم يتم تحديد عنوان IP للطابعة، استخدام الطابعة الافتراضية');
      //   await Printing.layoutPdf(
      //     onLayout: (format) async => pdf.save(),
      //   );
      //   return;
      // }

      // الحصول على قائمة الطابعات المتاحة
      final printers = await Printing.listPrinters();
      
      // البحث عن الطابعة المطابقة للـ IP أو الاسم
      Printer? selectedPrinter;
            print('printerIP: $printerIP');

      for (var printer in printers) {
        // print('Checking printer: ${printer.name} | URL: ${printer.url}');
        

        // إذا كان IP فارغ، نستخدم الطابعة الافتراضية
        if (printerIP.isEmpty) {
          print('⚠️ لم يتم تحديد طابعة، سيتم استخدام الطابعة الافتراضية');
          break;
        }

        // محاولة المطابقة بـ IP أو الاسم أو URL
        if (printerIP.isNotEmpty) {
          // تطابق مع URL (غالباً يحتوي على IP)
          if (printer.url != null && printer.url!.contains(printerIP)) {
             selectedPrinter = printer;
             print('✅ Found by URL: ${printer.name} ($printerIP)');
          }
           // تطابق مع الاسم (إذا كان المستخدم أدخل الاسم بدلاً من IP)
          else if (printer.name.toLowerCase().contains(printerIP.toLowerCase())) {
             selectedPrinter = printer;
             print('✅ Found by Name: ${printer.name} ($printerIP)');
          }
        }

        // إذا وجدنا الطابعة، نخرج من الحلقة
        if (selectedPrinter != null) break;
      }


      
      // إذا لم يتم العثور على طابعة محددة، استخدام الطابعة الافتراضية
      if (selectedPrinter == null) {
        print('⚠️ لم يتم العثور على طابعة تطابق IP: $printerIP، استخدام الطابعة الافتراضية');
      }
      
      // طباعة مباشرة إلى الطابعة المختارة
      print('11111111111111111111111111111');
      print(selectedPrinter.toString());
      await Printing.directPrintPdf(
        printer: Printer(
          url: selectedPrinter?.url ?? '',

        ),
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      print('❌ خطأ في الطباعة: $e');
      // في حالة الفشل، محاولة الطباعة بدون تحديد طابعة
      try {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
        );
      } catch (fallbackError) {
        print('❌ فشل الطباعة أيضاً بدون تحديد طابعة: $fallbackError');
      }
    }
  }

  // اختبار الاتصال بالطابعة
  Future<bool> testPrinterConnection(String printerIP) async {
    try {
      // يمكن تطوير اختبار الاتصال هنا
      return true;
    } catch (e) {
      return false;
    }
  }

  // تحميل اللوغو من assets
  Future<pw.ImageProvider?> loadLogoFromAssets(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (e) {
      print('خطأ في تحميل اللوغو: $e');
      return null;
    }
  }

  // تحميل اللوغو من ملف محلي
  Future<pw.ImageProvider?> loadLogoFromFile(Uint8List fileBytes) async {
    try {
      return pw.MemoryImage(fileBytes);
    } catch (e) {
      print('خطأ في تحميل اللوغو من الملف: $e');
      return null;
    }
  }
}
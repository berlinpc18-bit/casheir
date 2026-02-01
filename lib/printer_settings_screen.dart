import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'printer_service.dart';
import 'app_state.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> with RouteAware {
  // Controllers لإعدادات الطابعات
  final TextEditingController _kitchenPrinterIPController = TextEditingController();
  final TextEditingController _baristaPrinterIPController = TextEditingController();
  final TextEditingController _cashierPrinterIPController = TextEditingController();
  final TextEditingController _shishaPrinterIPController = TextEditingController();
  final TextEditingController _backupPrinterIPController = TextEditingController();
  final TextEditingController _kitchenPrinterNameController = TextEditingController();
  final TextEditingController _baristaPrinterNameController = TextEditingController();
  final TextEditingController _cashierPrinterNameController = TextEditingController();
  final TextEditingController _shishaPrinterNameController = TextEditingController();
  final TextEditingController _backupPrinterNameController = TextEditingController();

  // إعدادات الطابعات
  bool _printKitchenReceipts = true;
  bool _printBaristaReceipts = true;
  bool _printCashierReceipts = true;
  bool _printShishaReceipts = true;
  bool _printBackupReceipts = false;
  bool _useNetworkPrinters = false;

  // أقسام كل طابعة - سيتم تحديثها حسب الأقسام المتاحة
  List<String> _kitchenCategories = [];
  List<String> _baristaCategories = [];
  List<String> _cashierCategories = [];
  List<String> _shishaCategories = [];
  List<String> _backupCategories = [];

  // سيتم تحميل الأقسام من AppState
  List<String> _allCategories = [];
  
  // مرجع لـ AppState للتنظيف اللاحق
  AppState? _appStateRef;
  
  // فلاج لضمان عدم حذف الأقسام المرغوبة إلا في المرة الأولى
  static bool _hasCleanedUnwantedCategories = false;
  
  // دالة لإعادة تعيين فلاج التنظيف (للاختبار أو الحالات الخاصة)
  static void resetCleaningFlag() {
    _hasCleanedUnwantedCategories = false;
    print('🔄 تم إعادة تعيين فلاج تنظيف الأقسام');
  }
  
  // دالة لتعطيل التنظيف التلقائي نهائياً (لحماية الأقسام الجديدة)
  static void disableAutoCleaning() {
    _hasCleanedUnwantedCategories = true;
    print('🛡️ تم تعطيل التنظيف التلقائي للأقسام نهائياً - حماية للأقسام الجديدة');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSettings();
      
      // الاستماع لتغيرات AppState
      _appStateRef = context.read<AppState>();
      _appStateRef?.addListener(_onAppStateChanged);
    });
  }
  
  // دالة تستمع لتغيرات AppState
  void _onAppStateChanged() {
    if (_appStateRef == null || !mounted) return;
    
    final updatedCategories = _appStateRef!.customCategories.keys.toList();
    
    // تحديث الأقسام إذا تغيرت
    if (_allCategories.length != updatedCategories.length || 
        !_allCategories.every((cat) => updatedCategories.contains(cat))) {
      
      print('🔔 تغيير في AppState - تحديث أقسام الطابعات');
      
      // للتعامل مع تحديث أسماء الأقسام والأقسام الجديدة
      if (_allCategories.length == updatedCategories.length) {
        // نفس العدد يعني تم تعديل اسم قسم
        print('🏷️ تم اكتشاف تعديل في اسم قسم - إعادة تحميل الإعدادات');
        _reloadCategoryMappings();
      } else if (_allCategories.length < updatedCategories.length) {
        // زيادة في العدد يعني إضافة قسم جديد
        final newCategories = updatedCategories.where((cat) => !_allCategories.contains(cat)).toList();
        print('➕ قسم جديد مضاف: $newCategories');
        // لا نحتاج لحذف أي شيء، فقط تحديث القائمة
      } else {
        // نقصان في العدد يعني حذف أقسام
        _removeDeletedCategoriesFromPrinters(updatedCategories);
      }
      
      _allCategories = updatedCategories;
      
      // تحديث الواجهة
      setState(() {});
    }
  }
  
  // إعادة تحميل ربط الأقسام من PrinterService
  Future<void> _reloadCategoryMappings() async {
    try {
      final printerService = PrinterService();
      await printerService.ensureInitialized();
      
      // إعادة تحميل ربط الأقسام
      _loadCategoryMappingFromService(printerService);
      
      print('✅ تم إعادة تحميل ربط الأقسام بعد تحديث الاسم');
    } catch (e) {
      print('❌ خطأ في إعادة تحميل ربط الأقسام: $e');
    }
  }
  
  @override
  void dispose() {
    // إزالة الـ listener
    _appStateRef?.removeListener(_onAppStateChanged);
    
    // تنظيف Controllers
    _kitchenPrinterIPController.dispose();
    _baristaPrinterIPController.dispose();
    _cashierPrinterIPController.dispose();
    _shishaPrinterIPController.dispose();
    _backupPrinterIPController.dispose();
    _kitchenPrinterNameController.dispose();
    _baristaPrinterNameController.dispose();
    _cashierPrinterNameController.dispose();
    _shishaPrinterNameController.dispose();
    _backupPrinterNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث الأقسام المتاحة عند تغيير AppState
    final appState = context.read<AppState>();
    final updatedCategories = appState.customCategories.keys.toList();
    
    // تحديث الأقسام المتاحة إذا تغيرت
    if (_allCategories.length != updatedCategories.length || 
        !_allCategories.every((cat) => updatedCategories.contains(cat))) {
      
      // للتعامل مع تحديث أسماء الأقسام والأقسام الجديدة
      if (_allCategories.length == updatedCategories.length) {
        // نفس العدد يعني تم تعديل اسم قسم - إعادة تحميل فقط
        print('🏷️ تحديث اسم قسم - إعادة تحميل الربط');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _reloadCategoryMappings();
        });
      } else if (_allCategories.length < updatedCategories.length) {
        // زيادة في العدد يعني إضافة قسم جديد
        final newCategories = updatedCategories.where((cat) => !_allCategories.contains(cat)).toList();
        print('➕ أقسام جديدة مضافة: $newCategories');
        // لا نحتاج لحذف أي شيء، فقط تحديث القائمة
      } else {
        // نقصان في العدد يعني حذف أقسام
        _removeDeletedCategoriesFromPrinters(updatedCategories);
      }
      
      _allCategories = updatedCategories;
      
      // تحديث الواجهة
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  // دالة يتم استدعاؤها عند العودة للشاشة
  void didPopNext() {
    print('🔄 العودة لشاشة إعدادات الطابعات - تحديث الأقسام...');
    _refreshCategories();
  }
  
  // تحديث الأقسام عند العودة للشاشة
  Future<void> _refreshCategories() async {
    final appState = context.read<AppState>();
    final updatedCategories = appState.customCategories.keys.toList();
    
    if (_allCategories.length != updatedCategories.length || 
        !_allCategories.every((cat) => updatedCategories.contains(cat))) {
      
      print('📋 تحديث الأقسام: من ${_allCategories.length} إلى ${updatedCategories.length}');
      
      // للتعامل مع تحديث أسماء الأقسام والأقسام الجديدة
      if (_allCategories.length == updatedCategories.length) {
        // نفس العدد يعني تم تعديل اسم قسم
        print('🏷️ تم اكتشاف تعديل في اسم قسم - إعادة تحميل الربط');
        await _reloadCategoryMappings();
      } else if (_allCategories.length < updatedCategories.length) {
        // زيادة في العدد يعني إضافة قسم جديد
        final newCategories = updatedCategories.where((cat) => !_allCategories.contains(cat)).toList();
        print('➕ أقسام جديدة مضافة: $newCategories');
        // لا نحتاج لحذف أي شيء، فقط تحديث القائمة
      } else {
        // نقصان في العدد يعني حذف أقسام
        _removeDeletedCategoriesFromPrinters(updatedCategories);
      }
      
      _allCategories = updatedCategories;
      
      // تحديث الواجهة
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadSettings() async {
    print('📥 بدء تحميل إعدادات الطابعات في الواجهة...');
    
    // تحميل إعدادات الطابعات من PrinterService
    final printerService = PrinterService();
    
    // تأكد من تحميل الإعدادات أولاً
    await printerService.ensureInitialized();
    
    // تحميل عناوين IP
    _kitchenPrinterIPController.text = printerService.kitchenPrinterIP;
    _baristaPrinterIPController.text = printerService.baristaPrinterIP;
    _cashierPrinterIPController.text = printerService.cashierPrinterIP;
    _shishaPrinterIPController.text = printerService.shishaPrinterIP;
    _backupPrinterIPController.text = printerService.backupPrinterIP;
    
    // تحميل حالات الطابعات مع تسجيل التشخيص
    _printKitchenReceipts = printerService.printKitchenReceipts;
    _printBaristaReceipts = printerService.printBaristaReceipts;
    _printCashierReceipts = printerService.printCashierReceipts;
    _printShishaReceipts = printerService.printShishaReceipts;
    _printBackupReceipts = printerService.printBackupReceipts;
    _useNetworkPrinters = printerService.useNetworkPrinters;
    
    // طباعة حالات الطابعات للتشخيص
    print('🏷️ حالات الطابعات المحملة:');
    print('  المطبخ: $_printKitchenReceipts');
    print('  الباريستا: $_printBaristaReceipts');
    print('  الكاشير: $_printCashierReceipts');
    print('  اراكيل: $_printShishaReceipts');
    print('  الاحتياطية: $_printBackupReceipts');
    
    // تحميل أسماء الطابعات
    _kitchenPrinterNameController.text = 'طابعة المطبخ الرئيسية';
    _baristaPrinterNameController.text = 'طابعة الباريستا';
    _cashierPrinterNameController.text = 'طابعة الكاشير';
    _shishaPrinterNameController.text = 'طابعة اراكيل';
    _backupPrinterNameController.text = 'طابعة احتياطية';
    
    // تحميل الأقسام المتاحة من AppState فقط (الأقسام المخصصة التي أنشأها المستخدم)
    final appState = context.read<AppState>();
    
    // تم تعطيل التنظيف التلقائي للأقسام لحماية الأقسام الجديدة التي يضيفها المستخدم
    // المستخدم يمكنه حذف الأقسام غير المرغوبة يدوياً من الإعدادات
    if (!_hasCleanedUnwantedCategories) {
      // await _removeUnwantedCategories(appState);  // معطل مؤقتاً
      _hasCleanedUnwantedCategories = true;
      print('🛡️ تم تعطيل التنظيف التلقائي لحماية الأقسام الجديدة');
      
      // تعطيل التنظيف التلقائي نهائياً لحماية الأقسام الجديدة
      disableAutoCleaning();
    }
    
    // تحديث الأقسام المتاحة
    _allCategories = appState.customCategories.keys.toList();
    print('📋 الأقسام المتاحة حالياً: $_allCategories');
    
    // تحميل ربط الأقسام المحفوظة
    _loadCategoryMappingFromService(printerService);
    
    print('Loaded settings - Categories mapping: ${printerService.categoryToPrinter}'); // للتشخيص
    
    // تحديث الواجهة بعد تحميل جميع الإعدادات
    if (mounted) {
      setState(() {});
    }
    
    print('✅ اكتمل تحميل جميع إعدادات الطابعات في الواجهة');
  }
  
  void _loadCategoryMappingFromService(PrinterService printerService) {
    // تم إزالة قائمة الأقسام المرفوضة - الآن سيتم تحميل جميع الأقسام المحفوظة
    // المستخدم يمكنه إدارة الأقسام بنفسه من الواجهة
    
    // مسح الأقسام الحالية
    _kitchenCategories.clear();
    _baristaCategories.clear();
    _cashierCategories.clear();
    _shishaCategories.clear();
    _backupCategories.clear();
    
    // تحميل الأقسام من الربط المحفوظ (جميع الأقسام)
    final categoryMapping = printerService.categoryToPrinter;
    
    print('📥 تحميل ربط الأقسام: $categoryMapping');
    
    for (String category in categoryMapping.keys) {
      String? printerType = categoryMapping[category];
      print('� ربط القسم "$category" بالطابعة: $printerType');
      
      switch (printerType) {
        case 'kitchen':
          _kitchenCategories.add(category);
          break;
        case 'barista':
          _baristaCategories.add(category);
          break;
        case 'cashier':
          _cashierCategories.add(category);
          break;
        case 'shisha':
          _shishaCategories.add(category);
          break;
        case 'backup':
          _backupCategories.add(category);
          break;
      }
    }
    
    // إذا لم توجد أقسام محفوظة، استخدم الأقسام الافتراضية
    if (categoryMapping.isEmpty) {
      _setDefaultCategoriesForPrinters();
    }
    
    // طباعة النتائج النهائية لجميع الطابعات
    print('📊 الأقسام المحملة نهائياً:');
    print('  🍳 المطبخ: $_kitchenCategories');
    print('  ☕ الباريستا: $_baristaCategories');
    print('  💰 الكاشير: $_cashierCategories');
    print('  🚬 اراكيل: $_shishaCategories');
    print('  🔄 الاحتياطية: $_backupCategories');
    
    // تحديث الواجهة بعد تحميل البيانات
    if (mounted) {
      setState(() {});
    }
  }
  
  void _setDefaultCategoriesForPrinters() {
    // لا يتم تعيين أي أقسام تلقائياً - كل شيء يدوي
    // جميع قوائم الطابعات تبدأ فارغة
    _kitchenCategories.clear();
    _baristaCategories.clear();
    _cashierCategories.clear();
    _shishaCategories.clear();
    _backupCategories.clear();
    
    print('📋 تم إعداد أقسام فارغة - يجب إضافة الأقسام يدوياً لكل طابعة');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // تحديث الأقسام المتاحة عند تغيير AppState (فقط الأقسام المخصصة)
        final updatedCategories = appState.customCategories.keys.toList();
        
        // تحديث الأقسام المتاحة والتنظيف إذا تغيرت
        if (_allCategories.length != updatedCategories.length || 
            !_allCategories.every((cat) => updatedCategories.contains(cat))) {
          
          print('🔄 تحديث أقسام الطابعات - الأقسام المتاحة: ${updatedCategories.length}');
          
          // التحقق من نوع التغيير
          if (_allCategories.length < updatedCategories.length) {
            final newCategories = updatedCategories.where((cat) => !_allCategories.contains(cat)).toList();
            print('➕ أقسام جديدة في الواجهة: $newCategories');
          } else if (_allCategories.length > updatedCategories.length) {
            // إزالة الأقسام المحذوفة من جميع الطابعات
            _removeDeletedCategoriesFromPrinters(updatedCategories);
          }
          
          _allCategories = updatedCategories;
        }
        
        return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
            ),
          ),
        ),
        title: Text(
          'إعدادات الطابعات',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والوصف
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة الطابعات المتقدمة',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تخصيص الطابعات والأقسام لكل نوع من الطلبات',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // طابعة المطبخ
            _buildPrinterCard(
              title: 'طابعة المطبخ',
              subtitle: 'لطلبات المطبخ والأطعمة',
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              ipController: _kitchenPrinterIPController,
              nameController: _kitchenPrinterNameController,
              isEnabled: _printKitchenReceipts,
              categories: _kitchenCategories,
              onToggle: (value) {
                setState(() {
                  _printKitchenReceipts = value;
                });
              },
              onManageCategories: () => _manageKitchenCategories(),
            ),

            const SizedBox(height: 20),

            // طابعة الباريستا
            _buildPrinterCard(
              title: 'طابعة الباريستا',
              subtitle: 'للمشروبات والقهوة',
              icon: Icons.coffee,
              color: Colors.brown,
              ipController: _baristaPrinterIPController,
              nameController: _baristaPrinterNameController,
              isEnabled: _printBaristaReceipts,
              categories: _baristaCategories,
              onToggle: (value) {
                setState(() {
                  _printBaristaReceipts = value;
                });
              },
              onManageCategories: () => _manageBaristaCategories(),
            ),

            const SizedBox(height: 20),

            // طابعة الكاشير
            _buildPrinterCard(
              title: 'طابعة الكاشير',
              subtitle: 'للحسابات النهائية والفواتير',
              icon: Icons.receipt_long,
              color: Colors.green,
              ipController: _cashierPrinterIPController,
              nameController: _cashierPrinterNameController,
              isEnabled: _printCashierReceipts,
              categories: _cashierCategories,
              onToggle: (value) {
                setState(() {
                  _printCashierReceipts = value;
                });
              },
              onManageCategories: () => _manageCashierCategories(),
            ),

            const SizedBox(height: 20),

            // طابعة اراكيل
            _buildPrinterCard(
              title: 'طابعة اراكيل',
              subtitle: 'للشيشة ومنتجات التدخين',
              icon: Icons.smoking_rooms,
              color: Colors.purple,
              ipController: _shishaPrinterIPController,
              nameController: _shishaPrinterNameController,
              isEnabled: _printShishaReceipts,
              categories: _shishaCategories,
              onToggle: (value) {
                setState(() {
                  _printShishaReceipts = value;
                });
              },
              onManageCategories: () => _manageShishaCategories(),
            ),

            const SizedBox(height: 20),

            // طابعة احتياطية
            _buildPrinterCard(
              title: 'طابعة احتياطية',
              subtitle: 'للطوارئ وجميع الأقسام',
              icon: Icons.backup,
              color: Colors.grey,
              ipController: _backupPrinterIPController,
              nameController: _backupPrinterNameController,
              isEnabled: _printBackupReceipts,
              categories: _backupCategories,
              onToggle: (value) {
                setState(() {
                  _printBackupReceipts = value;
                });
              },
              onManageCategories: () => _manageBackupCategories(),
            ),

            const SizedBox(height: 30),

            // إعدادات عامة
            _buildGeneralSettings(),

            const SizedBox(height: 30),

            // أزرار الإجراءات
            _buildActionButtons(),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildPrinterCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required TextEditingController ipController,
    required TextEditingController nameController,
    required bool isEnabled,
    required List<String> categories,
    required ValueChanged<bool> onToggle,
    required VoidCallback onManageCategories,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: color,
                activeTrackColor: color.withOpacity(0.3),
              ),
            ],
          ),

          if (isEnabled) ...[
            const SizedBox(height: 20),

            // عرض الأقسام المخصصة لهذه الطابعة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category_outlined, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'الأقسام المخصصة (${categories.length})',
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  categories.isEmpty 
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'لا توجد أقسام مخصصة لهذه الطابعة',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: categories.map((category) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // اسم الطابعة
            TextField(
              controller: nameController,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'اسم الطابعة',
                labelStyle: TextStyle(color: color),
                prefixIcon: Icon(Icons.label_outline, color: color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                filled: true,
                fillColor: color.withOpacity(0.05),
              ),
            ),

            const SizedBox(height: 16),

            // عنوان IP
            TextField(
              controller: ipController,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'عنوان IP (اختياري)',
                labelStyle: TextStyle(color: color),
                prefixIcon: Icon(Icons.network_check, color: color),
                hintText: '192.168.1.100',
                hintStyle: TextStyle(color: color.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                filled: true,
                fillColor: color.withOpacity(0.05),
              ),
            ),

            const SizedBox(height: 16),

            // زر إدارة الأقسام
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManageCategories,
                icon: Icon(Icons.category_outlined, size: 18),
                label: Text('إدارة الأقسام'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'إعدادات عامة',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // تفعيل طابعات الشبكة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استخدام طابعات الشبكة',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الاتصال بالطابعات عبر عناوين IP',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white70 
                              : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useNetworkPrinters,
                  onChanged: (value) {
                    setState(() {
                      _useNetworkPrinters = value;
                    });
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // زر حفظ الإعدادات
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded, size: 20),
            label: const Text('حفظ الإعدادات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // دوال إدارة الأقسام
  void _manageKitchenCategories() {
    // تحديث الأقسام المتاحة قبل فتح النافذة
    _refreshCategories();
    
    _showCategoriesDialog(
      title: 'أقسام طابعة المطبخ',
      color: Colors.orange,
      currentCategories: _kitchenCategories,
      onSave: (categories) async {
        print('💾 حفظ أقسام المطبخ: $categories');
        setState(() {
          _kitchenCategories = categories;
        });
        print('✅ تم تحديث أقسام المطبخ في المتغير المحلي: $_kitchenCategories');
        // حفظ التغييرات فوراً
        await _saveSettings();
      },
    );
  }

  void _manageBaristaCategories() {
    // تحديث الأقسام المتاحة قبل فتح النافذة
    _refreshCategories();
    
    _showCategoriesDialog(
      title: 'أقسام طابعة الباريستا',
      color: Colors.brown,
      currentCategories: _baristaCategories,
      onSave: (categories) async {
        print('💾 حفظ أقسام الباريستا: $categories');
        setState(() {
          _baristaCategories = categories;
        });
        print('✅ تم تحديث أقسام الباريستا في المتغير المحلي: $_baristaCategories');
        // حفظ التغييرات فوراً
        await _saveSettings();
      },
    );
  }

  void _manageCashierCategories() {
    // تحديث الأقسام المتاحة قبل فتح النافذة
    _refreshCategories();
    
    _showCategoriesDialog(
      title: 'أقسام طابعة الكاشير',
      color: Colors.green,
      currentCategories: _cashierCategories,
      onSave: (categories) async {
        print('💾 حفظ أقسام الكاشير: $categories');
        setState(() {
          _cashierCategories = categories;
        });
        print('✅ تم تحديث أقسام الكاشير في المتغير المحلي: $_cashierCategories');
        // حفظ التغييرات فوراً
        await _saveSettings();
      },
    );
  }

  void _manageShishaCategories() {
    // تحديث الأقسام المتاحة قبل فتح النافذة
    _refreshCategories();
    
    _showCategoriesDialog(
      title: 'أقسام طابعة اراكيل',
      color: Colors.purple,
      currentCategories: _shishaCategories,
      onSave: (categories) async {
        print('💾 حفظ أقسام اراكيل: $categories');
        setState(() {
          _shishaCategories = categories;
        });
        print('✅ تم تحديث أقسام اراكيل في المتغير المحلي: $_shishaCategories');
        // حفظ التغييرات فوراً
        await _saveSettings();
      },
    );
  }

  void _manageBackupCategories() {
    // تحديث الأقسام المتاحة قبل فتح النافذة
    _refreshCategories();
    
    _showCategoriesDialog(
      title: 'أقسام الطابعة الاحتياطية',
      color: Colors.grey,
      currentCategories: _backupCategories,
      onSave: (categories) async {
        print('💾 حفظ أقسام الطابعة الاحتياطية: $categories');
        setState(() {
          _backupCategories = categories;
        });
        print('✅ تم تحديث أقسام الطابعة الاحتياطية في المتغير المحلي: $_backupCategories');
        // حفظ التغييرات فوراً
        await _saveSettings();
      },
    );
  }

  void _showCategoriesDialog({
    required String title,
    required Color color,
    required List<String> currentCategories,
    required Future<void> Function(List<String>) onSave,
  }) {
    // تحديث الأقسام المتاحة قبل فتح النافذة
    final appState = context.read<AppState>();
    _allCategories = appState.customCategories.keys.toList();
    
    List<String> selectedCategories = List.from(currentCategories);
    // إزالة أي أقسام محذوفة من القائمة المحددة
    selectedCategories.removeWhere((category) => !_allCategories.contains(category));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // دالة محلية لتحديث العداد
          void updateSelection(String category, bool isSelected) {
            setDialogState(() {
              if (isSelected) {
                selectedCategories.add(category);
              } else {
                selectedCategories.remove(category);
              }
            });
          }
          
          return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${selectedCategories.length} من ${_allCategories.length} أقسام محددة',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر الأقسام التي ستطبعها هذه الطابعة:',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  child: _allCategories.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد أقسام مخصصة',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'يمكنك إنشاء أقسام جديدة من الإعدادات الرئيسية',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _allCategories.length,
                        itemBuilder: (context, index) {
                      final category = _allCategories[index];
                      final isSelected = selectedCategories.contains(category);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) => updateSelection(category, value!),
                          title: Consumer<AppState>(
                            builder: (context, appState, child) {
                              final itemCount = appState.customCategories[category]?.length ?? 0;
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white 
                                            : Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (itemCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: color.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          activeColor: color,
                          checkColor: Colors.white,
                          side: BorderSide(color: color.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      );
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await onSave(selectedCategories);
                Navigator.pop(context);
                
                // تحديث الأقسام المتاحة بعد الحفظ
                final appState = context.read<AppState>();
                _allCategories = appState.customCategories.keys.toList();
                
                // تحديث الواجهة
                if (mounted) {
                  setState(() {});
                }
                
                _showSuccessMessage('تم حفظ أقسام الطابعة بنجاح');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text('حفظ'),
            ),
          ],
          );
        },
      ),
    );
  }


  Future<void> _saveSettings() async {
    try {
      print('💾 بدء حفظ إعدادات الطابعات...');
      
      // تحديث الأقسام المتاحة قبل الحفظ
      final appState = context.read<AppState>();
      _allCategories = appState.customCategories.keys.toList();
      print('📋 الأقسام المتاحة عند الحفظ: $_allCategories');
      
      // تنظيف الأقسام المحذوفة من جميع الطابعات
      _removeDeletedCategoriesFromPrinters(_allCategories);
      
      print('🏷️ حالات الطابعات قبل الحفظ:');
      print('  المطبخ: $_printKitchenReceipts');
      print('  الباريستا: $_printBaristaReceipts');
      print('  الكاشير: $_printCashierReceipts');
      print('  اراكيل: $_printShishaReceipts');
      print('  الاحتياطية: $_printBackupReceipts');
      
      // إنشاء خريطة ربط الأقسام يدوياً
      Map<String, String> categoryMapping = {};
      
      // ربط أقسام المطبخ
      for (String category in _kitchenCategories) {
        if (_allCategories.contains(category)) {
          categoryMapping[category] = 'kitchen';
        }
      }
      
      // ربط أقسام الباريستا
      for (String category in _baristaCategories) {
        if (_allCategories.contains(category)) {
          categoryMapping[category] = 'barista';
        }
      }
      
      // ربط أقسام الكاشير
      for (String category in _cashierCategories) {
        if (_allCategories.contains(category)) {
          categoryMapping[category] = 'cashier';
        }
      }
      
      // ربط أقسام اراكيل
      for (String category in _shishaCategories) {
        if (_allCategories.contains(category)) {
          categoryMapping[category] = 'shisha';
        }
      }
      
      // ربط أقسام الطابعة الاحتياطية
      for (String category in _backupCategories) {
        if (_allCategories.contains(category)) {
          categoryMapping[category] = 'backup';
        }
      }
      
      print('📋 خريطة الأقسام للحفظ: $categoryMapping');
      
      // حفظ جميع الإعدادات مع ربط الأقسام
      await PrinterService().updatePrinterSettings(
        kitchenIP: _kitchenPrinterIPController.text,
        baristaIP: _baristaPrinterIPController.text,
        cashierIP: _cashierPrinterIPController.text,
        shishaIP: _shishaPrinterIPController.text,
        backupIP: _backupPrinterIPController.text,
        enableKitchen: _printKitchenReceipts,
        enableBarista: _printBaristaReceipts,
        enableCashier: _printCashierReceipts,
        enableShisha: _printShishaReceipts,
        enableBackup: _printBackupReceipts,
        useNetwork: _useNetworkPrinters,
        categoryMapping: categoryMapping, // تمرير ربط الأقسام مباشرة
      );
      
      // تأخير بسيط لضمان الحفظ
      await Future.delayed(Duration(milliseconds: 300));
      
      // إعادة تحميل الإعدادات للتأكد من الحفظ
      await _reloadSettings();
      
      _showSuccessMessage('تم حفظ إعدادات الطابعات وربط الأقسام بنجاح');
      
    } catch (e) {
      print('Error saving settings: $e');
      _showErrorMessage('حدث خطأ أثناء حفظ الإعدادات: $e');
    }
  }

  // إعادة تحميل الإعدادات للتأكد من الحفظ
  Future<void> _reloadSettings() async {
    final printerService = PrinterService();
    
    // إعادة تهيئة الخدمة
    await printerService.resetAndReload();
    
    // إعادة تحميل الإعدادات في الواجهة
    await _loadSettings();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// إزالة الأقسام المحذوفة من جميع الطابعات
  void _removeDeletedCategoriesFromPrinters(List<String> currentCategories) {
    bool hasChanges = false;
    
    // تنظيف أقسام المطبخ
    _kitchenCategories.removeWhere((category) {
      final shouldRemove = !currentCategories.contains(category);
      if (shouldRemove) {
        print('🗑️ إزالة قسم محذوف من طابعة المطبخ: $category');
        hasChanges = true;
      }
      return shouldRemove;
    });
    
    // تنظيف أقسام الباريستا
    _baristaCategories.removeWhere((category) {
      final shouldRemove = !currentCategories.contains(category);
      if (shouldRemove) {
        print('🗑️ إزالة قسم محذوف من طابعة الباريستا: $category');
        hasChanges = true;
      }
      return shouldRemove;
    });
    
    // تنظيف أقسام الكاشير
    _cashierCategories.removeWhere((category) {
      final shouldRemove = !currentCategories.contains(category);
      if (shouldRemove) {
        print('🗑️ إزالة قسم محذوف من طابعة الكاشير: $category');
        hasChanges = true;
      }
      return shouldRemove;
    });
    
    // تنظيف أقسام اراكيل
    _shishaCategories.removeWhere((category) {
      final shouldRemove = !currentCategories.contains(category);
      if (shouldRemove) {
        print('🗑️ إزالة قسم محذوف من طابعة اراكيل: $category');
        hasChanges = true;
      }
      return shouldRemove;
    });
    
    // تنظيف أقسام الطابعة الاحتياطية
    _backupCategories.removeWhere((category) {
      final shouldRemove = !currentCategories.contains(category);
      if (shouldRemove) {
        print('🗑️ إزالة قسم محذوف من الطابعة الاحتياطية: $category');
        hasChanges = true;
      }
      return shouldRemove;
    });
    
    // حفظ التغييرات إذا كانت هناك أي تعديلات
    if (hasChanges) {
      print('💾 حفظ تغييرات الأقسام المحذوفة تلقائياً...');
      // حفظ التغييرات بصمت (بدون إظهار رسائل للمستخدم)
      _saveSettingsSilently();
    }
  }
  
  /// حفظ الإعدادات بصمت (بدون إظهار رسائل)
  Future<void> _saveSettingsSilently() async {
    try {
      // إنشاء خريطة ربط الأقسام
      Map<String, String> categoryMapping = {};
      
      // ربط أقسام المطبخ
      for (String category in _kitchenCategories) {
        categoryMapping[category] = 'kitchen';
      }
      
      // ربط أقسام الباريستا
      for (String category in _baristaCategories) {
        categoryMapping[category] = 'barista';
      }
      
      // ربط أقسام الكاشير
      for (String category in _cashierCategories) {
        categoryMapping[category] = 'cashier';
      }
      
      // ربط أقسام اراكيل
      for (String category in _shishaCategories) {
        categoryMapping[category] = 'shisha';
      }
      
      // ربط أقسام الطابعة الاحتياطية
      for (String category in _backupCategories) {
        categoryMapping[category] = 'backup';
      }
      
      // حفظ الإعدادات بصمت
      await PrinterService().updatePrinterSettings(
        kitchenIP: _kitchenPrinterIPController.text,
        baristaIP: _baristaPrinterIPController.text,
        cashierIP: _cashierPrinterIPController.text,
        shishaIP: _shishaPrinterIPController.text,
        backupIP: _backupPrinterIPController.text,
        enableKitchen: _printKitchenReceipts,
        enableBarista: _printBaristaReceipts,
        enableCashier: _printCashierReceipts,
        enableShisha: _printShishaReceipts,
        enableBackup: _printBackupReceipts,
        useNetwork: _useNetworkPrinters,
        categoryMapping: categoryMapping,
      );
      
      print('✅ تم حفظ تغييرات الأقسام بصمت');
      
    } catch (e) {
      print('❌ خطأ في حفظ تغييرات الأقسام: $e');
    }
  }

  /// إزالة الأقسام غير المرغوب فيها تلقائياً (مرة واحدة فقط)
  Future<void> _removeUnwantedCategories(AppState appState) async {
    print('🧹 فحص الأقسام القديمة للحذف (فقط الأقسام المحددة)...');
    // قائمة الأقسام المراد حذفها نهائياً (الأقسام القديمة المحددة فقط)
    // تم إزالة الأقسام العامة مثل "عصائر"، "حلويات" التي قد يرغب المستخدم في استخدامها
    final unwantedCategories = [
      'ببنم ققف',
    ];
    
    // التحقق من وجود أقسام قديمة للحذف فقط
    List<String> categoriesToDelete = [];
    for (String category in unwantedCategories) {
      if (appState.customCategories.containsKey(category)) {
        // التحقق من أن القسم فارغ أو يحتوي على عناصر قديمة افتراضية
        final items = appState.customCategories[category] ?? [];
        if (items.isEmpty || _isOldDefaultCategory(category, items)) {
          categoriesToDelete.add(category);
        } else {
          print('� تم الاحتفاظ بالقسم "$category" لأنه يحتوي على عناصر مخصصة');
        }
      }
    }
    
    // حذف الأقسام المؤكد أنها غير مرغوبة
    int deletedCount = 0;
    for (String category in categoriesToDelete) {
      appState.removeCategory(category);
      deletedCount++;
      print('🗑️ تم حذف القسم القديم: $category');
    }
    
    if (deletedCount > 0) {
      print('✅ تم حذف $deletedCount قسم قديم غير مرغوب');
    } else {
      print('ℹ️ لا توجد أقسام قديمة للحذف');
    }
  }
  
  /// التحقق من أن القسم يحتوي على عناصر افتراضية قديمة محددة
  bool _isOldDefaultCategory(String categoryName, List<String> items) {
    // قوائم العناصر الافتراضية القديمة المحددة (العناصر الدقيقة المراد حذفها)
    final Map<String, List<String>> oldDefaultItems = {
      'ببنم ققف': ['ببنم ققف'],
    };
    
    if (oldDefaultItems.containsKey(categoryName)) {
      final defaultItems = oldDefaultItems[categoryName]!;
      // إذا كانت جميع العناصر من القائمة الافتراضية القديمة المحددة
      return items.every((item) => defaultItems.contains(item));
    }
    
    return false; // ليس قسماً افتراضياً قديماً محدداً
  }
}
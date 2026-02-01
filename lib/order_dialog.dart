import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

import 'print_helper.dart';
import 'printer_service.dart';
import 'sound_service.dart';

class OrderDialog extends StatefulWidget {
  final List<OrderItem>? orders;
  final bool isEditMode;
  final String? tableName;

  const OrderDialog({super.key, this.orders, this.isEditMode = false, this.tableName});

  @override
  State<OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<OrderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppState _appState;

  Map<String, List<Map<String, dynamic>>> get categories {
    Map<String, List<Map<String, dynamic>>> allCategories = {};
    
    // الأقسام الافتراضية - لا توجد أقسام افتراضية
    List<String> defaultCategories = [];
    
    for (String categoryName in defaultCategories) {
      List<String> availableItems = _appState.getAvailableItemsForCategory(categoryName);
      allCategories[categoryName] = availableItems.map((itemName) => {
        'name': itemName,
        'price': _appState.getOrderPrice(itemName)
      }).toList();
    }
    
    // إضافة الأقسام المخصصة
    _appState.customCategories.forEach((categoryName, items) {
      List<String> availableItems = items.where((item) => 
        _appState.getOrderPrice(item) > 0
      ).toList();
      
      if (availableItems.isNotEmpty) {
        allCategories[categoryName] = availableItems.map((itemName) => {
          'name': itemName,
          'price': _appState.getOrderPrice(itemName)
        }).toList();
      }
    });
    
    // إزالة الأقسام الفارغة
    final Map<String, List<Map<String, dynamic>>> filteredCategories = Map.from(allCategories);
    filteredCategories.removeWhere((key, value) => value.isEmpty);
    
    return filteredCategories;
  }

  final List<OrderItem> _selectedOrders = [];
  bool _isClosing = false;

  void _safePop([dynamic result]) {
    if (_isClosing) return;
    _isClosing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  void _showNotesDialog(OrderItem order, int index) {
    final notesController = TextEditingController(text: order.notes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.note_alt_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'إضافة ملاحظة',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الطلب: ${order.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'مثال: بدون سكر، حار جداً، بدون ثلج...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _selectedOrders[index].notes = notesController.text.trim().isEmpty 
                    ? null 
                    : notesController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    _tabController = TabController(length: categories.keys.length, vsync: this);
    if (widget.orders != null) {
      _selectedOrders.addAll(widget.orders!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addOrUpdateOrder(String name, double price, int quantity) {
    int index = _selectedOrders.indexWhere((o) => o.name == name);
    if (index >= 0) {
      _selectedOrders[index].quantity = quantity;
      _selectedOrders[index].price = price;
      _selectedOrders[index].lastOrderTime = DateTime.now();
    } else {
      _selectedOrders.add(OrderItem(
        name: name,
        price: price,
        quantity: quantity,
        firstOrderTime: DateTime.now(),
        lastOrderTime: DateTime.now(),
      ));
    }
    SoundService().playClick(); // صوت إضافة عنصر
    setState(() {});
  }

  void _removeOrder(String name) {
    SoundService().playClick(); // صوت حذف عنصر
    setState(() {
      _selectedOrders.removeWhere((o) => o.name == name);
    });
  }

  // دالة الحفظ بدون طباعة
  void _saveOnly() {
    if (_selectedOrders.isEmpty) {
      SoundService().playError(); // صوت الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار عنصر واحد على الأقل')));
      return;
    }
    SoundService().playSuccess(); // صوت النجاح
    _safePop(_selectedOrders);
  }

  // دالة الحفظ مع الطباعة
  void _saveAndPrint() {
    if (_selectedOrders.isEmpty) {
      SoundService().playError(); // صوت الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار عنصر واحد على الأقل')));
      return;
    }
    SoundService().playPrint(); // صوت الطباعة
    // طباعة ذكية - توجيه كل طلب للطابعة المناسبة حسب القسم
    Map<String, String> orderCategories = {};
    for (OrderItem order in _selectedOrders) {
      // البحث عن القسم الذي ينتمي إليه العنصر
      String? category = _appState.customCategories.keys.firstWhere(
        (cat) => _appState.customCategories[cat]?.contains(order.name) == true,
        orElse: () => 'عام', // قسم افتراضي
      );
      orderCategories[order.name] = category;
    }
    
    // تحميل اللوغو من Assets
    PrinterService().loadLogoFromAssets('assets/logo.png').then((logo) {
      //print printer ips
      print("-----------------------------------------------------------");
    
      print('🖨️ توجيه الطباعة للأقسام: $orderCategories');
      PrinterService().printOrdersByCategory(
        _selectedOrders,
        orderCategories,
        tableName: widget.tableName,
        logoImage: logo,
      ).then((_) {
        _safePop(_selectedOrders);
      });
    });
  }

  // للتوافق مع الكود القديم - الآن يحفظ فقط
  void _submit() {
    _saveOnly();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final tabs = categories.keys.map((key) => Tab(text: key)).toList();

        return WillPopScope(
          onWillPop: () async => false, // منع الإغلاق بزر الرجوع
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
        width: 1000,
        height: 750,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isEditMode ? 'تعديل الطلبات' : 'إضافة طلبات',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _safePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: tabs,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
              ),
            ),
            
            // Content - Split Layout
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Left Side - Selected Orders
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F23),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shopping_cart_rounded, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'الطلبات المختارة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24),
                          Expanded(
                            child: _selectedOrders.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 48,
                                          color: Colors.white24,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'لا توجد طلبات بعد',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _selectedOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = _selectedOrders[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    order.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                if (order.notes != null && order.notes!.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 8),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.3),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      '📝',
                                                      style: TextStyle(fontSize: 10),
                                                    ),
                                                  ),
                                                IconButton(
                                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                  padding: EdgeInsets.zero,
                                                  onPressed: () => _removeOrder(order.name),
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.red,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '×${order.quantity}',
                                                    style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${(order.price * order.quantity).toInt()} د.ع',
                                                  style: const TextStyle(
                                                    color: Colors.amber,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (order.notes != null && order.notes!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.note_alt_rounded, color: Colors.orange, size: 14),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        order.notes!,
                                                        style: const TextStyle(
                                                          color: Colors.orange,
                                                          fontSize: 10,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => _showNotesDialog(order, index),
                                                      child: const Icon(Icons.edit_rounded, color: Colors.orange, size: 14),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else
                                              GestureDetector(
                                                onTap: () => _showNotesDialog(order, index),
                                                child: Container(
                                                  margin: const EdgeInsets.only(top: 6),
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.note_add_rounded, color: Colors.white38, size: 12),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        'إضافة ملاحظة',
                                                        style: TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          if (_selectedOrders.isNotEmpty) ...[
                            const Divider(color: Colors.white24),
                            Row(
                              children: [
                                const Text(
                                  'الإجمالي:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_selectedOrders.fold(0.0, (sum, order) => sum + (order.price * order.quantity)).toInt()} د.ع',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Right Side - Available Items
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: categories.keys.map((category) {
                          final items = categories[category]!;
                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final selectedOrder = _selectedOrders.firstWhere(
                                (o) => o.name == item['name'],
                                orElse: () => OrderItem(
                                  name: item['name'],
                                  price: (item['price'] as num).toDouble(),
                                  quantity: 0,
                                  firstOrderTime: DateTime.now(),
                                  lastOrderTime: DateTime.now(),
                                ),
                              );
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F23),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedOrder.quantity > 0 
                                        ? const Color(0xFF6366F1).withOpacity(0.5)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  onTap: () {}, // إضافة دالة فارغة لمنع السلوك الافتراضي
                                  title: Row(
                                    children: [
                                      // أيقونة الطابعة المخصصة
                                      Builder(
                                        builder: (context) {
                                          // البحث عن القسم والطابعة المخصصة
                                          String? category = _appState.customCategories.keys.firstWhere(
                                            (cat) => _appState.customCategories[cat]?.contains(item['name']) == true,
                                            orElse: () => '',
                                          );
                                          
                                          String? printerType = PrinterService().getPrinterForCategory(category);
                                          
                                          IconData printerIcon;
                                          Color printerColor;
                                          String printerTooltip;
                                          
                                          switch (printerType) {
                                            case 'kitchen':
                                              printerIcon = Icons.restaurant_menu;
                                              printerColor = Colors.orange;
                                              printerTooltip = 'طابعة المطبخ';
                                              break;
                                            case 'barista':
                                              printerIcon = Icons.coffee;
                                              printerColor = Colors.brown;
                                              printerTooltip = 'طابعة الباريستا';
                                              break;
                                            case 'shisha':
                                              printerIcon = Icons.smoking_rooms;
                                              printerColor = Colors.purple;
                                              printerTooltip = 'طابعة اراكيل';
                                              break;
                                            case 'backup':
                                              printerIcon = Icons.backup;
                                              printerColor = Colors.grey;
                                              printerTooltip = 'طابعة احتياطية';
                                              break;
                                            case 'cashier':
                                              printerIcon = Icons.receipt_long;
                                              printerColor = Colors.green;
                                              printerTooltip = 'طابعة الكاشير';
                                              break;
                                            default:
                                              // عنصر غير مخصص لأي طابعة
                                              printerIcon = Icons.help_outline;
                                              printerColor = Colors.grey;
                                              printerTooltip = 'غير مخصص لطابعة';
                                              break;
                                          }
                                          
                                          return Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: printerColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: printerColor.withOpacity(0.5)),
                                            ),
                                            child: Tooltip(
                                              message: printerTooltip,
                                              child: Icon(
                                                printerIcon,
                                                size: 14,
                                                color: printerColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (selectedOrder.quantity > 0)
                                        IconButton(
                                          onPressed: () => _removeOrder(item['name']),
                                          icon: const Icon(Icons.clear, color: Colors.red, size: 16),
                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          padding: EdgeInsets.zero,
                                          tooltip: 'إزالة من الطلب',
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'السعر: ${item['price']} د.ع',
                                    style: TextStyle(
                                      color: Colors.amber.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: selectedOrder.quantity > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 16),
                                                onPressed: () {
                                                  if (selectedOrder.quantity > 1) {
                                                    _addOrUpdateOrder(
                                                        item['name'],
                                                        (item['price'] as num).toDouble(),
                                                        selectedOrder.quantity - 1);
                                                  } else {
                                                    _removeOrder(item['name']);
                                                  }
                                                },
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(
                                                  '${selectedOrder.quantity}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                                onPressed: () {
                                                  _addOrUpdateOrder(
                                                      item['name'],
                                                      (item['price'] as num).toDouble(),
                                                      selectedOrder.quantity + 1);
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                                            onPressed: () {
                                              _addOrUpdateOrder(
                                                  item['name'],
                                                  (item['price'] as num).toDouble(),
                                                  1);
                                            },
                                          ),
                                        ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // زر الإلغاء
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: TextButton(
                        onPressed: () => _safePop(),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر الحفظ فقط
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveOnly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isEditMode ? Icons.edit_rounded : Icons.save_rounded, 
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isEditMode ? 'حفظ التعديل' : 'حفظ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر الحفظ والطباعة
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveAndPrint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.print_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isEditMode ? 'حفظ وطباعة' : 'حفظ وطباعة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
    );
      },
    );
  }
}
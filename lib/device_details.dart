import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'order_dialog.dart';
import 'order_details.dart';
import 'print_helper.dart';
import 'printer_service.dart';
import 'api_sync_manager.dart';

// دالة للترتيب الطبيعي للأسماء مع الأرقام
int _naturalSort(String a, String b) {
  // استخراج الرقم من اسم الجهاز
  RegExp regExp = RegExp(r'(\d+)');
  RegExpMatch? matchA = regExp.firstMatch(a);
  RegExpMatch? matchB = regExp.firstMatch(b);
  
  // إذا كان كلا الاسمين يحتويان على أرقام
  if (matchA != null && matchB != null) {
    // استخراج الجزء النصي والرقمي
    String prefixA = a.substring(0, matchA.start);
    String prefixB = b.substring(0, matchB.start);
    
    // إذا كان النص متماثلاً، قارن الأرقام
    if (prefixA == prefixB) {
      int numA = int.parse(matchA.group(0)!);
      int numB = int.parse(matchB.group(0)!);
      return numA.compareTo(numB);
    }
  }
  
  // إذا لم يكن هناك أرقام أو النص مختلف، استخدم الترتيب الأبجدي
  return a.compareTo(b);
}

class DeviceDetails extends StatefulWidget {
  final String deviceName;

  const DeviceDetails({super.key, required this.deviceName});

  @override
  State<DeviceDetails> createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends State<DeviceDetails>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load existing notes and setup listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      _notesController.text = appState.getNote(widget.deviceName);
      
      // Add listener to save notes automatically
      _notesController.addListener(() {
        appState.setNote(widget.deviceName, _notesController.text);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.timer_rounded), text: 'الوقت'),
          Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'الطلبات'),
          Tab(icon: Icon(Icons.settings_rounded), text: 'التحكم'),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // منع الإغلاق عند النقر خارج النافذة
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: [
            Icon(
              message.contains('نقل') ? Icons.swap_horiz_rounded : Icons.warning_rounded,
              color: message.contains('نقل') ? Colors.blue : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'تأكيد العملية', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            message, 
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'تأكيد',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final elapsed = appState.getElapsedTime(widget.deviceName);
        final running = appState.isRunning(widget.deviceName);
        final mode = appState.getMode(widget.deviceName);
        final price = appState.calculatePrice(widget.deviceName, elapsed, mode);

        // الحصول على جميع الأجهزة المحفوظة
        final allDevicesFromState = appState.devices.keys.toList();
        
        // دمج الأجهزة المحفوظة فقط (بدون افتراضية)
        final allDevicesSet = <String>{};
        allDevicesSet.addAll(allDevicesFromState);
        
        final allDevices = allDevicesSet.where((d) => d != widget.deviceName).toList();
        
        // ترتيب الأجهزة ترتيباً طبيعياً (الأرقام بشكل صحيح)
        allDevices.sort(_naturalSort);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              widget.deviceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  tooltip: 'تفريغ الطاولة',
                  onPressed: () async {
                    final confirm = await _showConfirmDialog(
                        'هل أنت متأكد من تفريغ بيانات الطاولة؟\nسيتم إعادة تعيين الطاولة إلى حالتها الأصلية.');
                    if (confirm == true) {
                      appState.resetDevice(widget.deviceName);
                      Navigator.pop(context);
                    }
                  },
                ),
              )
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildModernTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // تبويب الوقت - بدون تمرير
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // First Row - Time and Price (40% of space)
                              Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    // Time Display Card
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF1F1F23), Color(0xFF2A2A2E)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              color: running ? Colors.green : Colors.red,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 12),
                                            FittedBox(
                                              child: Text(
                                                _formatElapsedTime(elapsed),
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              running ? 'يعمل' : 'متوقف',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: running ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Price Display Card
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF059669), Color(0xFF047857)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF059669).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.attach_money_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 12),
                                            FittedBox(
                                              child: Text(
                                                '${price.toInt()} دينار',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              'السعر الحالي',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Second Row - Customer Count and Mode (25% of space)
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    // Customer Count
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F1F23),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.people_rounded,
                                                  color: Colors.white70,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    'عدد الأشخاص',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                // Decrease button
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      final current = appState.getCustomerCount(widget.deviceName);
                                                      if (current > 0) {
                                                        appState.setCustomerCount(widget.deviceName, current - 1);
                                                      }
                                                    },
                                                    icon: const Icon(Icons.remove, color: Colors.white, size: 14),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.3),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      appState.getCustomerCount(widget.deviceName).toString(),
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Increase button
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF059669), Color(0xFF047857)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      final current = appState.getCustomerCount(widget.deviceName);
                                                      appState.setCustomerCount(widget.deviceName, current + 1);
                                                    },
                                                    icon: const Icon(Icons.add, color: Colors.white, size: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // إخفاء زر الوضع الحالي لأجهزة الـ PC والـ Table والـ Billiard
                                    if (!widget.deviceName.toLowerCase().startsWith('pc') && !widget.deviceName.toLowerCase().startsWith('table') && !widget.deviceName.toLowerCase().startsWith('billiard')) ...[
                                      const SizedBox(width: 16),
                                      
                                      // Mode Display
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: mode == 'single'
                                                  ? [Colors.blue, Colors.blue.shade700]
                                                  : [Colors.purple, Colors.purple.shade700],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (mode == 'single' ? Colors.blue : Colors.purple)
                                                    .withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                mode == 'single' ? Icons.person_rounded : Icons.people_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'الوضع الحالي',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    FittedBox(
                                                      child: Text(
                                                        mode == 'single' ? 'وضع فردي' : 'وضع زوجي',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
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
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Third Row - Controls and Notes (35% of space)
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    // Control Buttons
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          // Play/Pause and Stop buttons
                                          Expanded(
                                            child: Row(
                                              children: [
                                                // Play/Pause button
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: running
                                                            ? [Colors.red, Colors.red.shade700]
                                                            : [Colors.green, Colors.green.shade700],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (running ? Colors.red : Colors.green)
                                                              .withOpacity(0.3),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        if (running) {
                                                          appState.stopTimer(widget.deviceName);
                                                        } else {
                                                          appState.startTimer(widget.deviceName);
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        shadowColor: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: FittedBox(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                              color: Colors.white,
                                                              size: 24,
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              running ? 'إيقاف' : 'بدء',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                
                                                // Stop button
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFFEF4444).withOpacity(0.3),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final confirm = await _showConfirmDialog(
                                                            'هل أنت متأكد من إيقاف الوقت نهائياً؟');
                                                        if (confirm == true) {
                                                          appState.resetTimerOnly(widget.deviceName);
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        shadowColor: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const FittedBox(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.stop_rounded,
                                                              color: Colors.white,
                                                              size: 24,
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              'إيقاف نهائي',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // إخفاء زر تغيير الوضع لأجهزة الـ PC والـ Table والـ Billiard
                                          if (!widget.deviceName.toLowerCase().startsWith('pc') && !widget.deviceName.toLowerCase().startsWith('table') && !widget.deviceName.toLowerCase().startsWith('billiard'))
                                            // Mode toggle button
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: mode == 'single'
                                                        ? [Colors.blue, Colors.blue.shade700]
                                                        : [Colors.purple, Colors.purple.shade700],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (mode == 'single' ? Colors.blue : Colors.purple)
                                                          .withOpacity(0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final newMode =
                                                        mode == 'single' ? 'multi' : 'single';
                                                    appState.setMode(widget.deviceName, newMode);
                                                  },
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
                                                        mode == 'single' ? Icons.person_rounded : Icons.people_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: FittedBox(
                                                          child: Text(
                                                            mode == 'single' ? 'تغيير إلى زوجي' : 'تغيير إلى فردي',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 14,
                                                            ),
                                                          ),
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
                                    const SizedBox(width: 16),
                                    
                                    // Notes section
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F1F23),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.note_rounded,
                                                  color: Colors.white70,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    'ملاحظات',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: _notesController,
                                                maxLines: null,
                                                expands: true,
                                                textAlignVertical: TextAlignVertical.top,
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                                decoration: InputDecoration(
                                                  hintText: 'أدخل الملاحظات هنا...',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white.withOpacity(0.5), 
                                                    fontSize: 12
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.zero,
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // تبويب الطلبات
                        OrdersTab(deviceName: widget.deviceName),
                        
                        // تبويب التحكم
                        ControlTab(
                          deviceName: widget.deviceName,
                          allDevices: allDevices,
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

  String _formatElapsedTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    final seconds = (duration.inSeconds % 60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class OrdersTab extends StatefulWidget {
  final String deviceName;

  const OrdersTab({super.key, required this.deviceName});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.getOrders(widget.deviceName);

    double calculateTotal() =>
        orders.fold(0, (sum, o) => sum + o.price * o.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          if (orders.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي الطلبات: ${orders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'المجموع: ${calculateTotal().toInt()} دينار',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Add Order Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: () async {
                final result = await showDialog<List<OrderItem>>(
                  context: context,
                  barrierDismissible: false, // منع الإغلاق بالنقر خارج النافذة
                  builder: (context) => OrderDialog(
                    tableName: widget.deviceName,
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  final appState = context.read<AppState>();
                  final apiSync = ApiSyncManager();
                  
                  try {
                    // Convert orders to JSON format for API
                    final orderItems = result.map((order) => {
                      'name': order.name,
                      'price': order.price,
                      'quantity': order.quantity,
                      'notes': order.notes,
                      'firstOrderTime': order.firstOrderTime.toIso8601String(),
                      'lastOrderTime': order.lastOrderTime.toIso8601String(),
                    }).toList();
                    
                    // Place order via API
                    await apiSync.placeOrderViaApi(
                      widget.deviceName,
                      orderItems,
                    );
                    
                    // Sync device orders from API to get latest list
                    await apiSync.syncDeviceOrders(appState, widget.deviceName);
                    
                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة الطلب بنجاح عبر API')),
                      );
                    }
                  } catch (e) {
                    // Fallback to local save if API fails
                    print('API failed, using local save: $e');
                    appState.addOrders(widget.deviceName, result);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة الطلب بنجاح (محلي)')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة طلب جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط على "إضافة طلب جديد" لبدء الطلب',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Order Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Order Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'الكمية: ${order.quantity} - السعر: ${order.price.toInt()} دينار',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'ملاحظة: ${order.notes}',
                                          style: TextStyle(
                                            color: Colors.orange.withOpacity(0.8),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // Price and Actions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(order.price * order.quantity).toInt()} دينار',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit Button
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              final result = await showDialog<List<OrderItem>>(
                                                context: context,
                                                barrierDismissible: false, // منع الإغلاق بالنقر خارج النافذة
                                                builder: (context) => OrderDialog(
                                                  orders: [order],
                                                  isEditMode: true,
                                                  tableName: widget.deviceName,
                                                ),
                                              );
                                              
                                              if (result != null && result.isNotEmpty) {
                                                // Update the existing order with new values
                                                final updatedOrder = result.first;
                                                order.name = updatedOrder.name;
                                                order.price = updatedOrder.price;
                                                order.quantity = updatedOrder.quantity;
                                                order.lastOrderTime = DateTime.now();
                                                order.notes = updatedOrder.notes;
                                                
                                                // Trigger UI update
                                                context.read<AppState>().notifyListeners();
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              color: Colors.blue,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 8),
                                        
                                        // Delete Button
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  backgroundColor: const Color(0xFF1F1F23),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                                  ),
                                                  title: const Row(
                                                    children: [
                                                      Icon(Icons.delete_forever, color: Colors.red, size: 24),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'حذف الطلب',
                                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    'هل أنت متأكد من حذف طلب "${order.name}"؟',
                                                    style: const TextStyle(color: Colors.white70),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(false),
                                                      child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.of(context).pop(true),
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                      child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              
                                              if (confirm == true) {
                                                appState.removeOrderByIndex(widget.deviceName, index);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('🗑️ تم حذف الطلب بنجاح'),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.delete_rounded,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ControlTab extends StatelessWidget {
  // دالة لحساب مجموع العمليات الحسابية في الملاحظة
  double _calculateNoteTotal(String note) {
    double total = 0.0;
    
    // البحث عن أنماط العمليات الحسابية مثل "1 * 2000" أو "3*4000"
    RegExp pattern = RegExp(r'(\d+)\s*\*\s*(\d+)');
    Iterable<RegExpMatch> matches = pattern.allMatches(note);
    
    for (RegExpMatch match in matches) {
      try {
        int quantity = int.parse(match.group(1) ?? '0');
        int price = int.parse(match.group(2) ?? '0');
        total += (quantity * price);
      } catch (e) {
        // في حالة خطأ في التحليل، تجاهل هذه العملية
        print('خطأ في تحليل العملية: ${match.group(0)}');
      }
    }
    
    return total;
  }

  void _printTableAccount(BuildContext context) async {
    final appState = context.read<AppState>();
    final orders = appState.getOrders(deviceName);
    final elapsed = appState.getElapsedTime(deviceName);
    final mode = appState.getMode(deviceName);
    final customerCount = appState.getCustomerCount(deviceName);
    final price = appState.calculatePrice(deviceName, elapsed, mode);
    final note = appState.getNote(deviceName);

    String elapsedStr = '';
    final hours = elapsed.inHours;
    final minutes = (elapsed.inMinutes % 60);
    final seconds = (elapsed.inSeconds % 60);
    if (hours > 0) {
      elapsedStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      elapsedStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    String modeStr = mode == 'زوجي' ? 'زوجي' : (mode == 'فردي' ? 'فردي' : mode);

    // تحديد نوع الجهاز بناءً على اسم الجهاز
    String deviceTypeName;
    String deviceInfo;
    
    if (deviceName.toUpperCase().contains('PC')) {
      deviceTypeName = 'PC';
      deviceInfo = 'عدد الأشخاص: $customerCount | الوقت: $elapsedStr';
    } else if (deviceName.toUpperCase().contains('TABLE') || deviceName.contains('طاولة')) {
      deviceTypeName = 'طاولة';
      deviceInfo = 'عدد الأشخاص: $customerCount | الوقت: $elapsedStr';
    } else if (deviceName.toUpperCase().contains('PS') || deviceName.contains('بلايستيشن')) {
      deviceTypeName = 'بلايستيشن';
      deviceInfo = 'الوضع: $modeStr | الوقت: $elapsedStr';
    } else {
      deviceTypeName = 'جهاز';
      deviceInfo = 'الوضع: $modeStr | الوقت: $elapsedStr';
    }

    // إضافة منتج خاص بنوع الجهاز يحوي التفاصيل
    final List<OrderItem> allOrders = [
      OrderItem(
        name: deviceTypeName,
        price: price,
        quantity: 1,
        firstOrderTime: DateTime.now(),
        lastOrderTime: DateTime.now(),
        notes: deviceInfo,
      ),
      ...orders
    ];
    
    // إضافة الملاحظة لجميع أنواع الأجهزة مع حساب المجموع
    if (note.isNotEmpty) {
      // تحليل الملاحظة لاستخراج العمليات الحسابية وحساب المجموع
      double noteTotal = _calculateNoteTotal(note);
      
      allOrders.add(OrderItem(
        name: 'ملاحظة',
        price: noteTotal, // استخدام مجموع العمليات في الملاحظة
        quantity: 1,
        firstOrderTime: DateTime.now(),
        lastOrderTime: DateTime.now(),
        notes: note,
      ));
    }

    // تحميل اللوغو من Assets
    final logo = await PrinterService().loadLogoFromAssets('assets/logo.png');
    
    await PrinterService().printCashierBill(
      allOrders,
      title: 'حساب الطاولة',
      tableName: deviceName,
      logoImage: logo,
    );
  }
  final String deviceName;
  final List<String> allDevices;

  const ControlTab({
    super.key,
    required this.deviceName,
    required this.allDevices,
  });

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: [
            Icon(
              message.contains('نقل') ? Icons.swap_horiz_rounded : Icons.warning_rounded,
              color: message.contains('نقل') ? Colors.blue : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'تأكيد العملية', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            message, 
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'تأكيد',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transfer Device Control
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.swap_horiz_rounded, color: Colors.white70),
                    SizedBox(width: 12),
                    Text(
                      'نقل إلى جهاز آخر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (allDevices.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showTransferDialog(context, appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'اختيار الجهاز المستهدف',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (allDevices.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'لا توجد أجهزة أخرى متاحة للنقل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // زر طباعة الحساب
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, color: Colors.white),
                label: const Text(
                  'طباعة الحساب',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _printTableAccount(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        title: const Text(
          'نقل إلى جهاز آخر',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allDevices.length,
            itemBuilder: (context, index) {
              final device = allDevices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListTile(
                  title: Text(
                    device,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    // حفظ context قبل العمليات async
                    final navigatorContext = Navigator.of(context);
                    final scaffoldContext = ScaffoldMessenger.of(context);
                    
                    // إغلاق قائمة الأجهزة أولاً
                    navigatorContext.pop();
                    
                    // عرض رسالة التأكيد
                    final confirm = await _showConfirmDialog(
                      context,
                      'هل أنت متأكد من نقل بيانات ${deviceName} إلى ${device}؟\n\nسيتم نقل جميع البيانات (الوقت، الطلبات، الملاحظات) من الجهاز الحالي إلى الجهاز المختار.'
                    );
                    
                    if (confirm == true) {
                      appState.transferDeviceData(deviceName, device);
                      
                      // العودة إلى الشاشة الرئيسية (نافذة PC)
                      navigatorContext.pop(); // إغلاق شاشة الجهاز الحالية
                      
                      // عرض رسالة نجاح النقل في الشاشة الرئيسية
                      scaffoldContext.showSnackBar(
                        SnackBar(
                          content: Text('✅ تم نقل البيانات من $deviceName إلى $device بنجاح'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}
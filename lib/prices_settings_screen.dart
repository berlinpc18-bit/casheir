import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'api_sync_manager.dart';

class PricesSettingsScreen extends StatefulWidget {
  const PricesSettingsScreen({super.key});

  @override
  State<PricesSettingsScreen> createState() => _PricesSettingsScreenState();
}

class _PricesSettingsScreenState extends State<PricesSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // متحكمات أسعار PC الفردية (سعر واحد لكل جهاز)
  final Map<String, TextEditingController> _pcControllers = {};
  
  // متحكمات أسعار PS4 الفردية (فردي/زوجي لكل جهاز)
  final Map<String, Map<String, TextEditingController>> _ps4Controllers = {};
  
  // متحكمات أسعار Table الفردية (سعر واحد لكل جهاز)
  final Map<String, TextEditingController> _tableControllers = {};
  
  // متحكمات أسعار Billiard الفردية (سعر واحد لكل جهاز)
  final Map<String, TextEditingController> _billiardControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _syncPricesFromApi().then((_) {
      _initializeAllControllers();
      _loadCurrentPrices();
    });
  }

  Future<void> _syncPricesFromApi() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final apiSync = ApiSyncManager();
      await apiSync.syncPrices(appState);
    } catch (e) {
      print('Error syncing prices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ خطأ في تحميل الأسعار من الخادم - استخدام البيانات المحلية'),
            backgroundColor: Colors.red.withOpacity(0.7),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'إعادة محاولة',
              onPressed: () {
                _syncPricesFromApi().then((_) {
                  _initializeAllControllers();
                  _loadCurrentPrices();
                });
              },
              textColor: Colors.amber,
            ),
          ),
        );
      }
    }
  }

  void _initializeAllControllers() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // تهيئة متحكمات أجهزة PC
    final pcDevices = appState.getDevicesByType('PC');
    for (String device in pcDevices) {
      _pcControllers[device] = TextEditingController();
    }
    
    // تهيئة متحكمات أجهزة PS4
    final ps4Devices = appState.getDevicesByType('PS4');
    for (String device in ps4Devices) {
      _ps4Controllers[device] = {
        'single': TextEditingController(),
        'multi': TextEditingController(),
      };
    }
    
    // تهيئة متحكمات أجهزة Table
    final tableDevices = appState.getDevicesByType('Table');
    for (String device in tableDevices) {
      _tableControllers[device] = TextEditingController();
    }
    
    // تهيئة متحكمات أجهزة Billiard
    final billiardDevices = appState.getDevicesByType('Billiard');
    for (String device in billiardDevices) {
      _billiardControllers[device] = TextEditingController();
    }
  }

  void _loadCurrentPrices() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // تحميل أسعار أجهزة PC الفردية
    _pcControllers.forEach((deviceName, controller) {
      controller.text = appState.getPcPrice(deviceName).toString();
    });
    
    // تحميل أسعار أجهزة PS4
    _ps4Controllers.forEach((deviceName, controllers) {
      controllers['single']!.text = appState.getPs4Price(deviceName, 'single').toString();
      controllers['multi']!.text = appState.getPs4Price(deviceName, 'multi').toString();
    });
    
    // تحميل أسعار الطاولات الفردية
    _tableControllers.forEach((deviceName, controller) {
      controller.text = appState.getTablePrice(deviceName).toString();
    });
    
    // تحميل أسعار البيليارد الفردية
    _billiardControllers.forEach((deviceName, controller) {
      controller.text = appState.getBilliardPrice(deviceName).toString();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    
    // تنظيف متحكمات PC
    _pcControllers.values.forEach((controller) => controller.dispose());
    
    // تنظيف متحكمات PS4
    _ps4Controllers.values.forEach((controllers) {
      controllers.values.forEach((controller) => controller.dispose());
    });
    
    // تنظيف متحكمات Table
    _tableControllers.values.forEach((controller) => controller.dispose());
    
    // تنظيف متحكمات Billiard
    _billiardControllers.values.forEach((controller) => controller.dispose());
    
    super.dispose();
  }

  void _savePrices() {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // حفظ أسعار أجهزة PC
      for (String deviceName in _pcControllers.keys) {
        final pcPrice = double.tryParse(_pcControllers[deviceName]!.text);
        if (pcPrice == null || pcPrice <= 0) {
          _showErrorDialog('يرجى إدخال سعر صحيح لجهاز $deviceName');
          return;
        }
      }
      
      // التحقق من صحة أسعار PS4
      for (String deviceName in _ps4Controllers.keys) {
        final singlePrice = double.tryParse(_ps4Controllers[deviceName]!['single']!.text);
        final multiPrice = double.tryParse(_ps4Controllers[deviceName]!['multi']!.text);
        
        if (singlePrice == null || singlePrice <= 0 || multiPrice == null || multiPrice <= 0) {
          _showErrorDialog('يرجى إدخال أسعار صحيحة لجهاز $deviceName');
          return;
        }
      }
      
      // التحقق من صحة أسعار Table
      for (String deviceName in _tableControllers.keys) {
        final tablePrice = double.tryParse(_tableControllers[deviceName]!.text);
        if (tablePrice == null || tablePrice <= 0) {
          _showErrorDialog('يرجى إدخال سعر صحيح لطاولة $deviceName');
          return;
        }
      }
      
      // التحقق من صحة أسعار Billiard
      for (String deviceName in _billiardControllers.keys) {
        final billiardPrice = double.tryParse(_billiardControllers[deviceName]!.text);
        if (billiardPrice == null || billiardPrice <= 0) {
          _showErrorDialog('يرجى إدخال سعر صحيح لطاولة بيليارد $deviceName');
          return;
        }
      }

      // حفظ أسعار PC الفردية لكل جهاز
      _pcControllers.forEach((deviceName, controller) {
        final price = double.parse(controller.text);
        appState.updatePcDevicePrice(deviceName, price);
      });
      
      // حفظ أسعار كل جهاز PS4
      _ps4Controllers.forEach((deviceName, controllers) {
        final singlePrice = double.parse(controllers['single']!.text);
        final multiPrice = double.parse(controllers['multi']!.text);
        appState.updatePs4Prices(deviceName, singlePrice, multiPrice);
      });
      
      // حفظ أسعار الطاولات الفردية لكل طاولة
      _tableControllers.forEach((deviceName, controller) {
        final price = double.parse(controller.text);
        appState.updateTablePrice(deviceName, price);
      });
      
      // حفظ أسعار البيليارد الفردية لكل طاولة
      _billiardControllers.forEach((deviceName, controller) {
        final price = double.parse(controller.text);
        appState.updateBilliardPrice(deviceName, price);
      });

      _showSuccessDialog('تم حفظ الأسعار بنجاح!\nسيتم تطبيق الأسعار الجديدة على الحسابات القادمة.');
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء حفظ الأسعار: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'خطأ', 
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black
              )
            ),
          ],
        ),
        content: Text(
          message, 
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'نجح', 
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black
              )
            ),
          ],
        ),
        content: Text(
          message, 
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54
          )
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الـ dialog
              Navigator.pop(context); // العودة إلى الشاشة السابقة
            },
            child: const Text('موافق', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontSize: 16
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey),
              suffixText: subtitle,
              suffixStyle: TextStyle(color: Colors.green.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green),
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded, 
              color: isDark ? Colors.white : Colors.black,
              size: 20
            ),
          ),
        ),
        title: Text(
          'إعدادات الأسعار',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(
              icon: Icon(Icons.computer),
              text: 'أجهزة PC',
            ),
            Tab(
              icon: Icon(Icons.videogame_asset),
              text: 'أجهزة PS4',
            ),
            Tab(
              icon: Icon(Icons.table_restaurant),
              text: 'الطاولات',
            ),
            Tab(
              icon: Icon(Icons.lens),
              text: 'بيليارد',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // وصف
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يمكنك تعديل أسعار كل جهاز بشكل منفصل. الأسعار بالدينار لكل ساعة.',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPcPricesTab(),
                _buildPs4PricesTab(),
                _buildTablePricesTab(),
                _buildBilliardPricesTab(),
              ],
            ),
          ),
          
          // أزرار الحفظ والإلغاء
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _savePrices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ الأسعار',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء تبويب أجهزة PC
  Widget _buildPcPricesTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final pcDevices = appState.getDevicesByType('PC');
        
        if (pcDevices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد أجهزة PC متاحة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: pcDevices.map<Widget>((deviceName) {
              // إنشاء متحكم جديد إذا لم يكن موجوداً
              if (!_pcControllers.containsKey(deviceName)) {
                _pcControllers[deviceName] = TextEditingController();
                _pcControllers[deviceName]!.text = appState.getPcPrice(deviceName).toString();
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildPriceField(
                  title: deviceName,
                  controller: _pcControllers[deviceName]!,
                  icon: Icons.computer,
                  subtitle: 'دينار لكل ساعة',
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
  
  // بناء تبويب أجهزة PS4
  Widget _buildPs4PricesTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final ps4Devices = appState.getDevicesByType('PS4');
        
        if (ps4Devices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد أجهزة PS4 متاحة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: ps4Devices.map<Widget>((deviceName) {
              // إنشاء متحكم جديد إذا لم يكن موجوداً
              if (!_ps4Controllers.containsKey(deviceName)) {
                _ps4Controllers[deviceName] = {
                  'single': TextEditingController(),
                  'multi': TextEditingController(),
                };
                _ps4Controllers[deviceName]!['single']!.text = 
                    appState.getPs4Price(deviceName, 'single').toString();
                _ps4Controllers[deviceName]!['multi']!.text = 
                    appState.getPs4Price(deviceName, 'multi').toString();
              }
              
              return _buildPs4DeviceCard(deviceName);
            }).toList(),
          ),
        );
      },
    );
  }
  
  // بناء تبويب الطاولات
  Widget _buildTablePricesTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final tableDevices = appState.getDevicesByType('Table');
        
        if (tableDevices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد طاولات متاحة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: tableDevices.map<Widget>((deviceName) {
              // إنشاء متحكم جديد إذا لم يكن موجوداً
              if (!_tableControllers.containsKey(deviceName)) {
                _tableControllers[deviceName] = TextEditingController();
                _tableControllers[deviceName]!.text = appState.getTablePrice(deviceName).toString();
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildPriceField(
                  title: deviceName,
                  controller: _tableControllers[deviceName]!,
                  icon: Icons.table_restaurant,
                  subtitle: 'دينار لكل ساعة',
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // بناء كارد جهاز PS4 مع الأسعار الفردي والزوجي
  Widget _buildPs4DeviceCard(String deviceName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videogame_asset_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                deviceName,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // سعر فردي
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فردي',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ps4Controllers[deviceName]!['single']!,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black, 
                        fontSize: 14
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey),
                        suffixText: 'دينار/ساعة',
                        suffixStyle: TextStyle(color: Colors.green.withOpacity(0.7), fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // سعر زوجي
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'زوجي',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ps4Controllers[deviceName]!['multi']!,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black, 
                        fontSize: 14
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey),
                        suffixText: 'دينار/ساعة',
                        suffixStyle: TextStyle(color: Colors.green.withOpacity(0.7), fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء تبويب البيليارد
  Widget _buildBilliardPricesTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final billiardDevices = appState.getDevicesByType('Billiard');
        
        if (billiardDevices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد طاولات بيليارد متاحة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: billiardDevices.map<Widget>((deviceName) {
              // إنشاء متحكم جديد إذا لم يكن موجوداً
              if (!_billiardControllers.containsKey(deviceName)) {
                _billiardControllers[deviceName] = TextEditingController();
                _billiardControllers[deviceName]!.text = appState.getBilliardPrice(deviceName).toString();
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildPriceField(
                  title: deviceName,
                  controller: _billiardControllers[deviceName]!,
                  icon: Icons.lens,
                  subtitle: 'دينار لكل ساعة',
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
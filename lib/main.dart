import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state.dart';
import 'device_grid.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'order_dialog.dart';
import 'sound_service.dart';
import 'license_manager.dart';
import 'license_activation_screen.dart';
import 'license_wrapper.dart';
import 'printer_service.dart';
import 'api_client.dart';
import 'api_sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة إدارة النوافذ
  await windowManager.ensureInitialized();
  
  // تهيئة خدمة الطابعات
  await PrinterService().ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // Server-only mode - no local data persistence needed
  // All data comes from server only
  
  await initializeDateFormatting('ar');

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      // No cleanup needed - server-only mode
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BERLIN GAMING',
          theme: appState.isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
          home: const LicenseWrapper(),
        );
      },
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: ThemeData.dark().colorScheme.copyWith(
        primary: const Color(0xFF6366F1), // Indigo modern
        secondary: const Color(0xFFEC4899), // Pink accent
        surface: const Color(0xFF1F1F23),
        background: const Color(0xFF0A0A0A),
        brightness: Brightness.dark,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1F1F23),
        elevation: 8,
        shadowColor: Colors.black54,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ThemeData.light().colorScheme.copyWith(
        primary: const Color(0xFF6366F1), // Indigo modern
        secondary: const Color(0xFFEC4899), // Pink accent
        surface: Colors.white,
        background: const Color(0xFFF8F9FA),
        brightness: Brightness.light,
        onSurface: const Color(0xFF1A1A1A),
        onBackground: const Color(0xFF1A1A1A),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
        bodyLarge: const TextStyle(color: Color(0xFF1A1A1A)),
        bodyMedium: const TextStyle(color: Color(0xFF1A1A1A)),
        titleLarge: const TextStyle(color: Color(0xFF1A1A1A)),
        titleMedium: const TextStyle(color: Color(0xFF1A1A1A)),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isFullScreen = false;
  bool _isTogglingFullScreen = false;
  bool _isSyncing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
        // 🔄 Refresh data from server when tab changes
        _syncDataFromApi();
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    // 🚀 Sync all data from API on app startup
    _syncDataFromApi();
  }

  Future<void> _syncDataFromApi() async {
    if (_isSyncing) return; // Prevent multiple simultaneous syncs
    
    setState(() => _isSyncing = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final apiSync = ApiSyncManager();
      
      // Check if server is available
      final isAvailable = await apiSync.isServerAvailable();
      if (isAvailable) {
        print('✅ API Server is available, syncing all data...');
        await apiSync.syncAll(appState);
        print('✅ Full API sync completed successfully');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('بيانات محدثة من السيرفر'),
                ],
              ),
              backgroundColor: Colors.green.withOpacity(0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('⚠️ API Server not available');
        if (mounted) {
          _showServerErrorDialog();
        }
      }
    } catch (e) {
      print('⚠️ Error syncing data from API: $e');
      if (mounted) {
        _showServerErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showServerErrorDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Colors.red,
            size: 32,
          ),
        ),
        title: const Text(
          'مشكلة في الاتصال بالخادم',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لم يتم الاتصال بخادم API',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'الخادم: http://localhost:8080',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيتم استخدام البيانات المحفوظة محليًا',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ حلول ممكنة:',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. تأكد من تشغيل خادم API على المنفذ 8080',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2. تحقق من اتصال الشبكة',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3. تأكد من عنوان الخادم الصحيح',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            label: const Text(
              'متابعة (بيانات محلية)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _syncDataFromApi(); // Retry
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة محاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFullScreen() {
    if (_isTogglingFullScreen) return;
    _isTogglingFullScreen = true;
    
    // تأخير صغير لتجنب التجمد
    Timer(const Duration(milliseconds: 50), () async {
      try {
        final newState = !_isFullScreen;
        
        // تحديث الحالة أولاً
        setState(() {
          _isFullScreen = newState;
        });
        
        // تطبيق Full Screen الحقيقي
        await windowManager.setFullScreen(newState);
        
        // رسالة تأكيد
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newState ? '🖥️ الشاشة الكاملة مُفعلة' : '🪟 النافذة العادية مُفعلة',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: newState ? Colors.green : Colors.blue,
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        
      } catch (e) {
        print('خطأ في Full Screen: $e');
        
        // استعادة الحالة في حالة الخطأ
        setState(() {
          _isFullScreen = !_isFullScreen;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ خطأ في الشاشة الكاملة: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        Timer(const Duration(milliseconds: 500), () {
          _isTogglingFullScreen = false;
        });
      }
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // دوال التنقل بين التبويبات
  void _goToPreviousTab() {
    SoundService().playClick(); // صوت النقر
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _tabController.animateTo(_currentIndex);
      });
    } else {
      // العودة للتبويب الأخير إذا كنا في الأول
      setState(() {
        _currentIndex = 4;
        _tabController.animateTo(_currentIndex);
      });
    }
  }
  
  void _goToNextTab() {
    SoundService().playClick(); // صوت النقر
    if (_currentIndex < 4) {
      setState(() {
        _currentIndex++;
        _tabController.animateTo(_currentIndex);
      });
    } else {
      // العودة للتبويب الأول إذا كنا في الأخير
      setState(() {
        _currentIndex = 0;
        _tabController.animateTo(_currentIndex);
      });
    }
  }
  
  void _goToTab(int index) {
    if (index >= 0 && index < 5) {
      SoundService().playClick(); // صوت النقر
      setState(() {
        _currentIndex = index;
        _tabController.animateTo(_currentIndex);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          // معالجة أزرار الماوس الجانبية
          // زر الماوس الخلفي (Back Button) - عادة يكون button 1
          if (event.buttons == 8) { // 8 = Back button
            _goToPreviousTab();
          }
          // زر الماوس الأمامي (Forward Button) - عادة يكون button 2
          else if (event.buttons == 16) { // 16 = Forward button
            _goToNextTab();
          }
        },
        onPointerSignal: (PointerSignalEvent event) {
          // معالجة أزرار الماوس الجانبية
          if (event is PointerScrollEvent) {
            // زر الماوس الخلفي (Back Button)
            if (event.scrollDelta.dx < -1.0) {
              _goToPreviousTab();
            }
            // زر الماوس الأمامي (Forward Button)
            else if (event.scrollDelta.dx > 1.0) {
              _goToNextTab();
            }
          }
        },
        child: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              // F11 للشاشة الكاملة - نسخة محسنة
              if (event.logicalKey == LogicalKeyboardKey.f11) {
                print('F11 detected');
                if (!_isTogglingFullScreen) {
                  _toggleFullScreen();
                }
                return;
              }
              
              // F5 لتحديث البيانات من السيرفر
              if (event.logicalKey == LogicalKeyboardKey.f5) {
                print('F5 detected - Refreshing data from server');
                _syncDataFromApi();
                return;
              }
              
              // باقي الاختصارات تعمل فقط عندما لا يوجد TextField نشط
              final FocusNode? currentFocus = FocusManager.instance.primaryFocus;
              if (currentFocus != null && currentFocus.context != null) {
                // إذا كان هناك TextField أو حقل إدخال نشط، لا تعالج الاختصارات
                final widget = currentFocus.context!.widget;
                if (widget is EditableText || 
                    widget.runtimeType.toString().contains('TextField') ||
                    widget.runtimeType.toString().contains('TextFormField')) {
                  return; // لا تعالج الاختصارات
                }
              }
              
              // اختصارات لوحة المفاتيح فقط (بدون أزرار الفأرة)
              else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                _goToPreviousTab();
              }
              else if (event.logicalKey == LogicalKeyboardKey.digit1) {
                _goToTab(0);
              }
              else if (event.logicalKey == LogicalKeyboardKey.digit2) {
                _goToTab(1);
              }
              else if (event.logicalKey == LogicalKeyboardKey.digit3) {
                _goToTab(2);
              }
              else if (event.logicalKey == LogicalKeyboardKey.digit4) {
                _goToTab(3);
              }
            }
          },
          child: GestureDetector(
              onTap: () {
                // إعادة التركيز عند النقر بدون تعقيد
                _focusNode.requestFocus();
              },
              child: Focus(
                autofocus: true,
                canRequestFocus: true,
                child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0A0A0A), // Deep black
                      const Color(0xFF1A1A2E), // Dark navy
                      const Color(0xFF16213E), // Rich blue-black
                    ]
                  : [
                      const Color(0xFFF8F9FA), // Very light gray
                      const Color(0xFFE9ECEF), // Light gray
                      const Color(0xFFDEE2E6), // Medium light gray
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Modern Header
                _buildModernHeader(),
                // Modern Tab Bar
                _buildModernTabBar(),
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _syncDataFromApi,
                    color: const Color(0xFF6366F1),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF8F9FA),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: const [
                        DeviceGrid(deviceType: DeviceType.Pc),
                        DeviceGrid(deviceType: DeviceType.Arabia),
                        DeviceGrid(deviceType: DeviceType.Table),
                        DeviceGrid(deviceType: DeviceType.Billiard),
                        DirectSaleTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Gaming Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BERLIN GAMING',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : const Color(0xFF1A1A1A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Gaming Cafe Manager',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white54 
                        : const Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 8),
                SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // زر الإعدادات
          Tooltip(
            message: 'الإعدادات',
            child: InkWell(
              onTap: _openSettings,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.green.withOpacity(0.3), 
                    Colors.teal.withOpacity(0.2)
                  ]),
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'إعدادات',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // زر الشاشة الكاملة
          Tooltip(
            message: _isFullScreen ? 'الخروج من الشاشة الكاملة (F11)' : 'الشاشة الكاملة (F11)',
            child: InkWell(
              onTap: _toggleFullScreen,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _isFullScreen 
                    ? LinearGradient(colors: [
                        Colors.orange.withOpacity(0.3), 
                        Colors.red.withOpacity(0.2)
                      ])
                    : LinearGradient(colors: [
                        Colors.blue.withOpacity(0.3), 
                        Colors.purple.withOpacity(0.2)
                      ]),
                  border: Border.all(
                    color: _isFullScreen ? Colors.orange : Colors.blue,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_isFullScreen ? Colors.orange : Colors.blue).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFullScreen 
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                      color: _isFullScreen ? Colors.orange : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isFullScreen ? 'خروج' : 'ملء الشاشة',
                      style: TextStyle(
                        color: _isFullScreen ? Colors.orange : Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F23) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.15)
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black87,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.computer_rounded, size: 18),
                SizedBox(width: 6),
                Text('PC'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videogame_asset_rounded, size: 18),
                SizedBox(width: 6),
                Text('PlayStation'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant_rounded, size: 18),
                SizedBox(width: 6),
                Text('Tables'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lens, size: 18),
                SizedBox(width: 6),
                Text('Billiard'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.point_of_sale_rounded, size: 18),
                SizedBox(width: 6),
                Text('Direct'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Reservation Models & Dialog ====================

enum ReservationStatus { pending, confirmed, inProgress, completed, cancelled }
enum DeviceCategory { pc, playstation, table }

class Reservation {
  String name;
  String phone;
  DateTime time;
  int duration; // بالدقائق
  int count;
  DeviceCategory deviceType;
  ReservationStatus status;
  double expectedPrice;
  String notes;
  String? assignedDevice; // الجهاز المخصص للحجز
  DateTime? actualStartTime;
  DateTime? actualEndTime;

  Reservation({
    required this.name,
    required this.phone,
    required this.time,
    required this.duration,
    required this.count,
    required this.deviceType,
    this.status = ReservationStatus.pending,
    this.expectedPrice = 0.0,
    this.notes = '',
    this.assignedDevice,
    this.actualStartTime,
    this.actualEndTime,
  });

  DateTime get endTime => time.add(Duration(minutes: duration));
  
  bool get isActive => status == ReservationStatus.inProgress;
  bool get isUpcoming => time.isAfter(DateTime.now()) && status == ReservationStatus.confirmed;
  bool get isOverdue => endTime.isBefore(DateTime.now()) && status != ReservationStatus.completed;

  String get statusText {
    switch (status) {
      case ReservationStatus.pending: return 'في الانتظار';
      case ReservationStatus.confirmed: return 'مؤكد';
      case ReservationStatus.inProgress: return 'جاري';
      case ReservationStatus.completed: return 'مكتمل';
      case ReservationStatus.cancelled: return 'ملغي';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReservationStatus.pending: return Colors.orange;
      case ReservationStatus.confirmed: return Colors.blue;
      case ReservationStatus.inProgress: return Colors.green;
      case ReservationStatus.completed: return Colors.grey;
      case ReservationStatus.cancelled: return Colors.red;
    }
  }

  String get deviceTypeText {
    switch (deviceType) {
      case DeviceCategory.pc: return 'PC';
      case DeviceCategory.playstation: return 'PlayStation';
      case DeviceCategory.table: return 'Table';
    }
  }

  IconData get deviceIcon {
    switch (deviceType) {
      case DeviceCategory.pc: return Icons.computer_rounded;
      case DeviceCategory.playstation: return Icons.videogame_asset_rounded;
      case DeviceCategory.table: return Icons.table_restaurant_rounded;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'time': time.toIso8601String(),
    'duration': duration,
    'count': count,
    'deviceType': deviceType.index,
    'status': status.index,
    'expectedPrice': expectedPrice,
    'notes': notes,
    'assignedDevice': assignedDevice,
    'actualStartTime': actualStartTime?.toIso8601String(),
    'actualEndTime': actualEndTime?.toIso8601String(),
  };

  static Reservation fromJson(Map<String, dynamic> json) => Reservation(
    name: json['name'],
    phone: json['phone'],
    time: DateTime.parse(json['time']),
    duration: json['duration'],
    count: json['count'],
    deviceType: DeviceCategory.values[json['deviceType'] ?? 0],
    status: ReservationStatus.values[json['status'] ?? 0],
    expectedPrice: json['expectedPrice']?.toDouble() ?? 0.0,
    notes: json['notes'] ?? '',
    assignedDevice: json['assignedDevice'],
    actualStartTime: json['actualStartTime'] != null ? DateTime.parse(json['actualStartTime']) : null,
    actualEndTime: json['actualEndTime'] != null ? DateTime.parse(json['actualEndTime']) : null,
  );
}

class ReservationDialog extends StatefulWidget {
  final Reservation? reservation;
  const ReservationDialog({super.key, this.reservation});

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _durationController;
  late TextEditingController _countController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  DateTime _selectedTime = DateTime.now();
  DeviceCategory _selectedDeviceType = DeviceCategory.pc;
  ReservationStatus _selectedStatus = ReservationStatus.pending;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reservation?.name ?? '');
    _phoneController = TextEditingController(text: widget.reservation?.phone ?? '');
    _durationController = TextEditingController(text: widget.reservation?.duration.toString() ?? '60');
    _countController = TextEditingController(text: widget.reservation?.count.toString() ?? '1');
    _priceController = TextEditingController(text: widget.reservation?.expectedPrice.toString() ?? '0');
    _notesController = TextEditingController(text: widget.reservation?.notes ?? '');
    _selectedTime = widget.reservation?.time ?? DateTime.now();
    _selectedDeviceType = widget.reservation?.deviceType ?? DeviceCategory.pc;
    _selectedStatus = widget.reservation?.status ?? ReservationStatus.pending;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _durationController.dispose();
    _countController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTime),
      );
      if (time != null) {
        setState(() {
          _selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final reservation = Reservation(
      name: _nameController.text,
      phone: _phoneController.text,
      time: _selectedTime,
      duration: int.parse(_durationController.text),
      count: int.parse(_countController.text),
      deviceType: _selectedDeviceType,
      status: _selectedStatus,
      expectedPrice: double.tryParse(_priceController.text) ?? 0.0,
      notes: _notesController.text,
    );

    Navigator.pop(context, reservation);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minWidth: 400,
            minHeight: 500,
          ),
          width: MediaQuery.of(context).size.width > 800 
              ? MediaQuery.of(context).size.width * 0.7
              : MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height > 600
              ? MediaQuery.of(context).size.height * 0.8
              : MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E3440), Color(0xFF3B4252)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF5E81AC), Color(0xFF81A1C1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.reservation == null ? 'إضافة حجز جديد' : 'تعديل الحجز',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
              
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Info Section
                        _buildSectionTitle('معلومات الزبون', Icons.person),
                        const SizedBox(height: 16),
                        _buildTextField(_nameController, 'اسم الزبون', Icons.person_outline, 'الرجاء إدخال الاسم'),
                        const SizedBox(height: 16),
                        _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone, 'الرجاء إدخال رقم الهاتف', TextInputType.phone),
                        
                        const SizedBox(height: 24),
                        
                        // Booking Details Section
                        _buildSectionTitle('تفاصيل الحجز', Icons.event_note),
                        const SizedBox(height: 16),
                        
                        // Device Type Selector
                        const Text('نوع الجهاز', style: TextStyle(color: Color(0xFFD8DEE9), fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4C566A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: DeviceCategory.values.map((type) {
                              final isSelected = _selectedDeviceType == type;
                              return Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedDeviceType = type),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF88C0D0) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          type == DeviceCategory.pc ? Icons.computer_rounded :
                                          type == DeviceCategory.playstation ? Icons.videogame_asset_rounded : Icons.table_restaurant_rounded,
                                          color: isSelected ? const Color(0xFF2E3440) : const Color(0xFFD8DEE9),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          type == DeviceCategory.pc ? 'PC' :
                                          type == DeviceCategory.playstation ? 'PlayStation' : 'Table',
                                          style: TextStyle(
                                            color: isSelected ? const Color(0xFF2E3440) : const Color(0xFFD8DEE9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_countController, 'عدد الأشخاص', Icons.people, 'الرجاء إدخال العدد', TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField(_durationController, 'المدة (دقيقة)', Icons.timer, 'الرجاء إدخال المدة', TextInputType.number)),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        _buildTextField(_priceController, 'السعر المتوقع (دينار)', Icons.attach_money, null, TextInputType.number),
                        
                        const SizedBox(height: 16),
                        
                        // Date Time Picker
                        const Text('وقت الحجز', style: TextStyle(color: Color(0xFFD8DEE9), fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4C566A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF5E81AC).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, color: Color(0xFF88C0D0)),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('yyyy/MM/dd - HH:mm').format(_selectedTime),
                                  style: const TextStyle(color: Color(0xFFECEFF4), fontSize: 16),
                                ),
                                const Spacer(),
                                const Icon(Icons.edit, color: Color(0xFF88C0D0), size: 20),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Status Selector (if editing)
                        if (widget.reservation != null) ...[
                          const Text('حالة الحجز', style: TextStyle(color: Color(0xFFD8DEE9), fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ReservationStatus>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF4C566A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            dropdownColor: const Color(0xFF4C566A),
                            style: const TextStyle(color: Color(0xFFECEFF4)),
                            items: ReservationStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: status == ReservationStatus.pending ? Colors.orange :
                                               status == ReservationStatus.confirmed ? Colors.blue :
                                               status == ReservationStatus.inProgress ? Colors.green :
                                               status == ReservationStatus.completed ? Colors.grey : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(status == ReservationStatus.pending ? 'في الانتظار' :
                                         status == ReservationStatus.confirmed ? 'مؤكد' :
                                         status == ReservationStatus.inProgress ? 'جاري' :
                                         status == ReservationStatus.completed ? 'مكتمل' : 'ملغي'),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedStatus = value!),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Notes
                        _buildTextField(_notesController, 'ملاحظات إضافية', Icons.note, null, TextInputType.multiline, 3),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF4C566A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: Color(0xFFD8DEE9), fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88C0D0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('حفظ الحجز', style: TextStyle(color: Color(0xFF2E3440), fontSize: 16, fontWeight: FontWeight.bold)),
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
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF88C0D0), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFECEFF4),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String? validator, [TextInputType? keyboardType, int maxLines = 1]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFECEFF4)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFD8DEE9)),
        prefixIcon: Icon(icon, color: const Color(0xFF88C0D0)),
        filled: true,
        fillColor: const Color(0xFF4C566A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF88C0D0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator != null ? (v) => v!.isEmpty ? validator : null : null,
    );
  }
}

// ==================== Reservation Tab ====================

class ReservationTab extends StatefulWidget {
  const ReservationTab({super.key});

  @override
  State<ReservationTab> createState() => _ReservationTabState();
}

class _ReservationTabState extends State<ReservationTab> with TickerProviderStateMixin {
  List<Reservation> reservations = [];
  bool _isListView = true;
  late TabController _viewModeController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _viewModeController = TabController(length: 2, vsync: this);
    _loadReservations();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _viewModeController.dispose();
    super.dispose();
  }

  void _startNotificationTimer() {
    // Check for upcoming reservations every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkUpcomingReservations();
    });
  }

  void _checkUpcomingReservations() {
    final now = DateTime.now();
    for (final reservation in reservations) {
      final timeUntil = reservation.time.difference(now).inMinutes;
      
      // Notify 15 minutes before
      if (timeUntil == 15 && reservation.status == ReservationStatus.confirmed) {
        _showNotification('تذكير حجز', 'حجز ${reservation.name} سيبدأ خلال 15 دقيقة');
      }
      
      // Check if reservation is overdue
      if (reservation.isOverdue && reservation.status == ReservationStatus.inProgress) {
        _showNotification('انتهاء وقت الحجز', 'انتهى وقت حجز ${reservation.name}');
      }
    }
  }

  void _showNotification(String title, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(message, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF5E81AC),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _loadReservations() async {
    // Server-only mode: reservations load from API on demand
    print('Loading reservations from server...');
  }

  Future<void> _saveReservations() async {
    // Server-only mode: no local persistence needed
    print('Reservations managed by server only');
  }

  void _addReservation() async {
    final newRes = await showDialog<Reservation>(
      context: context,
      builder: (context) => const ReservationDialog(),
    );
    if (newRes != null) {
      setState(() {
        reservations.add(newRes);
        reservations.sort((a, b) => a.time.compareTo(b.time));
      });
      await _saveReservations();
      
      // حفظ في AppState أيضاً
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addReservation('System', ReservationItem(
        name: newRes.name,
        price: 0,
        quantity: 1,
        reservationTime: newRes.time,
      ));
      
      _showNotification('حجز جديد', 'تم إضافة حجز ${newRes.name} بنجاح');
    }
  }

  void _editReservation(int index) async {
    final editedRes = await showDialog<Reservation>(
      context: context,
      builder: (context) => ReservationDialog(reservation: reservations[index]),
    );
    if (editedRes != null) {
      setState(() {
        reservations[index] = editedRes;
        reservations.sort((a, b) => a.time.compareTo(b.time));
      });
      await _saveReservations();
      
      // تحديث في AppState أيضاً
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addReservation('System', ReservationItem(
        name: editedRes.name,
        price: 0,
        quantity: 1,
        reservationTime: editedRes.time,
      ));
      
      _showNotification('تم التحديث', 'تم تحديث حجز ${editedRes.name}');
    }
  }

  void _deleteReservation(int index) {
    final reservation = reservations[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E3440),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف حجز "${reservation.name}"؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                reservations.removeAt(index);
              });
              await _saveReservations();
              
              // حذف من AppState أيضاً
              final appState = Provider.of<AppState>(context, listen: false);
              appState.addReservation('System', ReservationItem(
                name: reservation.name,
                price: 0,
                quantity: 1,
                reservationTime: reservation.time,
              ));
              
              Navigator.pop(ctx);
              
              _showNotification('تم الحذف', 'تم حذف حجز ${reservation.name}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  List<Reservation> get _filteredReservations {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return reservations.where((r) => 
          r.time.year == now.year && 
          r.time.month == now.month && 
          r.time.day == now.day
        ).toList();
      case 'upcoming':
        return reservations.where((r) => r.isUpcoming).toList();
      case 'active':
        return reservations.where((r) => r.isActive).toList();
      case 'overdue':
        return reservations.where((r) => r.isOverdue).toList();
      default:
        return reservations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header with stats and filters
              Flexible(
                flex: 0,
                child: _buildHeader(),
              ),
              // Filter tabs
              Flexible(
                flex: 0,
                child: _buildFilterTabs(),
              ),
              // تم حذف مربع خيارات العرض (قائمة)
              // خط فاصل حديث
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 0),
                child: Center(
                  child: Container(
                    width: 1500,
                    height: 3.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // زر حجز جديد مع مسافة للأسفل
              Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 8), // تقريباً 1 سم
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              _addReservation();
                              setState(() {
                                _isListView = true;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text('حجز جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                flex: 1,
                child: _filteredReservations.isEmpty
                    ? _buildEmptyState()
                    : _buildListView(),
              ),
            ],
          ),
        ),

      ),
    );
  }

  Widget _buildHeader() {
    final todayCount = reservations.where((r) {
      final now = DateTime.now();
      return r.time.year == now.year && r.time.month == now.month && r.time.day == now.day;
    }).length;
    
    final upcomingCount = reservations.where((r) => r.isUpcoming).length;
    final activeCount = reservations.where((r) => r.isActive).length;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(
        maxWidth: 800, // اجعل العرض أقصر (يمكنك التعديل حسب رغبتك)
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.event_note_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'إدارة الحجوزات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('اليوم', todayCount.toString(), Icons.today, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard('قادمة', upcomingCount.toString(), Icons.schedule, Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard('جارية', activeCount.toString(), Icons.play_circle, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(height: 1),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = {
      'all': 'الكل',
      'today': 'اليوم',
      'upcoming': 'قادمة',
      'active': 'جارية',
      'overdue': 'متأخرة',
    };
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.entries.map((entry) {
          final isSelected = _selectedFilter == entry.key;
          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: isSelected
                  ? ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      entry.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.white70,
                      ),
                    ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = entry.key;
                });
              },
              backgroundColor: const Color(0xFF3B4252),
              selectedColor: Colors.white.withOpacity(0.13),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B4252),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      constraints: const BoxConstraints(
        maxWidth: 370,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListView ? const Color(0xFF88C0D0) : Colors.transparent,
              foregroundColor: _isListView ? const Color(0xFF2E3440) : Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _isListView = true;
              });
            },
            icon: const Icon(Icons.list_rounded, size: 20),
            label: const Text('قائمة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حجوزات',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على "حجز جديد" لإضافة أول حجز',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredReservations.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final reservation = _filteredReservations[index];
        return _buildModernReservationCard(reservation, index);
      },
    );
  }
  
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Widget _buildModernReservationCard(Reservation reservation, int index) {
    // تصميم كرت الحجز مثل كرت الأجهزة الأخرى
    return InkWell(
      onTap: () => _editReservation(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/re.png'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: reservation.statusColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // محتوى الكرت
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                // شريط سفلي للأيقونة والاسم
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              reservation.deviceIcon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            reservation.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // رقم الحجز
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // وميض كلمة BUSY إذا كان الحجز نشطًا
                if (reservation.isActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 2),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.3, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      onEnd: () {
                        // إعادة تشغيل الوميض
                        if (reservation.isActive) setState(() {});
                      },
                      child: const Text(
                        'BUSY',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // زر حذف دائري
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _deleteReservation(index),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, int index) {
    final timeUntil = reservation.time.difference(DateTime.now());
    final isToday = reservation.time.day == DateTime.now().day;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B4252),
            const Color(0xFF434C5E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reservation.statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editReservation(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Device Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: reservation.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      reservation.deviceIcon,
                      color: reservation.statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Customer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reservation.phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reservation.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reservation.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details Row
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(reservation.time),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'اليوم',
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.people, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.count} أشخاص',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.duration} دقيقة',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (reservation.expectedPrice > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${reservation.expectedPrice.toInt()} دينار',
                      style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              
              if (reservation.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'ملاحظة: ${reservation.notes}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (timeUntil.inMinutes > 0 && timeUntil.inHours < 24) ...[
                    Text(
                      'خلال ${timeUntil.inHours > 0 ? "${timeUntil.inHours}س " : ""}${timeUntil.inMinutes % 60}د',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Edit Button
                  InkWell(
                    onTap: () => _editReservation(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit, color: Colors.blue, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Delete Button
                  InkWell(
                    onTap: () => _deleteReservation(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    // Simple calendar placeholder - في التطبيق الحقيقي يمكن استخدام مكتبة calendar
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'عرض التقويم',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إضافة عرض التقويم قريباً',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Direct Sale Tab ====================
class DirectSaleTab extends StatefulWidget {
  const DirectSaleTab({super.key});

  @override
  State<DirectSaleTab> createState() => _DirectSaleTabState();
}

class _DirectSaleTabState extends State<DirectSaleTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'البيع المباشر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'إضافة طلبات البيع المباشر',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Content
              Expanded(
                child: Row(
                  children: [
                    // Direct Sale Button
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF059669),
                          Color(0xFF047857),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showDirectSaleDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_shopping_cart_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Direct Sale',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'بيع مباشر',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                    ),
                    const SizedBox(width: 20),
                    // Orders List
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'طلبات البيع المباشر',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildDirectSaleOrdersList(appState),
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
        );
      },
    );
  }

  void _showDirectSaleDialog(BuildContext context) {
    SoundService().playClick(); // صوت فتح النافذة
    
    showDialog<List<OrderItem>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderDialog(
        tableName: 'البيع المباشر',
      ),
    ).then((orders) {
      if (orders != null && orders.isNotEmpty) {
        // حفظ الطلبات في نظام إدارة الحالة
        final appState = context.read<AppState>();
        appState.addOrders('البيع المباشر', orders);
        
        // تشغيل صوت النجاح
        SoundService().playCashRegister();
        
        // عرض رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة ${orders.length} عنصر للبيع المباشر'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Widget _buildDirectSaleOrdersList(AppState appState) {
    final directSaleDevice = appState.devices['البيع المباشر'];
    
    if (directSaleDevice == null || directSaleDevice.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات بيع مباشر حتى الآن',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: directSaleDevice.orders.length,
      itemBuilder: (context, index) {
        final order = directSaleDevice.orders[index];
        final totalPrice = order.price * order.quantity;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الكمية: ${order.quantity} × ${order.price.toStringAsFixed(0)} = ${totalPrice.toStringAsFixed(0)} د.ع',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  appState.removeOrder('البيع المباشر', order);
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.withOpacity(0.8),
                ),
                tooltip: 'حذف الطلب',
              ),
            ],
          ),
        );
      },
    );
  }
}
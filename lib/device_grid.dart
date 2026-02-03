import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'device_details.dart';
import 'receipt_preview_screen.dart';

enum DeviceType { Pc, Arabia, Table, Billiard }

// خلفية حديثة مستوحاة من تطبيقات الهاتف المحمول العصرية
class ModernBackground extends StatelessWidget {
  const ModernBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0A0A), // Deep black
                  const Color(0xFF1A1A2E), // Dark navy
                  const Color(0xFF16213E), // Rich blue-black
                  const Color(0xFF0A0A0A), // Back to deep black
                ]
              : [
                  const Color(0xFFF8F9FA), // Very light gray
                  const Color(0xFFE9ECEF), // Light gray
                  const Color(0xFFDEE2E6), // Medium light gray
                  const Color(0xFFF8F9FA), // Back to very light gray
                ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle geometric patterns
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(isDark ? 0.1 : 0.05),
                    Colors.transparent,
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(isDark ? 0.08 : 0.04),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final bool isDark;
  
  GridPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark 
          ? Colors.white.withOpacity(0.02) 
          : Colors.black.withOpacity(0.02)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// الخلفية المتحركة - جزيئات
class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});

  @override
  _ParticlesBackgroundState createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  final int numberOfParticles = 80;

  @override
  void initState() {
    super.initState();
    particles = List.generate(numberOfParticles, (index) => Particle());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      for (var p in particles) {
        p.reset(size);
      }
    });
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var p in particles) {
          p.update(size);
        }
        return SizedBox.expand(
          child: CustomPaint(
            painter: ParticlePainter(particles),
          ),
        );
      },
    );
  }
}

class Particle {
  late Offset position;
  late double size;
  late double speed;
  late double direction; // بالرانديان
  final Random random = Random();

  Particle() {
    reset();
  }

  void reset([Size? canvasSize]) {
    position = canvasSize == null
        ? Offset(random.nextDouble() * 400, random.nextDouble() * 800)
        : Offset(random.nextDouble() * canvasSize.width,
            random.nextDouble() * canvasSize.height);
    size = random.nextDouble() * 3 + 1;
    speed = random.nextDouble() * 0.5 + 0.1;
    direction = random.nextDouble() * 2 * pi;
  }

  void update(Size canvasSize) {
    final dx = speed * cos(direction);
    final dy = speed * sin(direction);
    position = Offset(position.dx + dx, position.dy + dy);

    if (position.dx > canvasSize.width ||
        position.dx < 0 ||
        position.dy > canvasSize.height ||
        position.dy < 0) {
      reset(canvasSize);
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueAccent.withOpacity(0.15);
    for (final particle in particles) {
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- DeviceGrid widget مع الخلفية الجديدة وثابتة ---

class DeviceGrid extends StatefulWidget {
  final DeviceType deviceType;

  const DeviceGrid({super.key, required this.deviceType});

  @override
  State<DeviceGrid> createState() => _DeviceGridState();
}

class _DeviceGridState extends State<DeviceGrid> with TickerProviderStateMixin {
  late AnimationController _busyController;
  late Animation<double> _busyAnimation;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _busyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _busyAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _busyController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _busyController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التفريغ'),
        content: const Text('هل أنت متأكد أنك تريد تفريغ جميع الطاولات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final appState = context.read<AppState>();
      List<String> devicesToClear = [];

      switch (widget.deviceType) {
        case DeviceType.Pc:
          devicesToClear = appState.getDevicesByType('PC');
          break;
        case DeviceType.Arabia:
          devicesToClear = appState.getDevicesByType('PS4');
          break;
        case DeviceType.Table:
          devicesToClear = appState.getDevicesByType('Table');
          break;
        case DeviceType.Billiard:
          devicesToClear = appState.getDevicesByType('Billiard');
          break;
      }

      for (var device in devicesToClear) {
        appState.clearDevice(device);
      }
    }
  }

  Widget _getIconForDeviceType(DeviceType type, Color iconColor) {
    Icon icon;
    switch (type) {
      case DeviceType.Pc:
        icon = const Icon(Icons.computer, size: 24);
        break;
      case DeviceType.Arabia:
        icon = const Icon(Icons.videogame_asset, size: 24);
        break;
      case DeviceType.Table:
        icon = const Icon(Icons.table_bar, size: 24);
        break;
      case DeviceType.Billiard:
        icon = const Icon(Icons.lens, size: 24);
        break;
    }
    return Icon(
      icon.icon,
      size: icon.size,
      color: iconColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> devices = [];
    String categoryTitle = '';

    final appState = Provider.of<AppState>(context);
    
    switch (widget.deviceType) {
      case DeviceType.Pc:
        devices = appState.getDevicesByType('PC');
        categoryTitle = 'Gaming PCs';
        break;
      case DeviceType.Arabia:
        devices = appState.getDevicesByType('PS4');
        categoryTitle = 'PlayStation Arena';
        break;
      case DeviceType.Table:
        devices = appState.getDevicesByType('Table');
        categoryTitle = 'Gaming Tables';
        break;
      case DeviceType.Billiard:
        devices = appState.getDevicesByType('Billiard');
        categoryTitle = 'Billiard Tables';
        break;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
        child: Column(
          children: [
            // Modern Category Header
            _buildCategoryHeader(categoryTitle),
            // Devices Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: devices.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(context),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: _getChildAspectRatio(context),
                ),
                itemBuilder: (context, index) {
                  final deviceName = devices[index];
                  return _buildModernDeviceCard(context, deviceName, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1.5; // Wider cards for single column
    if (width < 600) return 0.85; // Taller cards for mobile 2 columns
    return 1.1; // Default for desktop
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1600) return 8;
    if (width > 1200) return 6;
    if (width > 900) return 4;
    if (width > 600) return 3;
    if (width > 400) return 2;
    return 1; // For very small phones
  }

  Widget _buildCategoryHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: _getGradientForDeviceType(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getGradientForDeviceType().colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getIconDataForDeviceType(),
              color: Colors.white,
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
                        : const Color(0xFF1A1A1A),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Select a device to manage',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white54 
                        : const Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _getGradientForDeviceType(),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getGradientForDeviceType().colors.first.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.13),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.devices,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    final activeCount = _getActiveDevicesCount(appState);
                    return Text(
                      '$activeCount Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDeviceCard(BuildContext context, String deviceName, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isRunning = appState.isRunning(deviceName);
        final hasOrders = appState.getOrders(deviceName).isNotEmpty;
        final hasNotes = appState.getNote(deviceName).trim().isNotEmpty;
        final isBusy = isRunning || hasOrders || hasNotes;
        final elapsed = appState.getElapsedTime(deviceName);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1, end: 1),
          duration: const Duration(milliseconds: 200),
          builder: (context, scale, child) {
            return Listener(
              onPointerDown: (_) => (context as Element).markNeedsBuild(),
              child: GestureDetector(
                onTapDown: (_) => (context as Element).markNeedsBuild(),
                onTapUp: (_) => (context as Element).markNeedsBuild(),
                onTapCancel: () => (context as Element).markNeedsBuild(),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FadeTransition(
                            opacity: animation,
                            child: DeviceDetails(deviceName: deviceName),
                          ),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
                child: AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      // إذا كان القسم PC أو PlayStation أو Table أو Billiard ضع صورة الخلفية
                      image: widget.deviceType == DeviceType.Pc
                          ? const DecorationImage(
                              image: AssetImage('assets/pc.png'),
                              fit: BoxFit.cover,
                            )
                          : widget.deviceType == DeviceType.Arabia
                              ? const DecorationImage(
                                  image: AssetImage('assets/arabia.png'),
                                  fit: BoxFit.cover,
                                )
                              : widget.deviceType == DeviceType.Table
                                  ? const DecorationImage(
                                      image: AssetImage('assets/table.png'),
                                      fit: BoxFit.cover,
                                    )
                                  : widget.deviceType == DeviceType.Billiard
                                      ? const DecorationImage(
                                          image: AssetImage('assets/billiard.png'),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                      gradient: (widget.deviceType == DeviceType.Pc || widget.deviceType == DeviceType.Arabia || widget.deviceType == DeviceType.Table || widget.deviceType == DeviceType.Billiard)
                          ? null
                          : (isBusy
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1F1F23),
                                          const Color(0xFF2A2A2E),
                                        ]
                                      : [
                                          Colors.white,
                                          const Color(0xFFF8F8FA),
                                        ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1F1F23),
                                          const Color(0xFF1A1A1D),
                                        ]
                                      : [
                                          Colors.white,
                                          const Color(0xFFF5F5F7),
                                        ],
                                )),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isBusy
                            ? const Color(0xFFEC4899).withOpacity(0.5)
                            : isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.18),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.deviceType == DeviceType.Pc
                              ? Colors.purpleAccent.withOpacity(0.25)
                              : widget.deviceType == DeviceType.Arabia
                                  ? Colors.blueAccent.withOpacity(0.22)
                                  : widget.deviceType == DeviceType.Table
                                      ? Colors.greenAccent.withOpacity(0.22)
                                      : widget.deviceType == DeviceType.Billiard
                                          ? Colors.greenAccent.withOpacity(0.22)
                                          : (isBusy
                                          ? const Color(0xFFEC4899).withOpacity(0.35)
                                          : isDark
                                              ? Colors.black.withOpacity(0.22)
                                              : Colors.black.withOpacity(0.13)),
                          blurRadius: (widget.deviceType == DeviceType.Pc || widget.deviceType == DeviceType.Arabia || widget.deviceType == DeviceType.Table || widget.deviceType == DeviceType.Billiard) ? 32 : (isBusy ? 22 : 14),
                          spreadRadius: (widget.deviceType == DeviceType.Pc || widget.deviceType == DeviceType.Arabia || widget.deviceType == DeviceType.Table || widget.deviceType == DeviceType.Billiard) ? 4 : (isBusy ? 2 : 0),
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
            child: (widget.deviceType == DeviceType.Pc || widget.deviceType == DeviceType.Arabia || widget.deviceType == DeviceType.Table || widget.deviceType == DeviceType.Billiard)
              ? Stack(
                              children: [
                                // محتوى الكارت (فارغ ليظهر فقط الخلفية)
                                Positioned.fill(child: Container()),
                                
                                // Preview Button (Top Right) - Only show if has orders
                                if (hasOrders)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReceiptPreviewScreen(
                                                deviceName: deviceName,
                                                appState: appState,
                                              ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.receipt_long,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                () {
                                                  final deviceOrders = appState.getOrders(deviceName);
                                                  final total = deviceOrders.fold(0.0, (sum, o) => sum + (o.price * o.quantity));
                                                  final rounded = ((total / 250).round().toDouble() * 250);
                                                  return rounded.toStringAsFixed(0);
                                                }(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // الأيقونة والرقم في الأسفل مع تغويش
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(28),
                                      bottomRight: Radius.circular(28),
                                    ),
                                    child: Container(
                                      color: isBusy
                                          ? Colors.red.withOpacity(0.18)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // الأيقونة مع كلمة BUSY إذا كان مشغول
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                  gradient: _getGradientForDeviceType(),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _getIconDataForDeviceType(),
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                              if (isBusy) ...[
                                                const SizedBox(width: 6),
                                                AnimatedBuilder(
                                                  animation: _busyAnimation,
                                                  builder: (context, child) {
                                                    final color = Color.lerp(Colors.transparent, Colors.red, _busyAnimation.value)!;
                                                    return Text(
                                                      'BUSY',
                                                      style: TextStyle(
                                                        color: color,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                          // رقم الطاولة
                                          Text(
                                            '${index + 1}'.padLeft(2, '0'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Status indicator and device number
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isBusy
                                          ? const Color(0xFFEC4899).withOpacity(0.22)
                                          : const Color(0xFF22C55E).withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isBusy ? 'BUSY' : 'FREE',
                                      style: TextStyle(
                                        color: isBusy
                                            ? const Color(0xFFEC4899)
                                            : const Color(0xFF22C55E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${index + 1}'.padLeft(2, '0'),
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : const Color(0xFF666666),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Device icon and type
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: _getGradientForDeviceType(),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getGradientForDeviceType().colors.first.withOpacity(0.38),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getIconDataForDeviceType(),
                                      color: Colors.white,
                                      size: 28,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    deviceName,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              // Time and status
                              if (isRunning)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.13)
                                        : Colors.black.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatDuration(elapsed),
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF666666),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                Container(height: 18), // Placeholder for alignment
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  LinearGradient _getGradientForDeviceType() {
    switch (widget.deviceType) {
      case DeviceType.Pc:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        );
      case DeviceType.Arabia:
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
        );
      case DeviceType.Table:
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
        );
      case DeviceType.Billiard:
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0891B2)],
        );
    }
  }

  IconData _getIconDataForDeviceType() {
    switch (widget.deviceType) {
      case DeviceType.Pc:
        return Icons.computer_rounded;
      case DeviceType.Arabia:
        return Icons.videogame_asset_rounded;
      case DeviceType.Table:
        return Icons.table_restaurant_rounded;
      case DeviceType.Billiard:
        return Icons.lens;
    }
  }

  int _getActiveDevicesCount(AppState appState) {
    List<String> devices = [];
    switch (widget.deviceType) {
      case DeviceType.Pc:
        devices = appState.getDevicesByType('PC');
        break;
      case DeviceType.Arabia:
        devices = appState.getDevicesByType('PS4');
        break;
      case DeviceType.Table:
        devices = appState.getDevicesByType('Table');
        break;
      case DeviceType.Billiard:
        devices = appState.getDevicesByType('Billiard');
        break;
    }
    
    // عد الأجهزة النشطة (الأجهزة المحذوفة محذوفة تلقائياً من getDevicesByType)
    return devices.where((device) => 
      appState.isRunning(device) || 
      appState.getOrders(device).isNotEmpty || 
      appState.getNote(device).trim().isNotEmpty ||
      appState.getReservations(device).isNotEmpty
    ).length;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

enum DeviceType { PC, PS4, Table, Billiard }

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  DeviceType _selectedType = DeviceType.PS4;
  final TextEditingController _deviceNameController = TextEditingController();
  String? _editingDevice;

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  String _getTypePrefix(DeviceType type) {
    switch (type) {
      case DeviceType.PC:
        return 'Pc ';
      case DeviceType.PS4:
        return 'Arabia ';
      case DeviceType.Table:
        return 'Table ';
      case DeviceType.Billiard:
        return 'Billiard ';
    }
  }

  String _getNextDeviceName(DeviceType type, AppState appState) {
    final prefix = _getTypePrefix(type);
    final existingDevices = appState.getDevicesByType(type.name);
    
    // استخراج الأرقام الموجودة
    final existingNumbers = <int>[];
    for (String deviceName in existingDevices) {
      final numberPart = deviceName.replaceAll(prefix, '');
      final number = int.tryParse(numberPart);
      if (number != null) {
        existingNumbers.add(number);
      }
    }
    
    // العثور على أصغر رقم متاح
    int nextNumber = 1;
    while (existingNumbers.contains(nextNumber)) {
      nextNumber++;
    }
    
    return '$prefix$nextNumber';
  }

  String _getTypeDisplayName(DeviceType type) {
    switch (type) {
      case DeviceType.PC:
        return 'كمبيوتر';
      case DeviceType.PS4:
        return 'PlayStation 4';
      case DeviceType.Table:
        return 'طاولة';
      case DeviceType.Billiard:
        return 'بيليارد';
    }
  }

  IconData _getTypeIcon(DeviceType type) {
    switch (type) {
      case DeviceType.PC:
        return Icons.computer;
      case DeviceType.PS4:
        return Icons.videogame_asset_rounded;
      case DeviceType.Table:
        return Icons.table_restaurant_rounded;
      case DeviceType.Billiard:
        return Icons.lens;
    }
  }

  Color _getTypeColor(DeviceType type) {
    switch (type) {
      case DeviceType.PC:
        return Colors.blue;
      case DeviceType.PS4:
        return Colors.purple;
      case DeviceType.Table:
        return Colors.orange;
      case DeviceType.Billiard:
        return Colors.green;
    }
  }

  Future<void> _addDevice() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // إنشاء اسم الجهاز تلقائياً مع رقم متسلسل
    final fullDeviceName = _getNextDeviceName(_selectedType, appState);
    
    try {
      await appState.addDevice(fullDeviceName, _selectedType.name);
      if (mounted) {
        // تأخير صغير للتأكد من تحديث الحالة
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {});
        _deviceNameController.clear();
        _showSuccessDialog('تم إضافة الجهاز بنجاح: $fullDeviceName');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _editDevice(String deviceName) {
    setState(() {
      _editingDevice = deviceName;
      // استخراج الجزء بعد البادئة
      final parts = deviceName.split(' ');
      if (parts.length > 1) {
        _deviceNameController.text = parts.sublist(1).join(' ');
      }
    });
  }

  Future<void> _saveEdit() async {
    if (_editingDevice == null) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    final newName = _deviceNameController.text.trim();
    
    if (newName.isEmpty) {
      _showErrorDialog('يرجى إدخال اسم الجهاز');
      return;
    }

    // تحديد نوع الجهاز من الاسم الحالي
    DeviceType currentType = DeviceType.PS4;
    if (_editingDevice!.startsWith('Pc')) {
      currentType = DeviceType.PC;
    } else if (_editingDevice!.startsWith('Table')) {
      currentType = DeviceType.Table;
    } else if (_editingDevice!.startsWith('Billiard')) {
      currentType = DeviceType.Billiard;
    }
    
    final newFullName = _getTypePrefix(currentType) + newName;
    
    try {
      await appState.renameDevice(_editingDevice!, newFullName);
      setState(() {
        _editingDevice = null;
        _deviceNameController.clear();
      });
      _showSuccessDialog('تم تعديل اسم الجهاز بنجاح');
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingDevice = null;
      _deviceNameController.clear();
    });
  }

  void _deleteDevice(String deviceName) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (!appState.canDeleteDevice(deviceName)) {
      _showErrorDialog('لا يمكن حذف الجهاز. تأكد من إيقاف الجهاز وإنهاء جميع الطلبات والحجوزات');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف الجهاز "$deviceName"؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await appState.removeDevice(deviceName);
                if (mounted) {
                  // تأخير صغير للتأكد من تحديث الحالة
                  await Future.delayed(const Duration(milliseconds: 100));
                  setState(() {});
                  _showSuccessDialog('تم حذف الجهاز بنجاح');
                }
              } catch (e) {
                if (mounted) {
                  _showErrorDialog(e.toString());
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54
          ),
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
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: DeviceType.values.map((type) {
          final isSelected = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? _getTypeColor(type)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      size: 18,
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTypeDisplayName(type),
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : (isDark ? Colors.white70 : Colors.black54),
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddDeviceForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getTypeIcon(_selectedType), 
                   color: _getTypeColor(_selectedType), size: 20),
              const SizedBox(width: 8),
              Text(
                _editingDevice != null ? 'تعديل الجهاز' : 'إضافة جهاز جديد',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_editingDevice == null) ...[
            Text(
              'نوع الجهاز',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildDeviceTypeSelector(),
            const SizedBox(height: 16),
          ],
          
          if (_editingDevice == null) ...[
            Text(
              'الجهاز التالي سيكون:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final nextDeviceName = _getNextDeviceName(_selectedType, appState);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedType == DeviceType.PC
                            ? Icons.computer
                            : _selectedType == DeviceType.PS4
                                ? Icons.sports_esports
                                : Icons.table_bar,
                        color: _selectedType == DeviceType.PC
                            ? Colors.blue
                            : _selectedType == DeviceType.PS4
                                ? Colors.green
                                : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nextDeviceName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Text(
              'تعديل اسم الجهاز',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    _getTypePrefix(_editingDevice!.startsWith('Pc') ? DeviceType.PC 
                         : _editingDevice!.startsWith('Table') ? DeviceType.Table 
                         : DeviceType.PS4),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _deviceNameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم الجهاز',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        borderSide: BorderSide(color: _getTypeColor(DeviceType.PS4)),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          
          Row(
            children: [
              if (_editingDevice != null) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(_selectedType),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('حفظ التعديل'),
                  ),
                ),
              ] else
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(_selectedType),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('إضافة الجهاز'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        // التحقق من وجود أجهزة
        final totalDevices = appState.getDevicesByType('PC').length + 
                            appState.getDevicesByType('PS4').length + 
                            appState.getDevicesByType('Table').length +
                            appState.getDevicesByType('Billiard').length;
        
        if (totalDevices == 0) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.devices_other_rounded,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد أجهزة',
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قم بإضافة أول جهاز لك',
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // تجميع الأجهزة حسب النوع باستخدام دالة الترتيب الصحيح
        final devicesByType = <String, List<String>>{
          'PC': appState.getDevicesByType('PC'),
          'PS4': appState.getDevicesByType('PS4'),
          'Table': appState.getDevicesByType('Table'),
          'Billiard': appState.getDevicesByType('Billiard'),
        };
        
        return ListView(
          children: [
            ...devicesByType.entries.map((entry) {
              if (entry.value.isEmpty) return const SizedBox.shrink();
              
              DeviceType type = entry.key == 'PC' ? DeviceType.PC 
                  : entry.key == 'PS4' ? DeviceType.PS4 
                  : entry.key == 'Table' ? DeviceType.Table : DeviceType.Billiard;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(type), 
                             color: _getTypeColor(type), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${_getTypeDisplayName(type)} (${entry.value.length})',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((deviceName) => _buildDeviceCard(deviceName, appState)),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDeviceCard(String deviceName, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final device = appState.devices[deviceName];
    final canDelete = appState.canDeleteDevice(deviceName);
    
    DeviceType type = deviceName.startsWith('Pc') ? DeviceType.PC 
        : deviceName.startsWith('Arabia') ? DeviceType.PS4 
        : deviceName.startsWith('Table') ? DeviceType.Table : DeviceType.Billiard;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(type),
              color: _getTypeColor(type),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      device?.isRunning == true ? Icons.play_circle : Icons.pause_circle,
                      color: device?.isRunning == true ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device?.isRunning == true ? 'يعمل' : 'متوقف',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    if (device?.orders.isNotEmpty == true) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.shopping_cart, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${device!.orders.length} طلبات',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editDevice(deviceName),
                icon: const Icon(Icons.edit_rounded),
                color: Colors.blue,
                tooltip: 'تعديل',
              ),
              IconButton(
                onPressed: canDelete ? () => _deleteDevice(deviceName) : null,
                icon: const Icon(Icons.delete_rounded),
                color: canDelete ? Colors.red : Colors.grey,
                tooltip: canDelete ? 'حذف' : 'لا يمكن الحذف (الجهاز يعمل أو يحتوي على طلبات)',
              ),
            ],
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
              size: 20,
            ),
          ),
        ),
        title: Text(
          'إدارة الأجهزة',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // نموذج إضافة/تعديل الأجهزة
            _buildAddDeviceForm(),
            
            const SizedBox(height: 24),
            
            // قائمة الأجهزة  
            Expanded(
              child: _buildDevicesList(),
            ),
          ],
        ),
      ),
    );
  }
}

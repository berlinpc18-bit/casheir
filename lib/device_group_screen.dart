import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'device_group_manager.dart';
import 'sync_service.dart';

/// شاشة إدارة مجموعة الأجهزة
class DeviceGroupScreen extends StatefulWidget {
  const DeviceGroupScreen({Key? key}) : super(key: key);

  @override
  State<DeviceGroupScreen> createState() => _DeviceGroupScreenState();
}

class _DeviceGroupScreenState extends State<DeviceGroupScreen> {
  late DeviceGroupManager _groupManager;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _groupManager = DeviceGroupManager();
    _initializeGroup();
  }

  Future<void> _initializeGroup() async {
    await _groupManager.initialize('gaming-group-001');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _groupManager,
      child: Consumer<DeviceGroupManager>(
        builder: (context, groupManager, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('إدارة مجموعة الأجهزة'),
              backgroundColor: Colors.deepPurple,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSyncSettings,
                ),
                IconButton(
                  icon: Icon(
                    _showLogs ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() => _showLogs = !_showLogs);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // قسم معلومات المجموعة
                  _buildGroupInfo(),
                  
                  // قسم الأجهزة المتصلة
                  _buildConnectedDevices(),
                  
                  // قسم حالة المزامنة
                  _buildSyncStatus(),
                  
                  // قسم السجلات
                  if (_showLogs) _buildSyncLogs(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// بناء قسم معلومات المجموعة
  Widget _buildGroupInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات المجموعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('معرف المجموعة', _groupManager.groupId ?? 'غير محدد'),
            _buildInfoRow('عدد الأجهزة', '${_groupManager.deviceGroups.length}'),
            _buildInfoRow(
              'حالة المزامنة',
              _groupManager.autoSync ? 'مفعلة ✓' : 'معطلة ✗',
            ),
            _buildInfoRow(
              'فترة المزامنة',
              '${_groupManager.syncInterval} ثانية',
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قسم الأجهزة المتصلة
  Widget _buildConnectedDevices() {
    final devices = _groupManager.deviceGroups.values.toList();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأجهزة المتصلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (devices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('لا توجد أجهزة متصلة'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return _buildDeviceCard(device);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة الجهاز
  Widget _buildDeviceCard(DeviceGroupData device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: device.isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.devices,
                color: device.isOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      device.deviceId.substring(0, 12),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  device.isOnline ? 'متصل' : 'منقطع',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: device.isOnline ? Colors.green : Colors.red,
              ),
            ],
          ),
          if (device.lastUpdate != null) ...[
            const SizedBox(height: 8),
            Text(
              'آخر تحديث: ${device.lastUpdate!.hour}:${device.lastUpdate!.minute}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء قسم حالة المزامنة
  Widget _buildSyncStatus() {
    final state = _groupManager.getGroupState();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حالة المزامنة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(state['syncStatus'] as List).map((status) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(status['deviceName'] ?? 'جهاز'),
                    Chip(
                      label: Text(
                        status['isActive'] ? 'نشط' : 'غير نشط',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: status['isActive'] ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// بناء قسم السجلات
  Widget _buildSyncLogs() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل المزامنة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final logs = _groupManager.exportSyncLogs();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تصدير السجلات'),
                        content: SingleChildScrollView(
                          child: Text(logs),
                        ),
                        actions: [
                          TextButton(
                            onPressed: Navigator.of(context).pop,
                            child: const Text('إغلاق'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('تصدير'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _groupManager.syncLogs.length,
                itemBuilder: (context, index) {
                  final log = _groupManager.syncLogs[_groupManager.syncLogs.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second} - ${log.action}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء صف المعلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// إظهار إعدادات المزامنة
  void _showSyncSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات المزامنة'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('المزامنة التلقائية'),
                  value: _groupManager.autoSync,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _groupManager.enableAutoSync();
                      } else {
                        _groupManager.disableAutoSync();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('فترة المزامنة:'),
                    Expanded(
                      child: Slider(
                        value: _groupManager.syncInterval.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '${_groupManager.syncInterval} ثانية',
                        onChanged: _groupManager.autoSync
                            ? (value) {
                                setState(() {
                                  _groupManager.setSyncInterval(value.toInt());
                                });
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _groupManager.stop();
    super.dispose();
  }
}

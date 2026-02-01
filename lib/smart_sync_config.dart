/// ملف إعدادات نظام التحكم المشترك الذكي
/// تضمن جميع ثوابت الإعدادات والمعاملات

class SmartSyncConfig {
  // إعدادات الشبكة المحلية
  static const String broadcastAddress = '255.255.255.255';
  static const int discoveryPort = 5555;
  static const int syncPort = 5556;
  static const String discoveryProtocol = 'udp';
  
  // إعدادات المزامنة الافتراضية
  static const bool defaultAutoSyncEnabled = true;
  static const int defaultSyncIntervalSeconds = 5;
  static const int minSyncIntervalSeconds = 1;
  static const int maxSyncIntervalSeconds = 30;
  
  // إعدادات اكتشاف الأجهزة
  static const int discoveryBroadcastIntervalSeconds = 10;
  static const int deviceHealthCheckSeconds = 60;
  static const int deviceTimeoutSeconds = 90;
  
  // إعدادات السجلات
  static const int maxSyncLogsCount = 100;
  static const bool enableDetailedLogging = true;
  
  // إعدادات الأداء
  static const int maxConcurrentSyncRequests = 10;
  static const int maxDevicesPerGroup = 50;
  static const int udpMessageTimeoutMs = 5000;
  
  // إعدادات الأمان
  static const bool validatePayloadSignature = false;
  static const bool encryptPayloads = false;
  static const int payloadMaxSizeBytes = 65536; // 64 KB
  
  // رسائل الأخطاء
  static const Map<String, String> errorMessages = {
    'network_init_failed': 'فشل تهيئة خدمة الشبكة المحلية',
    'sync_service_init_failed': 'فشل تهيئة خدمة المزامنة',
    'device_not_found': 'الجهاز المستهدف غير مكتشف',
    'sync_timeout': 'انتهت مهلة المزامنة',
    'payload_invalid': 'بيانات غير صالحة',
    'network_error': 'خطأ في الشبكة',
    'port_unavailable': 'المنفذ غير متاح',
    'broadcast_failed': 'فشل البث',
  };
  
  // الألوان والتنسيقات
  static const String syncStatusOnline = 'متصل';
  static const String syncStatusOffline = 'منقطع';
  static const String syncStatusSyncing = 'جاري المزامنة';
  
  // رموز الحالة
  static const int statusCodeSuccess = 200;
  static const int statusCodeError = 500;
  static const int statusCodeTimeout = 408;
  static const int statusCodeNotFound = 404;
  
  /// الحصول على إعداد مخصص
  static String getSyncStatusLabel(bool isOnline) {
    return isOnline ? syncStatusOnline : syncStatusOffline;
  }
  
  /// التحقق من صحة فترة المزامنة
  static int validateSyncInterval(int seconds) {
    if (seconds < minSyncIntervalSeconds) return minSyncIntervalSeconds;
    if (seconds > maxSyncIntervalSeconds) return maxSyncIntervalSeconds;
    return seconds;
  }
  
  /// الحصول على رسالة خطأ
  static String getErrorMessage(String errorCode) {
    return errorMessages[errorCode] ?? 'خطأ غير معروف';
  }
  
  /// إعدادات التطوير
  static const bool debugMode = true;
  static const bool simulateNetworkDelay = false;
  static const int simulatedDelayMs = 100;
  
  /// حدود الذاكرة والموارد
  static const int maxLogFileSizeMB = 10;
  static const int maxCacheEntriesPerDevice = 1000;
}

/// نموذج معايرة الأداء
class PerformanceBenchmark {
  final String testName;
  final Duration duration;
  final int itemsProcessed;
  final DateTime timestamp;

  PerformanceBenchmark({
    required this.testName,
    required this.duration,
    required this.itemsProcessed,
    required this.timestamp,
  });

  double get itemsPerSecond => itemsProcessed / duration.inSeconds;

  @override
  String toString() {
    return '$testName: ${itemsPerSecond.toStringAsFixed(2)} items/sec (${duration.inMilliseconds}ms)';
  }
}

/// إعدادات المجموعة المتقدمة
class GroupAdvancedSettings {
  bool enableP2PSync = false;
  bool enableDataCompression = false;
  bool enableBandwidthLimiting = false;
  int bandwidthLimitKbps = 1024;
  bool enableFailover = true;
  int failoverTimeoutSeconds = 10;
  bool enableDataValidation = true;
  bool enableAutoRepair = true;
  
  Map<String, dynamic> toJson() => {
    'enableP2PSync': enableP2PSync,
    'enableDataCompression': enableDataCompression,
    'enableBandwidthLimiting': enableBandwidthLimiting,
    'bandwidthLimitKbps': bandwidthLimitKbps,
    'enableFailover': enableFailover,
    'failoverTimeoutSeconds': failoverTimeoutSeconds,
    'enableDataValidation': enableDataValidation,
    'enableAutoRepair': enableAutoRepair,
  };

  factory GroupAdvancedSettings.fromJson(Map<String, dynamic> json) {
    return GroupAdvancedSettings()
      ..enableP2PSync = json['enableP2PSync'] ?? false
      ..enableDataCompression = json['enableDataCompression'] ?? false
      ..enableBandwidthLimiting = json['enableBandwidthLimiting'] ?? false
      ..bandwidthLimitKbps = json['bandwidthLimitKbps'] ?? 1024
      ..enableFailover = json['enableFailover'] ?? true
      ..failoverTimeoutSeconds = json['failoverTimeoutSeconds'] ?? 10
      ..enableDataValidation = json['enableDataValidation'] ?? true
      ..enableAutoRepair = json['enableAutoRepair'] ?? true;
  }
}

/// مراقب الأداء والموارد
class ResourceMonitor {
  int _messageSendCount = 0;
  int _messageReceiveCount = 0;
  int _syncRequestCount = 0;
  int _errorCount = 0;
  final List<PerformanceBenchmark> benchmarks = [];

  void recordMessageSent() => _messageSendCount++;
  void recordMessageReceived() => _messageReceiveCount++;
  void recordSyncRequest() => _syncRequestCount++;
  void recordError() => _errorCount++;

  void recordBenchmark(PerformanceBenchmark benchmark) {
    benchmarks.add(benchmark);
  }

  Map<String, dynamic> getStats() => {
    'messageSendCount': _messageSendCount,
    'messageReceiveCount': _messageReceiveCount,
    'syncRequestCount': _syncRequestCount,
    'errorCount': _errorCount,
    'averageResponseTime': _calculateAverageResponseTime(),
    'benchmarks': benchmarks.map((b) => b.toString()).toList(),
  };

  double _calculateAverageResponseTime() {
    if (benchmarks.isEmpty) return 0;
    final totalMs = benchmarks.fold<int>(0, (sum, b) => sum + b.duration.inMilliseconds);
    return totalMs / benchmarks.length;
  }

  void reset() {
    _messageSendCount = 0;
    _messageReceiveCount = 0;
    _syncRequestCount = 0;
    _errorCount = 0;
    benchmarks.clear();
  }
}

/// نموذج معلومات الجلسة
class SessionInfo {
  final String sessionId;
  final String groupId;
  final String deviceId;
  final DateTime startTime;
  DateTime? endTime;
  int totalSyncCount = 0;
  int successfulSyncCount = 0;
  int failedSyncCount = 0;
  Duration totalSyncTime = Duration.zero;

  SessionInfo({
    required this.sessionId,
    required this.groupId,
    required this.deviceId,
    required this.startTime,
  });

  bool get isActive => endTime == null;

  Duration get uptime => endTime != null 
    ? endTime!.difference(startTime)
    : DateTime.now().difference(startTime);

  double get successRate => totalSyncCount > 0 
    ? successfulSyncCount / totalSyncCount 
    : 0;

  void recordSync(bool success, Duration syncTime) {
    totalSyncCount++;
    if (success) {
      successfulSyncCount++;
    } else {
      failedSyncCount++;
    }
    totalSyncTime = totalSyncTime + syncTime;
  }

  void endSession() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'groupId': groupId,
    'deviceId': deviceId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'totalSyncCount': totalSyncCount,
    'successfulSyncCount': successfulSyncCount,
    'failedSyncCount': failedSyncCount,
    'successRate': successRate,
    'uptime': uptime.inSeconds,
  };
}

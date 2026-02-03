
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 1000;

  List<LogEntry> get logs => List.unmodifiable(_logs.reversed);

  void log(String message, {String? tag, LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      message: message,
      timestamp: DateTime.now(),
      tag: tag ?? 'General',
      level: level,
    );
    
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    // Also print to console for debug builds
    debugPrint('[${entry.tag}] ${entry.message}');
  }

  void info(String message, [String? tag]) => log(message, tag: tag, level: LogLevel.info);
  void error(String message, [String? tag]) => log(message, tag: tag, level: LogLevel.error);
  void warning(String message, [String? tag]) => log(message, tag: tag, level: LogLevel.warning);
  
  void clear() {
    _logs.clear();
  }
}

enum LogLevel { info, warning, error }

class LogEntry {
  final String message;
  final DateTime timestamp;
  final String tag;
  final LogLevel level;

  LogEntry({
    required this.message,
    required this.timestamp,
    required this.tag,
    required this.level,
  });
}

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = AppLogger().logs;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النظام (Logs)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              AppLogger().clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('لا توجد سجلات'))
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  leading: _buildLevelIcon(log.level),
                  title: Text(log.message, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${DateFormat('HH:mm:ss').format(log.timestamp)} • ${log.tag}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  dense: true,
                  tileColor: _getBackgroundColor(log.level),
                );
              },
            ),
    );
  }

  Widget _buildLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Icon(Icons.error_outline, color: Colors.red, size: 20);
      case LogLevel.warning:
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20);
      case LogLevel.info:
      default:
        return const Icon(Icons.info_outline, color: Colors.blue, size: 20);
    }
  }

  Color? _getBackgroundColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red.withOpacity(0.05);
      case LogLevel.warning:
        return Colors.orange.withOpacity(0.05);
      default:
        return null;
    }
  }
}

// نظام حماية متقدم ضد القرصنة
// إضافة طبقات أمان متعددة

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedSecurityManager {
  static final AdvancedSecurityManager _instance = AdvancedSecurityManager._internal();
  factory AdvancedSecurityManager() => _instance;
  AdvancedSecurityManager._internal();

  // مفاتيح متعددة للحماية المتقدمة
  static const String _masterKey = 'BERLIN_GAMING_2025_ULTRA_SECURE';
  static const String _deviceFingerprintKey = 'device_fingerprint_v2';
  
  // الحصول على بصمة جهاز فريدة ومتقدمة
  Future<String> getAdvancedDeviceFingerprint() async {
    try {
      List<String> deviceComponents = [];
      
      if (Platform.isWindows) {
        // 1. معرف اللوحة الأم
        final motherboard = await Process.run('wmic', ['baseboard', 'get', 'serialnumber']);
        deviceComponents.add(motherboard.stdout.toString().replaceAll('SerialNumber', '').trim());
        
        // 2. معرف المعالج
        final cpu = await Process.run('wmic', ['cpu', 'get', 'processorid']);
        deviceComponents.add(cpu.stdout.toString().replaceAll('ProcessorId', '').trim());
        
        // 3. معرف القرص الصلب
        final disk = await Process.run('wmic', ['diskdrive', 'get', 'serialnumber']);
        deviceComponents.add(disk.stdout.toString().replaceAll('SerialNumber', '').trim());
        
        // 4. معرف BIOS
        final bios = await Process.run('wmic', ['bios', 'get', 'serialnumber']);
        deviceComponents.add(bios.stdout.toString().replaceAll('SerialNumber', '').trim());
        
        // 5. معرف كرت الشاشة
        final gpu = await Process.run('wmic', ['path', 'win32_VideoController', 'get', 'pnpdeviceid']);
        deviceComponents.add(gpu.stdout.toString().replaceAll('PNPDeviceID', '').trim());
        
        // 6. معرف الشبكة
        final network = await Process.run('wmic', ['path', 'win32_networkadapter', 'get', 'macaddress']);
        deviceComponents.add(network.stdout.toString().replaceAll('MACAddress', '').trim());
        
        // 7. معرف النظام
        final system = await Process.run('wmic', ['csproduct', 'get', 'uuid']);
        deviceComponents.add(system.stdout.toString().replaceAll('UUID', '').trim());
      }
      
      // إزالة المكونات الفارغة
      deviceComponents = deviceComponents.where((component) => 
        component.isNotEmpty && component != 'null' && component.length > 3
      ).toList();
      
      if (deviceComponents.isEmpty) {
        throw Exception('لا يمكن الحصول على معرف الجهاز');
      }
      
      // دمج جميع المكونات
      final combinedFingerprint = deviceComponents.join('|');
      
      // تشفير متعدد الطبقات
      final stage1 = sha256.convert(utf8.encode(combinedFingerprint)).toString();
      final stage2 = sha256.convert(utf8.encode(stage1 + _masterKey)).toString();
      final stage3 = sha256.convert(utf8.encode(stage2 + DateTime.now().year.toString())).toString();
      
      return stage3.substring(0, 40).toUpperCase();
      
    } catch (e) {
      // في حالة الفشل، استخدم معرف احتياطي قوي
      final fallback = 'SECURE_FALLBACK_${Platform.operatingSystem}_${Random().nextInt(999999)}';
      final hash = sha256.convert(utf8.encode(fallback + _masterKey)).toString();
      return hash.substring(0, 40).toUpperCase();
    }
  }
  
  // فحص التلاعب في النظام
  Future<bool> detectTampering() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFingerprint = prefs.getString(_deviceFingerprintKey);
      final currentFingerprint = await getAdvancedDeviceFingerprint();
      
      if (savedFingerprint == null) {
        // أول تشغيل - احفظ البصمة
        await prefs.setString(_deviceFingerprintKey, currentFingerprint);
        return false;
      }
      
      // فحص التطابق
      return savedFingerprint != currentFingerprint;
    } catch (e) {
      return true; // في حالة الشك، اعتبر أن هناك تلاعب
    }
  }
  
  // فحص البيئة الافتراضية
  Future<bool> detectVirtualMachine() async {
    try {
      if (Platform.isWindows) {
        // فحص علامات الأجهزة الافتراضية
        final systemInfo = await Process.run('systeminfo', []);
        final output = systemInfo.stdout.toString().toLowerCase();
        
        final vmSigns = [
          'vmware', 'virtualbox', 'virtual machine', 'hyperv',
          'qemu', 'kvm', 'xen', 'parallels', 'vbox'
        ];
        
        for (String sign in vmSigns) {
          if (output.contains(sign)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // فحص عمليات التصحيح
  Future<bool> detectDebugger() async {
    try {
      // فحص العمليات المشبوهة
      if (Platform.isWindows) {
        final processes = await Process.run('tasklist', ['/fo', 'csv']);
        final output = processes.stdout.toString().toLowerCase();
        
        final debuggerTools = [
          'ollydbg', 'x32dbg', 'x64dbg', 'ida', 'ghidra',
          'cheatengine', 'processhacker', 'wireshark'
        ];
        
        for (String tool in debuggerTools) {
          if (output.contains(tool)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // فحص شامل للأمان
  Future<SecurityCheckResult> performSecurityCheck() async {
    final tampering = await detectTampering();
    final virtualMachine = await detectVirtualMachine();
    final debugger = await detectDebugger();
    
    return SecurityCheckResult(
      isTampered: tampering,
      isVirtualMachine: virtualMachine,
      hasDebugger: debugger,
      isSecure: !tampering && !virtualMachine && !debugger,
    );
  }
  
  // توليد ترخيص مقاوم للقرصنة
  Future<String> generateSecureLicense(String customerName, int validDays) async {
    final deviceFingerprint = await getAdvancedDeviceFingerprint();
    final securityCheck = await performSecurityCheck();
    
    if (!securityCheck.isSecure) {
      throw SecurityException('البيئة غير آمنة للتفعيل');
    }
    
    final licenseData = {
      'device': deviceFingerprint,
      'customer': customerName,
      'activated': DateTime.now().millisecondsSinceEpoch,
      'expires': DateTime.now().add(Duration(days: validDays)).millisecondsSinceEpoch,
      'version': '2.0.0', // نسخة محسنة
      'security': {
        'vm_check': !securityCheck.isVirtualMachine,
        'debug_check': !securityCheck.hasDebugger,
        'tamper_check': !securityCheck.isTampered,
      }
    };
    
    final licenseJson = jsonEncode(licenseData);
    
    // تشفير متعدد المراحل
    final stage1Hash = sha256.convert(utf8.encode(licenseJson + _masterKey)).toString();
    final stage2Hash = sha256.convert(utf8.encode(stage1Hash + deviceFingerprint)).toString();
    final finalHash = stage2Hash.substring(0, 24);
    
    return base64.encode(utf8.encode(licenseJson)) + '.' + finalHash;
  }
}

// نتيجة فحص الأمان
class SecurityCheckResult {
  final bool isTampered;
  final bool isVirtualMachine; 
  final bool hasDebugger;
  final bool isSecure;
  
  SecurityCheckResult({
    required this.isTampered,
    required this.isVirtualMachine,
    required this.hasDebugger,
    required this.isSecure,
  });
}

// استثناء الأمان
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
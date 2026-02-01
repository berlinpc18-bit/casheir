import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal() {
    _loadSoundSettings();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  // أصوات مختلفة للأحداث المختلفة
  static const String _clickSound = 'sounds/click.mp3';
  static const String _successSound = 'sounds/success.mp3';
  static const String _errorSound = 'sounds/error.mp3';
  static const String _notificationSound = 'sounds/notification.mp3';
  static const String _cashRegisterSound = 'sounds/cash_register.mp3';
  static const String _printSound = 'sounds/print.mp3';

  // تشغيل/إيقاف الأصوات
  bool get soundEnabled => _soundEnabled;
  
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _saveSoundSettings();
  }

  // تحميل إعدادات الصوت
  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    } catch (e) {
      _soundEnabled = true;
    }
  }

  // حفظ إعدادات الصوت
  Future<void> _saveSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', _soundEnabled);
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  // تشغيل الأصوات المختلفة
  Future<void> playClick() async {
    if (_soundEnabled) {
      await _playAssetSound(_clickSound);
    }
  }

  Future<void> playSuccess() async {
    if (_soundEnabled) {
      await _playAssetSound(_successSound);
    }
  }

  Future<void> playError() async {
    if (_soundEnabled) {
      await _playAssetSound(_errorSound);
    }
  }

  Future<void> playNotification() async {
    if (_soundEnabled) {
      await _playAssetSound(_notificationSound);
    }
  }

  Future<void> playCashRegister() async {
    if (_soundEnabled) {
      await _playAssetSound(_cashRegisterSound);
    }
  }

  Future<void> playPrint() async {
    if (_soundEnabled) {
      await _playAssetSound(_printSound);
    }
  }

  // تشغيل الأصوات من ملفات Assets
  Future<void> _playAssetSound(String soundPath) async {
    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // في حالة فشل تشغيل الملف الصوتي، استخدم صوت النظام كبديل
      _playSystemSound();
    }
  }

  // صوت افتراضي من النظام كبديل
  void _playSystemSound() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  // تنظيف الموارد
  void dispose() {
    _audioPlayer.dispose();
  }
}
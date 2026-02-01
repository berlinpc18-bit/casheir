import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _usernameKey = 'logged_in_username';
  static const String _loginTimeKey = 'login_time';

  static final Map<String, String> _users = {
    'zoro': '1q2w3e1998',
    'dvksig': '472963',
    'fkbskg': '299638',
    'fjbldi': '559238',
    'mkgjdi': '399549',
    'qpricm': '179674',
    'gkkbis': '399647',
    'fkksor': '992754',
    'vnnsjg': '448296',
    'fkkbos': '449204',
    'azsxdo': '558829',
    'vbfkur': '599137',
    'sxddke': '668290',
    'lleogj': '722156',
    'bhhdks': '339577',
    'vmmskg': '883992',
  };

  // تسجيل الدخول وحفظ الحالة
  Future<void> login(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // تسجيل الخروج
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_usernameKey);
    await prefs.remove(_loginTimeKey);
  }

  // فحص حالة تسجيل الدخول
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // الحصول على اسم المستخدم المسجل حالياً
  Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // الحصول على وقت تسجيل الدخول
  Future<DateTime?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);
    if (loginTime != null) {
      return DateTime.fromMillisecondsSinceEpoch(loginTime);
    }
    return null;
  }

  // فحص صحة بيانات الدخول
  static bool validateUser(String username, String password) {
    if (!_users.containsKey(username)) return false;
    return _users[username] == password;
  }
}

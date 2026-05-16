import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStore extends ChangeNotifier {
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'role';
  static const _nameKey = 'staff_name';
  static const _adminIdKey = 'admin_id';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String? token;
  String? role;
  String? staffName;
  String? adminId;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> load() async {
    token = await _secure.read(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString(_roleKey);
    staffName = prefs.getString(_nameKey);
    adminId = prefs.getString(_adminIdKey);
  }

  Future<void> save({required String token, required String role, String? staffName, String? adminId}) async {
    this.token = token;
    this.role = role;
    this.staffName = staffName;
    this.adminId = adminId;
    await _secure.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    await prefs.setString(_nameKey, staffName ?? '');
    await prefs.setString(_adminIdKey, adminId ?? '');
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    role = null;
    staffName = null;
    adminId = null;
    await _secure.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_adminIdKey);
    notifyListeners();
  }
}

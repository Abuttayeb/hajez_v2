import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _role;
  String? _token;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  String? get role => _role;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;
  bool get isOwner => _role == 'owner';
  String get displayName => _user?['name']?.toString().split(' ').first ?? 'زائر';
  String get email => _user?['email'] ?? '';
  String get avatarUrl => _user?['avatar'] ?? '';

  AuthProvider() { _loadSession(); }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    final u = prefs.getString('user');
    _user = u != null ? jsonDecode(u) : null;
    notifyListeners();
  }

  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await AuthService.login(email: email, password: password);
      if (res['token'] != null) {
        _token = res['token'];
        _role = res['role'] ?? 'customer';
        _user = res['user'] ?? {};
        await AuthService.saveSession(_token!, _role!, _user!);
        _isLoading = false; notifyListeners();
        return true;
      }
      _setError(res['message'] ?? 'بيانات خاطئة');
      _isLoading = false; notifyListeners();
      return false;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _setError('تعذر الاتصال بالسيرفر');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> register({required String name, required String email, required String phone, required String password, required String role}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await AuthService.register(name: name, email: email, phone: phone, password: password, role: role);
      if (res['token'] != null) {
        _token = res['token'];
        _role = res['role'] ?? 'customer';
        _user = res['user'] ?? {};
        await AuthService.saveSession(_token!, _role!, _user!);
        _isLoading = false; notifyListeners();
        return true;
      }
      _setError(res['message'] ?? 'حدث خطأ');
      _isLoading = false; notifyListeners();
      return false;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _setError('تعذر الاتصال بالسيرفر');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await AuthService.forgotPassword(email);
      _isLoading = false; notifyListeners();
      return !res.containsKey('errors');
    } catch (e) {
      _setError('تعذر الاتصال');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? phone, String? city}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await AuthService.updateProfile(name: name, phone: phone, city: city);
      if (res['user'] != null) {
        _user = res['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        _isLoading = false; notifyListeners();
        return true;
      }
      _setError(res['message'] ?? 'حدث خطأ');
      _isLoading = false; notifyListeners();
      return false;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _setError('تعذر الاتصال');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await AuthService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      if (res['message'] != null && !_isError(res)) {
        _isLoading = false; notifyListeners();
        return true;
      }
      _setError(res['message'] ?? 'كلمة المرور الحالية غير صحيحة');
      _isLoading = false; notifyListeners();
      return false;
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _setError('تعذر الاتصال');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  bool _isError(Map<String, dynamic> res) {
    // إذا في errors (validation errors) = فشل
    return res['errors'] != null;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _token = null; _role = null; _user = null;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
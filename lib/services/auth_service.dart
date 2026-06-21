import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// ═══════════════════════════════════════════════════════════════
///  AuthService – مصادقة المستخدم وإدارة الجلسة
///  يتعامل مع: تسجيل الدخول، التسجيل، إعادة تعيين كلمة المرور،
///  تحديث الملف الشخصي، وإدارة التوكنات.
/// ═══════════════════════════════════════════════════════════════
class AuthService {
  // ─────────────────────────────────────────────────
  //  ثوابت المفاتيح في SharedPreferences
  // ─────────────────────────────────────────────────
  static const String _keyToken = 'token';
  static const String _keyRole = 'role';
  static const String _keyUser = 'user';

  // ─────────────────────────────────────────────────
  //  تسجيل حساب جديد
  // ─────────────────────────────────────────────────

  /// تسجيل مستخدم جديد وإرجاع بيانات الاستجابة من الخادم.
  ///
  /// يُرسل: الاسم، البريد، الهاتف، كلمة المرور، الدور.
  /// الخادم يعيد التوكن وبيانات المستخدم.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      return await ApiClient.instance.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'role': role,
      });
    } on ApiException {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────
  //  تسجيل الدخول
  // ─────────────────────────────────────────────────

  /// تسجيل الدخول بالبريد وكلمة المرور.
  ///
  /// يُرسل اختيارياً توكن FCM ونوع الجهاز.
  /// الخادم يعيد التوكن وبيانات المستخدم والدور.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
    String? deviceType,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (fcmToken != null) body['fcm_token'] = fcmToken;
      if (deviceType != null) body['device_type'] = deviceType;

      return await ApiClient.instance.post('/login', data: body);
    } on ApiException {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────
  //  تسجيل الخروج
  // ─────────────────────────────────────────────────

  /// تسجيل الخروج: يُرسل طلب للخادم ثم يمسح الجلسة محلياً.
  ///
  /// لا يُرمي خطأ حتى لو فشل طلب الخادم (نضمن مسح الجلسة).
  static Future<void> logout() async {
    try {
      await ApiClient.instance.post('/logout');
    } catch (_) {
      // نتجاهل أخطاء الخادم ونكمل مسح الجلسة
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUser);
  }

  // ─────────────────────────────────────────────────
  //  نسيان كلمة المرور
  // ─────────────────────────────────────────────────

  /// إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني.
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      return await ApiClient.instance.post(
        '/forgot-password',
        data: {'email': email},
      );
    } on ApiException {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────
  //  إعادة تعيين كلمة المرور
  // ─────────────────────────────────────────────────

  /// إعادة تعيين كلمة المرور باستخدام التوكن المُرسل بالبريد.
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    try {
      return await ApiClient.instance.post('/reset-password', data: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });
    } on ApiException {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────
  //  تحديث الملف الشخصي
  // ─────────────────────────────────────────────────

  /// تحديث بيانات الملف الشخصي.
  ///
  /// إذا تم تمرير [avatar] يُستخدم رفع متعدد الأجزاء (multipart).
  /// في حالة عدم وجود صورة يُرسل طلب JSON عادي.
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? city,
    File? avatar,
  }) async {
    try {
      // رفع مع صورة (multipart PUT)
      if (avatar != null) {
        final fields = <String, String>{};
        if (name != null) fields['name'] = name;
        if (phone != null) fields['phone'] = phone;
        if (city != null) fields['city'] = city;

        final file = MultipartFile.fromFileSync(
          avatar.path,
          filename: avatar.path.split('/').last,
        );

        return await ApiClient.instance.multipartPut(
          '/profile',
          files: [file],
          fields: fields,
          fileField: 'avatar',
        );
      }

      // تحديث بدون صورة (JSON PUT)
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (city != null) body['city'] = city;

      return await ApiClient.instance.put('/profile', data: body);
    } on ApiException {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────
  //  تغيير كلمة المرور
  // ─────────────────────────────────────────────────

  /// تغيير كلمة المرور الحالية.
  ///
  /// يتطلب: كلمة المرور الحالية والجديدة.
  /// يُرسل أيضاً تأكيد كلمة المرور الجديدة.
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await ApiClient.instance.post('/change-password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  إدارة الجلسة – SharedPreferences
  // ═══════════════════════════════════════════════════

  /// حفظ بيانات الجلسة (التوكن، الدور، بيانات المستخدم).
  static Future<void> saveSession(
    String token,
    String role,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  /// استرجاع التوكن المحفوظ.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// استرجاع الدور المحفوظ (user أو owner).
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  /// استرجاع بيانات المستخدم المحفوظة كخريطة.
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// التحقق مما إذا كان المستخدم مسجلاً الدخول.
  static Future<bool> isLoggedIn() async {
    return (await getToken()) != null;
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// ═══════════════════════════════════════════════════════════════
///  FcmService – إدارة إشعارات Firebase Cloud Messaging
///
///  يتعامل مع:
///  - طلب أذونات الإشعارات
///  - حفظ التوكن محلياً وإرساله للخادم
///  - التحديث التلقائي عند تجديد التوكن
///  - معالجة الرسائل في المقدمة والخلفية
/// ═══════════════════════════════════════════════════════════════

/// معالج الرسائل في الخلفية – يجب أن يكون دالة مستوى أعلى.
///
/// يُسجل كمعالج عند تهيئة Firebase في main().
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // معالجة الرسالة في الخلفية
  // يمكن إضافة منطق إشعارات محلية هنا مستقبلاً
}

class FcmService {
  // ─────────────────────────────────────────────────
  //  ثوابت المفاتيح
  // ─────────────────────────────────────────────────
  static const String _keyFcmToken = 'fcm_token';
  static const String _keyAuthToken = 'token';

  // ─────────────────────────────────────────────────
  //  تهيئة الخدمة
  // ─────────────────────────────────────────────────

  /// تهيئة خدمة الإشعارات.
  ///
  /// 1. طلب أذونات الإشعارات (تنبيه، شارة، صوت)
  /// 2. جلب التوكن الحالي وحفظه
  /// 3. الاستماع لتجديد التوكن
  /// 4. الاستماع للرسائل في المقدمة
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // طلب أذونات الإشعارات
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // جلب التوكن الحالي وحفظه
    final token = await messaging.getToken();
    if (token != null) await _saveToken(token);

    // التحديث التلقائي عند تجديد التوكن
    messaging.onTokenRefresh.listen(_saveToken);

    // الاستماع للرسائل في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // يمكن إضافة إشعار محلي هنا مستقبلاً
    });
  }

  // ─────────────────────────────────────────────────
  //  حفظ وإرسال التوكن
  // ─────────────────────────────────────────────────

  /// حفظ توكن FCM محلياً وإرساله للخادم.
  ///
  /// يُرسل للخادم فقط إذا كان المستخدم مسجلاً الدخول.
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, token);

    // التحقق من تسجيل الدخول قبل الإرسال للخادم
    final authToken = prefs.getString(_keyAuthToken);
    if (authToken == null) return;

    try {
      await ApiClient.instance.post(
        '/fcm-token',
        data: {'fcm_token': token},
      );
    } catch (_) {
      // لا نرمي الخطأ – فشل إرسال التوكن لا يوقف التطبيق
    }
  }
}

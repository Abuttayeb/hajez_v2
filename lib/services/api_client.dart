import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({required this.message, this.statusCode, this.errors});

  String get displayMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstError = errors!.values.first;
      if (firstError is List && firstError.isNotEmpty) return firstError.first.toString();
      return firstError.toString();
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;
  ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: BASE_URL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (_) => true,
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(),
    ]);
  }

  // ───── GET ─────
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParams);
      return _handleResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ───── POST ─────
  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return _handleResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ───── PUT ─────
  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return _handleResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ───── DELETE ─────
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _handleResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ───── Multipart POST ─────
  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required List<MultipartFile> files,
    Map<String, String> fields = const {},
    String fileField = 'image',
  }) async {
    try {
      final formData = FormData.fromMap({
        for (final e in fields.entries) e.key: e.value,
        if (files.length == 1) fileField: files.first,
        if (files.length > 1) fileField: files,
      });
      final res = await _dio.post(path, data: formData);
      return _handleResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ───── Multipart PUT ─────
  Future<Map<String, dynamic>> multipartPut(
    String path, {
    List<MultipartFile>? files,
    Map<String, String> fields = const {},
    String fileField = 'avatar',
  }) async {
    try {
      final map = <String, dynamic>{};
      map.addAll(fields);
      if (files != null && files.isNotEmpty) {
        map[fileField] = files.first;
      }
      final formData = FormData.fromMap(map);
      final res = await _dio.put(path, data: formData);
      return _handleResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ───── Response Handler ─────
  Map<String, dynamic> _handleResponse(Response res) {
    final data = res.data;
    if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
      return data is Map<String, dynamic> ? data : {'data': data};
    }
    if (data is Map<String, dynamic>) {
      throw ApiException(
        message: data['message'] ?? 'حدث خطأ في الخادم',
        statusCode: res.statusCode,
        errors: data['errors'] != null ? Map<String, dynamic>.from(data['errors'] as Map) : null,
      );
    }
    throw ApiException(message: 'حدث خطأ غير متوقع', statusCode: res.statusCode);
  }

  // ───── Error Handler ─────
  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(message: 'انتهت مهلة الاتصال، تحقق من الإنترنت');
      case DioExceptionType.connectionError:
        return const ApiException(message: 'لا يوجد اتصال بالإنترنت');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return ApiException(
            message: data['message'] ?? 'خطأ في الخادم',
            statusCode: e.response?.statusCode,
            errors: data['errors'] != null ? Map<String, dynamic>.from(data['errors'] as Map) : null,
          );
        }
        return ApiException(message: 'خطأ في الخادم', statusCode: e.response?.statusCode);
      default:
        return const ApiException(message: 'حدث خطأ غير متوقع');
    }
  }
}

// ═══════════════════════════════════════════════════
//  Auth Interceptor - حقن التوكن تلقائياً
// ═══════════════════════════════════════════════════
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // التوكن منتهي - ممكن نعمل logout تلقائي
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('token');
        prefs.remove('role');
        prefs.remove('user');
      });
    }
    handler.next(err);
  }
}

// ═══════════════════════════════════════════════════
//  Logging Interceptor - للتصحيح في الـ development
// ═══════════════════════════════════════════════════
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // في الإنتاج ممكن نلغي هذا
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// ═══════════════════════════════════════════════════════════════
///  FarmService – جميع العمليات المتعلقة بالمزارع والحجوزات
///
///  يشمل:
///  - التصنيفات
///  - المزارع (عرض عام، تفاصيل، التوفر)
///  - المفضلة (إضافة/حذف، فحص، قائمة)
///  - الإشعارات
///  - الكوبونات
///  - البلاغات
///  - الحجوزات (إنشاء، عرض، إلغاء)
///  - التقييمات
///  - عمليات مالك المزرعة
/// ═══════════════════════════════════════════════════════════════
class FarmService {
  // ═══════════════════════════════════════════════════
  //  التصنيفات
  // ═══════════════════════════════════════════════════

  /// جلب جميع التصنيفات مع عدد المزارع في كل تصنيف.
  ///
  /// يُرجع قائمة من التصنيفات.
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await ApiClient.instance.get(
        '/categories',
        queryParams: {'with_farms_count': '1'},
      );
      return response['data'] is List
          ? response['data'] as List<dynamic>
          : <dynamic>[];
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  المزارع – عرض عام
  // ═══════════════════════════════════════════════════

  /// جلب قائمة المزارع مع فلاتر البحث والتصفية.
  ///
  /// يدعم: البحث، المدينة، النوع، التصنيف، المسبح، نطاق السعر،
  /// السعة، الترتيب، الإحداثيات، والترقيم.
  ///
  /// يُرجع خريطة تحتوي `data` (قائمة المزارع) و `meta` (بيانات الترقيم).
  static Future<Map<String, dynamic>> getFarms({
    String? search,
    String? city,
    String? type,
    int? categoryId,
    bool? hasPool,
    double? minPrice,
    double? maxPrice,
    int? capacity,
    String? sort,
    int page = 1,
    int perPage = 15,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (categoryId != null) params['category_id'] = categoryId;
      if (hasPool == true) params['has_pool'] = '1';
      if (minPrice != null) params['min_price'] = minPrice;
      if (maxPrice != null) params['max_price'] = maxPrice;
      if (capacity != null) params['capacity'] = capacity;
      if (sort != null) params['sort'] = sort;
      if (latitude != null) params['latitude'] = latitude;
      if (longitude != null) params['longitude'] = longitude;
      params['page'] = page;
      params['per_page'] = perPage;

      return await ApiClient.instance.get('/farms', queryParams: params);
    } on ApiException {
      rethrow;
    }
  }

  /// جلب تفاصيل مزرعة واحدة بالمعرف.
  ///
  /// يُرجع بيانات المزرعة مع حقل `is_favorited` مُلحق.
  static Future<Map<String, dynamic>> getFarm(int id) async {
    try {
      return await ApiClient.instance.get('/farms/$id');
    } on ApiException {
      rethrow;
    }
  }

  /// التحقق من توفر المزرعة في تواريخ محددة.
  ///
  /// يُرجع خريطة تحتوي:
  /// - `available`: هل المزرعة متاحة
  /// - `total_price`: السعر الإجمالي
  /// - `nights`: عدد الليالي
  /// - `weekday_nights`: ليالي أيام الأسبوع
  /// - `weekend_nights`: ليالي عطلة نهاية الأسبوع
  /// - `weekday_price`: سعر ليلة يوم أسبوع
  /// - `weekend_price`: سعر ليلة عطلة
  /// - `price_breakdown`: تفصيل الأسعار
  static Future<Map<String, dynamic>> checkAvailability(
    int farmId,
    String checkIn,
    String checkOut, {
    required int guests,
  }) async {
    try {
      return await ApiClient.instance.get(
        '/farms/$farmId/availability',
        queryParams: {
          'check_in': checkIn,
          'check_out': checkOut,
          'guests': guests,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  المفضلة
  // ═══════════════════════════════════════════════════

  /// تبديل حالة المفضلة لمزرعة معينة.
  ///
  /// يُرجع `{favorited: bool}` يُشير للحالة الجديدة.
  static Future<Map<String, dynamic>> toggleFavorite(int farmId) async {
    try {
      return await ApiClient.instance.post(
        '/favorites/toggle',
        data: {'farm_id': farmId},
      );
    } on ApiException {
      rethrow;
    }
  }

  /// التحقق مما إذا كانت المزرعة في المفضلة.
  ///
  /// يُرجع `{is_favorited: bool}`.
  static Future<Map<String, dynamic>> checkFavorite(int farmId) async {
    try {
      return await ApiClient.instance.get(
        '/favorites/check',
        queryParams: {'farm_id': farmId},
      );
    } on ApiException {
      rethrow;
    }
  }

  /// جلب قائمة المزارع المفضلة مع ترقيم الصفحات.
  ///
  /// يُرجع `{data: [{farm: {...}, ...}]}`.
  static Future<Map<String, dynamic>> getFavorites({int page = 1}) async {
    try {
      return await ApiClient.instance.get(
        '/favorites',
        queryParams: {'page': page},
      );
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  الإشعارات
  // ═══════════════════════════════════════════════════

  /// جلب قائمة الإشعارات مع ترقيم الصفحات.
  ///
  /// يُرجع `{notifications: {data: [...]}, unread_count: int}`.
  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      return await ApiClient.instance.get(
        '/notifications',
        queryParams: {'page': page},
      );
    } on ApiException {
      rethrow;
    }
  }

  /// جلب عدد الإشعارات غير المقروءة.
  ///
  /// يُرجع `{count: int}`.
  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      return await ApiClient.instance.get('/notifications/unread-count');
    } on ApiException {
      rethrow;
    }
  }

  /// تعليم إشعار معين كمقروء.
  static Future<void> markNotificationRead(int id) async {
    try {
      await ApiClient.instance.post('/notifications/$id/read');
    } on ApiException {
      rethrow;
    }
  }

  /// تعليم جميع الإشعارات كمقروءة.
  static Future<void> markAllRead() async {
    try {
      await ApiClient.instance.post('/notifications/read-all');
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  الكوبونات
  // ═══════════════════════════════════════════════════

  /// التحقق من صحة كود الخصم.
  ///
  /// يُرسل الكود وقيمة الطلب ويُرجع تفاصيل الخصم:
  /// - `valid`: هل الكود صالح
  /// - `discount_amount`: قيمة الخصم
  /// - `discount_type`: نوع الخصم (percentage / fixed)
  /// - `code`: الكود
  static Future<Map<String, dynamic>> validateCoupon(
    String code,
    double orderAmount,
  ) async {
    try {
      return await ApiClient.instance.post(
        '/coupons/validate',
        data: {'code': code, 'order_amount': orderAmount},
      );
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  البلاغات
  // ═══════════════════════════════════════════════════

  /// إرسال بلاغ عن عنصر (مزرعة أو تقييم).
  ///
  /// [reportableType]: نوع العنصر (Farm, Review)
  /// [reportableId]: معرف العنصر
  /// [reason]: سبب البلاغ
  /// [description]: وصف اختياري
  static Future<Map<String, dynamic>> submitReport({
    required String reportableType,
    required int reportableId,
    required String reason,
    String? description,
  }) async {
    try {
      return await ApiClient.instance.post('/reports', data: {
        'reportable_type': reportableType,
        'reportable_id': reportableId,
        'reason': reason,
        if (description != null) 'description': description,
      });
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  الحجوزات
  // ═══════════════════════════════════════════════════

  /// إنشاء حجز جديد.
  ///
  /// يُرجع `{booking: {...}, payment: {...}}` مع بيانات الحجز والدفع.
  static Future<Map<String, dynamic>> createBooking({
    required int farmId,
    required String checkIn,
    required String checkOut,
    required int guests,
    String paymentMethod = 'cash',
    String? notes,
    String? couponCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'farm_id': farmId,
        'check_in': checkIn,
        'check_out': checkOut,
        'guests': guests,
        'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      };
      if (couponCode != null && couponCode.isNotEmpty) {
        body['coupon_code'] = couponCode;
      }

      return await ApiClient.instance.post('/bookings', data: body);
    } on ApiException {
      rethrow;
    }
  }

  /// جلب حجوزات المستخدم مع فلاتر وترقيم.
  ///
  /// [status]: فلتر الحالة (confirmed, pending, cancelled, completed)
  /// [filter]: فلتر إضافي (upcoming, past, active)
  static Future<Map<String, dynamic>> getMyBookings({
    String? status,
    String? filter,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (status != null) params['status'] = status;
      if (filter != null) params['filter'] = filter;

      return await ApiClient.instance.get('/my-bookings', queryParams: params);
    } on ApiException {
      rethrow;
    }
  }

  /// جلب تفاصيل حجز واحد.
  ///
  /// يُرجع بيانات الحجز مع علاقات farm و payment.
  static Future<Map<String, dynamic>> getBooking(int id) async {
    try {
      return await ApiClient.instance.get('/my-bookings/$id');
    } on ApiException {
      rethrow;
    }
  }

  /// إلغاء حجز معين.
  ///
  /// [reason]: سبب الإلغاء (اختياري).
  static Future<Map<String, dynamic>> cancelBooking(
    int id, {
    String? reason,
  }) async {
    try {
      return await ApiClient.instance.post(
        '/my-bookings/$id/cancel',
        data: {'reason': reason},
      );
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  التقييمات
  // ═══════════════════════════════════════════════════

  /// جلب تقييمات مزرعة معينة.
  ///
  /// يُرجع خريطة تحتوي:
  /// - `reviews`: `{data: [...]}` قائمة التقييمات
  /// - `stats`: `{average_rating, total, star_breakdown, sub_ratings}`
  static Future<Map<String, dynamic>> getFarmReviews(int farmId) async {
    try {
      return await ApiClient.instance.get('/farms/$farmId/reviews');
    } on ApiException {
      rethrow;
    }
  }

  /// إضافة تقييم جديد لحجز.
  ///
  /// يدعم تقييمات فرعية: النظافة، الخدمة، القيمة، الموقع.
  /// [isAnonymous]: هل التقييم مجهول الهوية.
  static Future<Map<String, dynamic>> addReview({
    required int bookingId,
    required int rating,
    String? comment,
    double? cleanliness,
    double? service,
    double? value,
    double? location,
    bool isAnonymous = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
        'is_anonymous': isAnonymous,
      };
      if (cleanliness != null) body['cleanliness_rating'] = cleanliness;
      if (service != null) body['service_rating'] = service;
      if (value != null) body['value_rating'] = value;
      if (location != null) body['location_rating'] = location;

      return await ApiClient.instance.post('/reviews', data: body);
    } on ApiException {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  //  مالك المزرعة
  // ═══════════════════════════════════════════════════

  /// جلب مزارع المالك المسجلة مع ترقيم.
  static Future<Map<String, dynamic>> getMyFarms({int page = 1}) async {
    try {
      return await ApiClient.instance.get(
        '/my-farms',
        queryParams: {'page': page},
      );
    } on ApiException {
      rethrow;
    }
  }

  /// جلب حجوزات مالك المزرعة مع فلاتر وترقيم.
  ///
  /// [status]: فلتر الحالة
  /// [filter]: فلتر إضافي (upcoming, past, active)
  static Future<Map<String, dynamic>> getOwnerBookings({
    String? status,
    String? filter,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (status != null) params['status'] = status;
      if (filter != null) params['filter'] = filter;

      return await ApiClient.instance.get(
        '/owner/bookings',
        queryParams: params,
      );
    } on ApiException {
      rethrow;
    }
  }

  /// إنشاء مزرعة جديدة.
  ///
  /// [data]: بيانات المزرعة (الاسم، الوصف، السعر، العنوان، ...).
  /// يُرجع `{farm: {...}}`.
  static Future<Map<String, dynamic>> createFarm(
    Map<String, dynamic> data,
  ) async {
    try {
      return await ApiClient.instance.post('/farms', data: data);
    } on ApiException {
      rethrow;
    }
  }

  /// تحديث بيانات مزرعة موجودة.
  ///
  /// يُرجع `{farm: {...}}` بالبيانات المُحدثة.
  static Future<Map<String, dynamic>> updateFarm(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await ApiClient.instance.put('/farms/$id', data: data);
    } on ApiException {
      rethrow;
    }
  }

  /// حذف مزرعة.
  static Future<void> deleteFarm(int id) async {
    try {
      await ApiClient.instance.delete('/farms/$id');
    } on ApiException {
      rethrow;
    }
  }

  /// رفع صورة لمزرعة (multipart).
  ///
  /// [farmId]: معرف المزرعة
  /// [imageFile]: ملف الصورة
  /// [isCover]: هل الصورة غلاف
  /// [category]: تصنيف الصورة (general, pool, outdoor, ...)
  /// يُرجع `{image: {...}}`.
  static Future<Map<String, dynamic>> uploadFarmImage({
    required int farmId,
    required File imageFile,
    bool isCover = false,
    String category = 'general',
  }) async {
    try {
      final file = MultipartFile.fromFileSync(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      );

      return await ApiClient.instance.multipartPost(
        '/farms/$farmId/images',
        files: [file],
        fields: {
          'is_cover': isCover ? '1' : '0',
          'category': category,
        },
        fileField: 'image',
      );
    } on ApiException {
      rethrow;
    }
  }

  /// حذف صورة من مزرعة.
  static Future<void> deleteFarmImage(int farmId, int imageId) async {
    try {
      await ApiClient.instance.delete('/farms/$farmId/images/$imageId');
    } on ApiException {
      rethrow;
    }
  }

  /// تحديث حالة حجز (من طرف المالك).
  ///
  /// [status]: الحالة الجديدة (confirmed, rejected, cancelled)
  /// [rejectionReason]: سبب الرفض (اختياري).
  static Future<Map<String, dynamic>> updateBookingStatus(
    int id,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (rejectionReason != null) body['rejection_reason'] = rejectionReason;

      return await ApiClient.instance.put(
        '/owner/bookings/$id/status',
        data: body,
      );
    } on ApiException {
      rethrow;
    }
  }
}

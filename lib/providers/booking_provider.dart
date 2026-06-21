import 'package:flutter/material.dart';
import '../services/farm_service.dart';
import '../services/api_client.dart';

class BookingProvider extends ChangeNotifier {
  List<dynamic> _myBookings = [];
  List<dynamic> _ownerBookings = [];
  bool _isLoading = true;
  String? _error;
  bool _isActionLoading = false;
  String? _lastError;
  int _myBookingsPage = 1;
  int _ownerBookingsPage = 1;
  bool _hasMoreMy = true;
  bool _hasMoreOwner = true;

  List<dynamic> get myBookings => _myBookings;
  List<dynamic> get ownerBookings => _ownerBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isActionLoading => _isActionLoading;
  String? get lastError => _lastError;
  bool get hasMoreMy => _hasMoreMy;
  bool get hasMoreOwner => _hasMoreOwner;

  List<dynamic> get pendingBookings => _myBookings.where((b) => ['pending', 'confirmed'].contains(b['status'])).toList();
  List<dynamic> get completedBookings => _myBookings.where((b) => b['status'] == 'completed').toList();
  List<dynamic> get cancelledBookings => _myBookings.where((b) => b['status'] == 'cancelled').toList();
  List<dynamic> get pendingOwnerBookings => _ownerBookings.where((b) => b['status'] == 'pending').toList();
  int get pendingCount => _ownerBookings.where((b) => b['status'] == 'pending').length;
  double get totalRevenue => _ownerBookings.where((b) => b['status'] == 'completed').fold<double>(0, (s, b) => s + (b['total_price'] as num).toDouble());

  Future<void> loadMyBookings({bool refresh = false}) async {
    if (refresh) { _myBookingsPage = 1; _myBookings = []; _hasMoreMy = true; }
    _isLoading = _myBookings.isEmpty; _error = null; _lastError = null; notifyListeners();
    try {
      final res = await FarmService.getMyBookings(page: _myBookingsPage);
      final data = res['data'] as List? ?? [];
      if (_myBookingsPage == 1) {
        _myBookings = data;
      } else {
        _myBookings.addAll(data);
      }
      _hasMoreMy = (res['meta']?['current_page'] ?? 1) < (res['meta']?['last_page'] ?? 1);
      _isLoading = false; notifyListeners();
    } on ApiException catch (e) {
      _lastError = e.displayMessage;
      _error = 'تعذر تحميل الحجوزات';
      _isLoading = false; notifyListeners();
    } catch (e) {
      _error = 'تعذر تحميل الحجوزات';
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> loadMoreMyBookings() async {
    if (_isLoading || !_hasMoreMy) return;
    _myBookingsPage++;
    await loadMyBookings();
  }

  Future<void> loadOwnerBookings({bool refresh = false}) async {
    if (refresh) { _ownerBookingsPage = 1; _ownerBookings = []; _hasMoreOwner = true; }
    _isLoading = _ownerBookings.isEmpty; _error = null; _lastError = null; notifyListeners();
    try {
      final res = await FarmService.getOwnerBookings(page: _ownerBookingsPage);
      final data = res['data'] as List? ?? [];
      if (_ownerBookingsPage == 1) {
        _ownerBookings = data;
      } else {
        _ownerBookings.addAll(data);
      }
      _hasMoreOwner = (res['meta']?['current_page'] ?? 1) < (res['meta']?['last_page'] ?? 1);
      _isLoading = false; notifyListeners();
    } on ApiException catch (e) {
      _lastError = e.displayMessage;
      _error = 'تعذر تحميل الحجوزات';
      _isLoading = false; notifyListeners();
    } catch (e) {
      _error = 'تعذر تحميل الحجوزات';
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> cancelBooking(int id, {String? reason}) async {
    _isActionLoading = true; _lastError = null; notifyListeners();
    try {
      await FarmService.cancelBooking(id, reason: reason);
      await loadMyBookings(refresh: true);
      _isActionLoading = false; notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.displayMessage;
      _isActionLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _isActionLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> updateBookingStatus(int id, String status, {String? rejectionReason}) async {
    _isActionLoading = true; _lastError = null; notifyListeners();
    try {
      await FarmService.updateBookingStatus(id, status, rejectionReason: rejectionReason);
      await loadOwnerBookings(refresh: true);
      _isActionLoading = false; notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.displayMessage;
      _isActionLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _isActionLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> createBooking({
    required int farmId, required String checkIn, required String checkOut,
    required int guests, String paymentMethod = 'cash', String? notes, String? couponCode,
  }) async {
    _isActionLoading = true; _lastError = null; notifyListeners();
    try {
      final res = await FarmService.createBooking(
        farmId: farmId, checkIn: checkIn, checkOut: checkOut,
        guests: guests, paymentMethod: paymentMethod, notes: notes, couponCode: couponCode,
      );
      if (res['booking'] != null) {
        await loadMyBookings(refresh: true);
        _isActionLoading = false; notifyListeners();
        return true;
      }
      _lastError = res['message'] ?? 'فشل إنشاء الحجز';
      _isActionLoading = false; notifyListeners();
      return false;
    } on ApiException catch (e) {
      _lastError = e.displayMessage;
      _isActionLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'تعذر الاتصال بالسيرفر';
      _isActionLoading = false; notifyListeners();
      return false;
    }
  }

  void retry() => loadMyBookings(refresh: true);
}
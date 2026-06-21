import 'package:flutter/material.dart';
import '../services/farm_service.dart';
import '../services/api_client.dart';

class FarmProvider extends ChangeNotifier {
  List<dynamic> _farms = [];
  List<dynamic> _featuredFarms = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCity = '';
  Map<String, dynamic> _filters = {};
  int _currentPage = 1;
  bool _hasMore = true;

  List<dynamic> get farms => _farms;
  List<dynamic> get featuredFarms => _featuredFarms;
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCity => _selectedCity;
  Map<String, dynamic> get filters => _filters;
  bool get hasMore => _hasMore;
  int get totalFarms => _farms.length;

  FarmProvider() {
    loadCategories();
    loadFarms();
  }

  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<void> loadCategories() async {
    try {
      final res = await FarmService.getCategories();
      if (res is Map && res.containsKey('data')) {
        _categories = List<dynamic>.from(res['data'] ?? []);
      } else if (res is List) {
        _categories = res;
      } else {
        _categories = [];
      }
      notifyListeners();
    } on ApiException {
      // صامت - نحملها لاحقاً
    } catch (_) {}
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _currentPage = 1; _farms = []; _hasMore = true;
    loadFarms();
  }

  void updateCity(String city) {
    _selectedCity = city;
    _currentPage = 1; _farms = []; _hasMore = true;
    loadFarms();
  }

  void updateFilters(Map<String, dynamic> filters) {
    _filters = filters;
    _currentPage = 1; _farms = []; _hasMore = true;
    loadFarms();
  }

  void clearFilters() {
    _filters = {};
    _searchQuery = '';
    _selectedCity = '';
    _currentPage = 1; _farms = []; _hasMore = true;
    loadFarms();
  }

  Future<void> loadFarms({bool refresh = false}) async {
    if (refresh) { _currentPage = 1; _farms = []; }
    _isLoading = _farms.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final res = await FarmService.getFarms(
        search: _searchQuery,
        city: _selectedCity,
        type: _filters['type'],
        categoryId: _filters['category_id'],
        hasPool: _filters['has_pool'],
        minPrice: _filters['min_price']?.toDouble(),
        maxPrice: _filters['max_price']?.toDouble(),
        capacity: _filters['capacity'],
        sort: _filters['sort'],
        page: _currentPage,
      );

      final newFarms = res['data'] as List? ?? [];
      if (_currentPage == 1) {
        _farms = List<dynamic>.from(newFarms);
      } else {
        _farms.addAll(List<dynamic>.from(newFarms));
      }

      // فصل المزارع المميزة
      _featuredFarms = _farms.where((f) {
        if (f['is_featured'] != true) return false;
        final until = f['featured_until'];
        if (until == null) return true;
        try { return DateTime.parse(until.toString()).isAfter(DateTime.now()); } catch (_) { return false; }
      }).toList();

      // التحقق من التصفح من الـ meta
      _hasMore = (res['meta']?['current_page'] ?? 1) < (res['meta']?['last_page'] ?? 1);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _setError(e.displayMessage);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('تعذر تحميل المزارع');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await loadFarms();
  }

  void retry() => loadFarms(refresh: true);
}
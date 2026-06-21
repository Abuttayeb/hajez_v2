import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/farm_service.dart';
import '../services/api_client.dart';

class FavoritesProvider extends ChangeNotifier {
  Set<int> _favoriteIds = {};
  List<dynamic> _favoriteFarms = [];
  bool _isLoading = false;
  String? lastError;

  Set<int> get favoriteIds => _favoriteIds;
  List<dynamic> get favoriteFarms => _favoriteFarms;
  bool isFavorite(int id) => _favoriteIds.contains(id);
  int get count => _favoriteIds.length;
  bool get isLoading => _isLoading;

  FavoritesProvider() { _loadLocal(); }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      await loadFromServer();
    }
    notifyListeners();
  }

  Future<void> loadFromServer() async {
    _isLoading = true; lastError = null; notifyListeners();
    try {
      final res = await FarmService.getFavorites();
      final data = res['data'] as List? ?? [];
      _favoriteFarms = data.map((f) => f['farm'] as Map<String, dynamic>? ?? f).toList();
      _favoriteIds = _favoriteFarms.map<int>((f) => f['id'] as int).toSet();
      _isLoading = false; notifyListeners();
    } on ApiException catch (e) {
      lastError = e.displayMessage;
      _isLoading = false; notifyListeners();
    } catch (e) {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> toggle(int farmId) async {
    lastError = null;
    try {
      final res = await FarmService.toggleFavorite(farmId);
      final favorited = res['favorited'] as bool? ?? false;
      if (favorited) {
        _favoriteIds.add(farmId);
      } else {
        _favoriteIds.remove(farmId);
        _favoriteFarms.removeWhere((f) => f['id'] == farmId);
      }
      notifyListeners();
      return favorited;
    } on ApiException catch (e) {
      lastError = e.displayMessage;
      notifyListeners();
      return _favoriteIds.contains(farmId);
    } catch (e) {
      return _favoriteIds.contains(farmId);
    }
  }

  void setFavorites(List<dynamic> farms) {
    _favoriteIds = farms.where((f) => f['is_favorited'] == true).map<int>((f) => f['id'] as int).toSet();
    notifyListeners();
  }
}
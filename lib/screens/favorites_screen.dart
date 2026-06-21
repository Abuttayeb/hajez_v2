import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../services/farm_service.dart';
import '../providers/favorites_provider.dart';
import '../widgets/farm_card.dart';
import '../widgets/state_views.dart';
import 'farm/farm_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<dynamic> _farms = [];
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadFavorites();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _error = null;
    });
    try {
      final res = await FarmService.getFavorites(page: 1);
      final data = res['data'] as List? ?? [];
      setState(() {
        _farms = data.map((f) => f['farm'] as Map<String, dynamic>? ?? f).toList();
        _isLoading = false;
        _currentPage = (res['current_page'] as int?) ?? 1;
        _lastPage = (res['last_page'] as int?) ?? 1;
      });
      if (mounted) {
        context.read<FavoritesProvider>().setFavorites(data);
      }
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل المفضلة';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await FarmService.getFavorites(page: nextPage);
      final data = res['data'] as List? ?? [];
      setState(() {
        _farms.addAll(data.map((f) => f['farm'] as Map<String, dynamic>? ?? f));
        _currentPage = (res['current_page'] as int?) ?? nextPage;
        _lastPage = (res['last_page'] as int?) ?? _lastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المفضلة'),
        actions: [
          if (_farms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Text(
                  '${_farms.length} مكان',
                  style:
                      AppText.smallBold.copyWith(color: AppColors.grey600),
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? ErrorView(
              message: _error!,
              onRetry: _loadFavorites,
              icon: Icons.favorite_border_rounded,
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _farms.isEmpty
                  ? EmptyView(
                      message: 'لم تضف أي مكان للمفضلة بعد',
                      icon: Icons.favorite_border_rounded,
                      actionLabel: 'استكشف المزارع',
                      onAction: () {
                        // Navigate to home/explore
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (r) => false);
                      },
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _farms.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= _farms.length) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final f = _farms[i];
                          return Dismissible(
                            key: ValueKey(f['id']),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              final res =
                                  await FarmService.toggleFavorite(f['id'] as int);
                              return res['favorited'] == false;
                            },
                            onDismissed: (_) {
                              setState(() => _farms.removeAt(i));
                              context
                                  .read<FavoritesProvider>()
                                  .toggle(f['id'] as int);
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.only(left: 24),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FarmCard(
                                farm: f,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FarmDetailScreen(
                                        farmId: f['id']),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

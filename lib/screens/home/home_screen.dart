import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../services/farm_service.dart';
import '../../providers/farm_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/farm_card.dart';
import '../../widgets/shimmer_cards.dart';
import '../../widgets/state_views.dart';
import '../farm/farm_detail_screen.dart';
import '../farm/filter_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final _bannerCtrl = PageController();
  int _navIndex = 0;
  bool _isOffline = false;
  int _unreadCount = 0;

  final List<Map<String, String>> _cities = [
    {'name': '', 'label': 'الكل', 'icon': 'apps'},
    {'name': 'عمان', 'label': 'عمان', 'icon': 'location_city'},
    {'name': 'العقبة', 'label': 'العقبة', 'icon': 'beach_access'},
    {'name': 'البحر الميت', 'label': 'البحر الميت', 'icon': 'water'},
    {'name': 'إربد', 'label': 'إربد', 'icon': 'park'},
    {'name': 'الزرقاء', 'label': 'الزرقاء', 'icon': 'apartment'},
    {'name': 'جرش', 'label': 'جرش', 'icon': 'account_balance'},
    {'name': 'السلط', 'label': 'السلط', 'icon': 'terrain'},
    {'name': 'الكرك', 'label': 'الكرك', 'icon': 'castle'},
  ];

  IconData _categoryIcon(String? iconName) {
    switch (iconName) {
      case 'agriculture':
        return Icons.agriculture_outlined;
      case 'cottage':
      case 'chalet':
        return Icons.cottage_outlined;
      case 'villa':
        return Icons.villa_outlined;
      case 'resort':
        return Icons.spa_outlined;
      case 'pool':
        return Icons.pool;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOffline = result == ConnectivityResult.none);
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await FarmService.getUnreadCount();
      final count = (res['unread_count'] ?? 0) as int;
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isOffline = result == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildHomeTab(),
            const MyBookingsScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.grey200, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'استكشف',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'حجوزاتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final farmProv = context.watch<FarmProvider>();
    final authProv = context.watch<AuthProvider>();

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => farmProv.loadFarms(refresh: true),
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اهلا، ${authProv.displayName}',
                              style: AppText.bodyGrey.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'اكتشف وجهتك القادمة',
                              style: AppText.heading2,
                            ),
                          ],
                        ),
                      ),
                      // Notification bell with badge
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ).then((_) => _loadUnreadCount());
                        },
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.dark,
                                  size: 22,
                                ),
                                if (_unreadCount > 0)
                                  Positioned(
                                    top: -2,
                                    left: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        _unreadCount > 9
                                            ? '9+'
                                            : '$_unreadCount',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.grey500,
                                  size: 22,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onSubmitted: (_) => farmProv
                                      .updateSearch(_searchCtrl.text.trim()),
                                  decoration: const InputDecoration(
                                    hintText: 'ابحث عن مزرعة أو شاليه...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AppColors.grey500,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 14),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchCtrl.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    farmProv.updateSearch('');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.close,
                                      color: AppColors.grey500,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FilterScreen(
                                filters: farmProv.filters,
                              ),
                            ),
                          );
                          if (result != null) farmProv.updateFilters(result);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: farmProv.filters.isNotEmpty
                                ? AppColors.primary
                                : AppColors.grey100,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: farmProv.filters.isNotEmpty
                                ? AppColors.white
                                : AppColors.dark,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Categories (Dynamic from API) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
                  child: SizedBox(
                    height: 80,
                    child: farmProv.categories.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: farmProv.categories.length + 1,
                            itemBuilder: (_, i) {
                              // "All" item first
                              if (i == 0) {
                                final isActive =
                                    farmProv.filters['category_id'] ==
                                        null;
                                return GestureDetector(
                                  onTap: () {
                                    final f = Map<String, dynamic>.from(
                                        farmProv.filters)
                                      ..remove('category_id');
                                    farmProv.updateFilters(f);
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    width: 72,
                                    margin: const EdgeInsets.only(left: 10),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primary
                                          : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.lg),
                                      border: isActive
                                          ? null
                                          : Border.all(
                                              color: AppColors.grey200),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.apps_rounded,
                                          color: isActive
                                              ? AppColors.white
                                              : AppColors.dark,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'الكل',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? AppColors.white
                                                : AppColors.darkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final cat = farmProv.categories[i - 1];
                              final catId = cat['id'];
                              final catName =
                                  cat['name']?.toString() ?? '';
                              final catIcon = _categoryIcon(
                                  cat['icon']?.toString());
                              final isActive =
                                  farmProv.filters['category_id'] == catId;

                              return GestureDetector(
                                onTap: () {
                                  farmProv.updateFilters({
                                    ...farmProv.filters,
                                    'category_id': catId,
                                  });
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  width: 72,
                                  margin: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.grey100,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.lg),
                                    border: isActive
                                        ? null
                                        : Border.all(
                                            color: AppColors.grey200),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        catIcon,
                                        color: isActive
                                            ? AppColors.white
                                            : AppColors.dark,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        catName,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isActive
                                              ? AppColors.white
                                              : AppColors.darkSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),

              // ── Featured Farms (Horizontal Slider) ──
              if (farmProv.featuredFarms.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'مزارع مميزة',
                              style: AppText.heading3,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  farmProv.updateFilters({'type': ''}),
                              child: Text(
                                'عرض الكل',
                                style: AppText.smallBold
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 20),
                          itemCount: farmProv.featuredFarms.length,
                          itemBuilder: (_, i) {
                            final f = farmProv.featuredFarms[i];
                            return _FeaturedCard(
                              farm: f,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmDetailScreen(
                                      farmId: f['id']),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Cities ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cities.length,
                      itemBuilder: (_, i) {
                        final c = _cities[i];
                        final sel =
                            farmProv.selectedCity == c['name'];
                        return GestureDetector(
                          onTap: () =>
                              farmProv.updateCity(c['name']!),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                            child: Text(
                              c['label']!,
                              style: TextStyle(
                                color: sel
                                    ? AppColors.white
                                    : AppColors.darkSecondary,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Results Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      if (farmProv.isLoading && farmProv.farms.isEmpty)
                        const SizedBox()
                      else
                        Text(
                          farmProv.farms.isEmpty
                              ? 'لا توجد نتائج'
                              : '${farmProv.farms.length} مكان متاح',
                          style: AppText.heading4,
                        ),
                      const Spacer(),
                      if (farmProv.filters.isNotEmpty ||
                          farmProv.selectedCity.isNotEmpty ||
                          farmProv.searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => farmProv.clearFilters(),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.filter_list_off,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'مسح الفلاتر',
                                style: AppText.smallBold
                                    .copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Farms List ──
              if (farmProv.isLoading && farmProv.farms.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const FarmCardShimmer(),
                      childCount: 5,
                    ),
                  ),
                )
              else if (farmProv.error != null &&
                  farmProv.farms.isEmpty)
                SliverFillRemaining(
                  child: ErrorView(
                    message: farmProv.error!,
                    onRetry: farmProv.retry,
                  ),
                )
              else if (farmProv.farms.isEmpty)
                SliverFillRemaining(
                  child: EmptyView(
                    message: 'لا توجد مزارع تطابق بحثك',
                    icon: Icons.search_off_rounded,
                    onAction: farmProv.clearFilters,
                    actionLabel: 'مسح الفلاتر',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => AnimationConfiguration
                          .staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: FarmCard(
                              farm: farmProv.farms[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmDetailScreen(
                                      farmId:
                                          farmProv.farms[i]['id']),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      childCount: farmProv.farms.length,
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),

        // Offline banner
        if (_isOffline)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineBanner(),
          ),
      ],
    );
  }
}

// ── Featured Farm Horizontal Card ──
class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> farm;
  final VoidCallback onTap;

  const _FeaturedCard({required this.farm, required this.onTap});

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$BASE_URL${url.startsWith('/') ? '' : '/'}$url';
  }

  @override
  Widget build(BuildContext context) {
    final images = farm['images'] as List? ?? [];
    final rawCover = farm['cover_image'] ??
        (images.isNotEmpty ? images[0]['image_path'] : null);
    final coverImage =
        rawCover != null ? _fixUrl(rawCover.toString()) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(left: 12, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowPrimary,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBF0), Color(0xFFFFF3E0)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: coverImage != null && coverImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: coverImage,
                            fit: BoxFit.cover,
                          )
                        : Container(color: AppColors.grey200),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: AppColors.white, size: 12),
                          SizedBox(width: 3),
                          Text(
                            'مميز',
                            style: TextStyle(
                              color: AppColors.white,
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm['name'] ?? '',
                    style: AppText.heading4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(farm['city'] ?? '', style: AppText.small),
                      const Spacer(),
                      Text(
                        '${farm['price_per_night']} د.أ/ليلة',
                        style: AppText.smallBold
                            .copyWith(color: AppColors.goldDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
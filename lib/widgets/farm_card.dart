import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/favorites_provider.dart';

class FarmCard extends StatelessWidget {
  final Map<String, dynamic> farm;
  final VoidCallback onTap;
  final bool compact;

  const FarmCard({
    super.key,
    required this.farm,
    required this.onTap,
    this.compact = false,
  });

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://hajez.esnaad-sa.com$url';
  }

  bool get _isFeatured {
    if (farm['is_featured'] != true) return false;
    final until = farm['featured_until'];
    if (until == null) return true;
    try {
      return DateTime.parse(until.toString()).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'chalet':
        return 'شاليه';
      case 'villa':
        return 'فيلا';
      case 'resort':
        return 'منتجع';
      default:
        return 'مزرعة';
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'chalet':
        return Icons.cottage_outlined;
      case 'villa':
        return Icons.villa_outlined;
      case 'resort':
        return Icons.spa_outlined;
      default:
        return Icons.agriculture_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use cached average_rating and reviews_count from server
    final avgRating =
        (farm['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewsCount = (farm['reviews_count'] as int?) ?? 0;

    // Fallback: calculate from local reviews if server values are 0
    final reviews = farm['reviews'] as List? ?? [];
    final localAvg = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (s, r) => s + (r['rating'] ?? 0)) /
            reviews.length;
    final displayRating = avgRating > 0 ? avgRating : localAvg;
    final displayCount = reviewsCount > 0 ? reviewsCount : reviews.length;

    // Use is_favorited from API when available
    final serverFav = farm['is_favorited'] as bool?;

    final images = farm['images'] as List? ?? [];
    final rawCover = farm['cover_image'] ??
        (images.isNotEmpty ? images[0]['image_path'] : null);
    final coverImage =
        rawCover != null ? _fixUrl(rawCover.toString()) : null;

    return Consumer<FavoritesProvider>(
      builder: (_, fav, __) {
        final isFav = serverFav ?? fav.isFavorite(farm['id']);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: _isFeatured
                  ? Border.all(color: AppColors.gold, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: _isFeatured
                      ? AppColors.shadowPrimary
                      : AppColors.shadowDark,
                  blurRadius: _isFeatured ? 20 : 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl)),
                      child: AspectRatio(
                        aspectRatio: compact ? 1.6 : 1.4,
                        child: coverImage != null && coverImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: coverImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.grey200,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                    ),
                    // Featured badge
                    if (_isFeatured)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.gold, AppColors.goldDark],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadius.xl - 1),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: AppColors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'مميز',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Type badge
                    Positioned(
                      top: _isFeatured ? 32 : 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(0.85),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_typeIcon(farm['type']),
                                color: AppColors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              _typeLabel(farm['type']),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Price badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${farm['price_per_night']}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'د.أ',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.grey500,
                              ),
                            ),
                            const Text(
                              '/ليلة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: _isFeatured ? 32 : 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => fav.toggle(farm['id']),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFav
                                ? AppColors.error
                                : AppColors.grey500,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.92),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              displayRating > 0
                                  ? displayRating
                                      .toStringAsFixed(1)
                                  : 'جديد',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: AppColors.dark,
                              ),
                            ),
                            if (displayCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '($displayCount)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Cairo',
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Content Section
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              farm['name'] ?? '',
                              style: AppText.heading3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (farm['is_verified'] == true)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.verified,
                                  color: AppColors.success, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(farm['city'] ?? '', style: AppText.small),
                          const Spacer(),
                          const Icon(Icons.people_outline_rounded,
                              size: 14, color: AppColors.grey500),
                          const SizedBox(width: 3),
                          Text(
                            'حتى ${farm['capacity']} شخص',
                            style: AppText.small,
                          ),
                        ],
                      ),
                      if (farm['has_pool'] == true) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.infoLight,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.full),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pool,
                                      size: 12, color: AppColors.info),
                                  SizedBox(width: 4),
                                  Text(
                                    'مسبح',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Cairo',
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if ((farm['amenities'] as List? ?? [])
                                .isNotEmpty)
                              ...((farm['amenities'] as List)
                                  .take(2)
                                  .map((a) => Container(
                                        margin: const EdgeInsets.only(
                                            left: 8),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.grey100,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppRadius.full),
                                        ),
                                        child: Text(
                                          a['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'Cairo',
                                            color:
                                                AppColors.darkSecondary,
                                          ),
                                        ),
                                      ))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: AppColors.grey200,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined,
                size: 48, color: AppColors.grey300),
            SizedBox(height: 8),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                color: AppColors.grey500,
                fontFamily: 'Cairo',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
}

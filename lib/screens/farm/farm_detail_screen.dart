import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../services/farm_service.dart';
import '../../providers/favorites_provider.dart';
import '../booking/booking_screen.dart';

class FarmDetailScreen extends StatefulWidget {
  final int farmId;
  const FarmDetailScreen({super.key, required this.farmId});

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  Map<String, dynamic>? _farm;
  bool _loading = true;
  int _currentImage = 0;
  bool _submittingReport = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final res = await FarmService.getFarm(widget.farmId);
      if (mounted) {
        setState(() {
          _farm = res;
          _loading = false;
          // Sync favorite state from API
          if (res['is_favorited'] == true) {
            context
                .read<FavoritesProvider>()
                .favoriteIds
                .add(widget.farmId);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$BASE_URL${url.startsWith('/') ? '' : '/'}$url';
  }

  void _openWhatsApp() async {
    final phone = _farm?['whatsapp'] ?? '';
    if (phone.isEmpty) return;
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) launchUrl(Uri.parse(url));
  }

  void _openMaps() async {
    final lat = _farm?['latitude'];
    final lng = _farm?['longitude'];
    if (lat == null || lng == null) return;
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(mapsUrl))) {
      launchUrl(Uri.parse(mapsUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  void _showReportDialog() {
    final reasons = [
      {'value': 'inappropriate_content', 'label': 'محتوى غير لائق', 'icon': Icons.block_outlined},
      {'value': 'wrong_info', 'label': 'معلومات غير صحيحة', 'icon': Icons.info_outline_rounded},
      {'value': 'scam', 'label': 'احتيال أو نصب', 'icon': Icons.warning_amber_rounded},
      {'value': 'other', 'label': 'سبب آخر', 'icon': Icons.more_horiz},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) {
        String? selectedReason;
        final descCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('الإبلاغ عن هذه المزرعة',
                    style: AppText.heading3),
                const SizedBox(height: 4),
                Text('اختر سبب الإبلاغ لمساعدتنا في تحسين المنصة',
                    style: AppText.bodyGrey),
                const SizedBox(height: 20),
                ...reasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedReason = r['value'] as String),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedReason == r['value']
                                ? AppColors.errorLight
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(
                                AppRadius.lg),
                            border: Border.all(
                              color: selectedReason == r['value']
                                  ? AppColors.error
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(r['icon'] as IconData,
                                  color: selectedReason == r['value']
                                      ? AppColors.error
                                      : AppColors.grey500,
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(r['label'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: selectedReason == r['value']
                                          ? AppColors.error
                                          : AppColors.dark,
                                    )),
                              ),
                              if (selectedReason == r['value'])
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.error,
                                    size: 20),
                            ],
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'تفاصيل إضافية (اختياري)...',
                    hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.grey500),
                    prefixIcon: Icon(Icons.edit_note_outlined,
                        color: AppColors.grey500),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (selectedReason != null &&
                            !_submittingReport)
                        ? () async {
                            setModalState(
                                () => _submittingReport = true);
                            try {
                              await FarmService.submitReport(
                                reportableType: 'Farm',
                                reportableId: widget.farmId,
                                reason: selectedReason!,
                                description:
                                    descCtrl.text.isNotEmpty
                                        ? descCtrl.text
                                        : null,
                              );
                              Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: const Text(
                                    'تم إرسال البلاغ بنجاح',
                                    style: TextStyle(
                                        fontFamily: 'Cairo'),
                                  ),
                                  backgroundColor:
                                      AppColors.success,
                                  behavior:
                                      SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.lg),
                                  ),
                                ));
                              }
                            } catch (_) {
                              setModalState(
                                  () => _submittingReport = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: const Text(
                                    'تعذر إرسال البلاغ',
                                    style: TextStyle(
                                        fontFamily: 'Cairo'),
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior:
                                      SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.lg),
                                  ),
                                ));
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    ),
                    child: _submittingReport
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('إرسال البلاغ'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllReviews(List<dynamic> allReviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const Text('جميع التقييمات',
                            style: AppText.heading3),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 18, color: AppColors.dark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: allReviews.length,
                  itemBuilder: (_, i) =>
                      _buildReviewCard(allReviews[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(dynamic r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySurface,
                radius: 20,
                child: Text(
                  (r['user']?['name'] ?? 'م')[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['is_anonymous'] == true
                          ? 'مستخدم مجهول'
                          : (r['user']?['name'] ?? ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 13,
                          color:
                              i < (r['rating'] ?? 0)
                                  ? AppColors.gold
                                  : AppColors.grey300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Sub-ratings
          if (r['cleanliness_rating'] != null ||
              r['service_rating'] != null ||
              r['value_rating'] != null ||
              r['location_rating'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  if (r['cleanliness_rating'] != null)
                    _subRatingBar(
                        'النظافة',
                        (r['cleanliness_rating'] as num)
                            .toDouble()),
                  if (r['service_rating'] != null) ...[
                    const SizedBox(height: 6),
                    _subRatingBar(
                        'الخدمة',
                        (r['service_rating'] as num)
                            .toDouble()),
                  ],
                  if (r['value_rating'] != null) ...[
                    const SizedBox(height: 6),
                    _subRatingBar(
                        'القيمة مقابل السعر',
                        (r['value_rating'] as num).toDouble()),
                  ],
                  if (r['location_rating'] != null) ...[
                    const SizedBox(height: 6),
                    _subRatingBar(
                        'الموقع',
                        (r['location_rating'] as num)
                            .toDouble()),
                  ],
                ],
              ),
            ),
          ],
          if (r['comment'] != null &&
              r['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r['comment'].toString(),
              style: AppText.body.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _subRatingBar(String label, double value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppText.caption),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 5,
              backgroundColor: AppColors.grey200,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(1),
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    if (_farm == null)
      return const Scaffold(
        body: Center(
          child: Text(
            'حدث خطأ',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );

    final rawImages = [
      if (_farm!['cover_image'] != null)
        _fixUrl(_farm!['cover_image'].toString()),
      ...(_farm!['images'] as List? ?? [])
          .map((i) => _fixUrl(i['image_path']?.toString()))
          .where((u) => u.isNotEmpty),
    ].toSet().toList();

    final reviews = _farm!['reviews'] as List? ?? [];

    // Use cached rating stats from API
    final avgRating =
        (_farm!['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewsCount =
        (_farm!['reviews_count'] as int?) ?? reviews.length;

    final amenities = _farm!['amenities'] as List? ?? [];
    final double? lat = _farm!['latitude'] != null
        ? double.tryParse(_farm!['latitude'].toString())
        : null;
    final double? lng = _farm!['longitude'] != null
        ? double.tryParse(_farm!['longitude'].toString())
        : null;
    final hasLocation = lat != null && lng != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Image Gallery
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.dark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Consumer<FavoritesProvider>(
                builder: (_, fav, __) => Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      fav.isFavorite(widget.farmId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: fav.isFavorite(widget.farmId)
                          ? AppColors.error
                          : AppColors.dark,
                    ),
                    onPressed: () => fav.toggle(widget.farmId),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (rawImages.isNotEmpty)
                    PageView.builder(
                      itemCount: rawImages.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImage = i),
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: rawImages[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppColors.grey200),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.grey200,
                          child: const Icon(
                            Icons.home_work_outlined,
                            size: 60,
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(Icons.home_work_outlined,
                            size: 80, color: AppColors.grey500),
                      ),
                    ),
                  // Page indicators
                  if (rawImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          rawImages.length,
                          (i) => AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 250),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImage == i ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImage == i
                                  ? AppColors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Image counter
                  if (rawImages.length > 1)
                    Positioned(
                      top: 80,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${_currentImage + 1}/${rawImages.length}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Price tag
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_farm!['price_per_night']}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'د.أ/ليلة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.grey500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + WhatsApp
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _farm!['name'] ?? '',
                          style: AppText.heading1,
                        ),
                      ),
                      if (_farm!['whatsapp'] != null)
                        GestureDetector(
                          onTap: _openWhatsApp,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.whatsapp.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.lg),
                            ),
                            child: const Icon(
                              Icons.chat_outlined,
                              color: AppColors.whatsapp,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${_farm!['city']} · ${_farm!['address']}',
                        style: AppText.bodyGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Row(
                      children: [
                        _infoChip(
                          Icons.star_rounded,
                          avgRating > 0
                              ? avgRating.toStringAsFixed(1)
                              : 'جديد',
                          AppColors.gold,
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppColors.grey200),
                        _infoChip(
                          Icons.people_outline,
                          'حتى ${_farm!['capacity']}',
                          AppColors.primary,
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: AppColors.grey200),
                        _infoChip(
                          Icons.login_outlined,
                          'دخول ${_farm!['check_in_time']?.toString().substring(0, 5) ?? ''}',
                          AppColors.secondary,
                        ),
                      ],
                    ),
                  ),

                  // Verified badge
                  if (_farm!['is_verified'] == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 6),
                          Text(
                            'مزرعة موثقة',
                            style: TextStyle(
                              color: AppColors.success,
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Description
                  const Text('عن المزرعة', style: AppText.heading3),
                  const SizedBox(height: 8),
                  Text(
                    _farm!['description'] ?? '',
                    style: AppText.body.copyWith(height: 1.7),
                  ),

                  // Rules
                  if (_farm!['rules'] != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.rule_rounded,
                                  color: AppColors.warning,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('قواعد المزرعة',
                                  style: AppText.heading4),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _farm!['rules']!,
                            style:
                                AppText.body.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Amenities
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('المرافق والخدمات',
                        style: AppText.heading3),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: amenities
                          .map((a) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius
                                      .circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      a['name'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  // Map
                  if (hasLocation) ...[
                    const SizedBox(height: 24),
                    const Text('الموقع', style: AppText.heading3),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.xl),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(lat!, lng!),
                            initialZoom: 14,
                            interactionOptions:
                                const InteractiveFlag.none,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.hajez.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(lat, lng),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: AppColors.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openMaps,
                            icon: const Icon(Icons.map_outlined,
                                size: 18),
                            label: const Text('Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openMaps,
                            icon: const Icon(
                                Icons.navigation_outlined,
                                size: 18),
                            label: const Text('Waze'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(
                                  color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Reviews
                  if (reviews.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('التقييمات',
                            style: AppText.heading3),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.gold),
                              const SizedBox(width: 3),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                              Text(
                                ' ($reviewsCount)',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.grey500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...reviews.take(3).map((r) => _buildReviewCard(r)),

                    // See All Reviews button
                    if (reviews.length > 3) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              _showAllReviews(reviews),
                          icon: const Icon(
                              Icons.reviews_outlined,
                              size: 16),
                          label: Text(
                            'عرض كل التقييمات ($reviewsCount)',
                            style: AppText.smallBold,
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Report button
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: _showReportDialog,
                      icon: const Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: AppColors.grey500,
                      ),
                      label: const Text(
                        'الإبلاغ عن هذه المزرعة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('السعر لليلة', style: AppText.caption),
                Text(
                  '${_farm!['price_per_night']} د.أ',
                  style: AppText.price,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingScreen(farm: _farm!),
                    ),
                  ),
                  child: const Text('احجز الآن'),
                ),
              ),
            ),
            if (_farm!['whatsapp'] != null) ...[
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.whatsapp,
                  borderRadius:
                      BorderRadius.circular(AppRadius.lg),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat,
                      color: AppColors.white),
                  onPressed: _openWhatsApp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.darkSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
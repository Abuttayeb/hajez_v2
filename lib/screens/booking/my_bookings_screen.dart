import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/shimmer_cards.dart';
import '../../widgets/state_views.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<BookingProvider>().loadMyBookings();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حجوزاتي'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'قادمة (${prov.pendingBookings.length})'),
            Tab(text: 'مكتملة (${prov.completedBookings.length})'),
            Tab(text: 'ملغية (${prov.cancelledBookings.length})'),
          ],
        ),
      ),
      body: prov.isLoading
          ? ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const _BookingShimmer())
          : prov.error != null
              ? ErrorView(message: prov.error!, onRetry: prov.retry)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => prov.loadMyBookings(),
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(prov.pendingBookings),
                      _buildList(prov.completedBookings),
                      _buildList(prov.cancelledBookings),
                    ],
                  ),
                ),
    );
  }

  Widget _buildList(List<dynamic> bookings) {
    if (bookings.isEmpty) return const EmptyView(message: 'لا توجد حجوزات', icon: Icons.bookmark_outline_rounded);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _BookingCard(
        booking: bookings[i],
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: bookings[i]['id'])));
          context.read<BookingProvider>().loadMyBookings();
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.onTap});

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://hajez.esnaad-sa.com$url';
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final statusMap = {
      'pending': {'label': 'قيد المراجعة', 'color': AppColors.warning, 'bg': AppColors.warningLight, 'icon': Icons.schedule},
      'confirmed': {'label': 'مؤكد', 'color': AppColors.success, 'bg': AppColors.successLight, 'icon': Icons.check_circle_outline},
      'cancelled': {'label': 'ملغي', 'color': AppColors.error, 'bg': AppColors.errorLight, 'icon': Icons.cancel_outlined},
      'completed': {'label': 'مكتمل', 'color': AppColors.primary, 'bg': AppColors.primarySurface, 'icon': Icons.task_alt},
    };
    final sc = statusMap[status] ?? statusMap['pending']!;
    final farm = booking['farm'] ?? {};
    final images = farm['images'] as List? ?? [];
    final rawCover = farm['cover_image'] ?? (images.isNotEmpty ? images[0]['image_path'] : null);
    final coverImage = rawCover != null ? _fixUrl(rawCover.toString()) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: [BoxShadow(color: AppColors.shadowDark, blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: [
          if (coverImage != null && coverImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              child: CachedNetworkImage(imageUrl: coverImage, height: 120, width: double.infinity, fit: BoxFit.cover, placeholder: (_, __) => Container(height: 120, color: AppColors.grey200)),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(farm['name'] ?? '', style: AppText.heading4, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: (sc['bg'] as Color), borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(sc['icon'] as IconData, size: 13, color: sc['color'] as Color),
                    const SizedBox(width: 4),
                    Text(sc['label'] as String, style: TextStyle(color: sc['color'] as Color, fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text('${booking['check_in']} → ${booking['check_out']}', style: AppText.small),
                const Spacer(),
                Text('${booking['total_price']} د.أ', style: AppText.price.copyWith(fontSize: 15)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BookingShimmer extends StatelessWidget {
  const _BookingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(children: [
        Container(height: 120, color: AppColors.grey200, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
        const Padding(
          padding: EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 16, width: 200, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(4)))),
            SizedBox(height: 10),
            SizedBox(height: 12, width: 140, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(4)))),
          ]),
        ),
      ]),
    );
  }
}
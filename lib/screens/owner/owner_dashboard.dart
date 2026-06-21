import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/farm_service.dart';
import 'add_farm_screen.dart';
import 'my_farms_screen.dart';
import 'owner_bookings_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  List<dynamic> _farms = [];
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _loading = true);
    try {
      // getMyFarms() and getOwnerBookings() return paginated Maps
      final farmsRes = await FarmService.getMyFarms();
      final bookingsRes = await FarmService.getOwnerBookings();
      setState(() {
        _farms = (farmsRes['data'] as List?) ?? [];
        _bookings = (bookingsRes['data'] as List?) ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        _bookings.where((b) => b['status'] == 'pending').length;
    final confirmed =
        _bookings.where((b) => b['status'] == 'confirmed').length;
    final revenue = _bookings
        .where((b) => b['status'] == 'completed')
        .fold<double>(0, (s, b) => s + (b['total_price'] as num).toDouble());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة المالك'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    Row(
                      children: [
                        _statCard(
                          'مزارعي',
                          '${_farms.length}',
                          Icons.agriculture_outlined,
                          AppColors.primary,
                          AppColors.primarySurface,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'طلبات جديدة',
                          '$pending',
                          Icons.pending_actions,
                          AppColors.warning,
                          AppColors.warningLight,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'الإيرادات',
                          '${revenue.toStringAsFixed(0)}',
                          Icons.attach_money_rounded,
                          AppColors.success,
                          AppColors.successLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text('إجراءات سريعة', style: AppText.heading4),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            Icons.add_circle_outline,
                            'إضافة مزرعة',
                            AppColors.primary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddFarmScreen()),
                            ).then((_) => _load()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionCard(
                            Icons.list_alt_outlined,
                            'مزارعي',
                            AppColors.secondary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MyFarmsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionCard(
                            Icons.book_online_outlined,
                            'الحجوزات',
                            AppColors.info,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const OwnerBookingsScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Summary row
                    if (confirmed > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: AppColors.success,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'أداء جيد!',
                                    style: AppText.heading4.copyWith(
                                        color: AppColors.success),
                                  ),
                                  Text(
                                    'لديك $confirmed حجز مؤكد و $pending طلب بانتظار المراجعة',
                                    style: AppText.small.copyWith(
                                        color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Recent Bookings
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('أحدث الطلبات',
                            style: AppText.heading4),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const OwnerBookingsScreen()),
                          ),
                          child: Text(
                            'عرض الكل',
                            style: AppText.smallBold.copyWith(
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    ..._bookings
                        .where((b) => b['status'] == 'pending')
                        .take(4)
                        .map((b) => _bookingItem(b)),
                    if (_bookings
                        .where((b) => b['status'] == 'pending')
                        .isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 48,
                                color: AppColors.success,
                              ),
                              SizedBox(height: 12),
                              Text('لا توجد طلبات جديدة',
                                  style: AppText.bodyGrey),
                              Text('كل شيء على ما يرام!',
                                  style: AppText.small),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
          Color bgColor) =>
      Expanded(
        child: Container(
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.grey500,
                  fontFamily: 'Cairo',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _actionCard(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _bookingItem(Map<String, dynamic> b) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primarySurface,
              radius: 22,
              child: Text(
                (b['user']?['name'] ?? 'م')[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['user']?['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    '${b['check_in']} ← ${b['check_out']}',
                    style: AppText.small,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${b['total_price']} د.أ',
                  style: AppText.price.copyWith(fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text(
                    'قيد المراجعة',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

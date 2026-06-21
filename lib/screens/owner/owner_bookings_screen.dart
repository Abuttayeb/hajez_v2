import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/farm_service.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() async {
    setState(() => _loading = true);
    try {
      final res = await FarmService.getOwnerBookings();
      setState(() {
        _bookings = (res['data'] as List?) ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://hajez.esnaad-sa.com$url';
  }

  List<dynamic> get _pending =>
      _bookings.where((b) => b['status'] == 'pending').toList();
  List<dynamic> get _confirmed =>
      _bookings.where((b) => b['status'] == 'confirmed').toList();
  List<dynamic> get _other => _bookings
      .where((b) => ['cancelled', 'completed'].contains(b['status']))
      .toList();

  void _updateStatus(int id, String status,
      {String? rejectionReason}) async {
    await FarmService.updateBookingStatus(id, status,
        rejectionReason: rejectionReason);
    _load();
  }

  void _rejectWithReason(int id) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: const Text(
          'سبب الرفض',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'أدخل سبب الرفض',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text(
              'رفض',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
    if (reason != null) {
      _updateStatus(id, 'cancelled', rejectionReason: reason);
    }
  }

  Widget _statusBadge(String status) {
    final map = {
      'pending': ['قيد المراجعة', AppColors.warning],
      'confirmed': ['مؤكد', AppColors.success],
      'cancelled': ['ملغي', AppColors.error],
      'completed': ['مكتمل', AppColors.primary],
    };
    final c = map[status] ?? ['', AppColors.grey500];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (c[1] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        c[0] as String,
        style: TextStyle(
          color: c[1] as Color,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الحجوزات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: 'جديد (${_pending.length})'),
            Tab(text: 'مؤكد (${_confirmed.length})'),
            Tab(text: 'الكل (${_bookings.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_pending, showActions: true),
                _buildList(_confirmed),
                _buildList(_bookings),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> list, {bool showActions = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.grey500,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد حجوزات',
              style: TextStyle(
                color: AppColors.grey500,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final b = list[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info + price
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    radius: 22,
                    child: Text(
                      (b['user']?['name'] ?? 'م')[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['user']?['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          b['user']?['phone'] ?? '',
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
                      const SizedBox(height: 4),
                      _statusBadge(b['status']),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              // Farm name
              Row(
                children: [
                  const Icon(Icons.home_work_outlined,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(b['farm']?['name'] ?? '', style: AppText.small),
                ],
              ),
              const SizedBox(height: 4),
              // Dates and guests
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '${b['check_in']} ← ${b['check_out']}',
                    style: AppText.small,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.people_outline,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '${b['guests']} أشخاص',
                    style: AppText.small,
                  ),
                ],
              ),
              // Rejection reason if exists
              if (b['rejection_reason'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b['rejection_reason'],
                          style: AppText.small.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Action buttons for pending bookings
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(b['id'], 'confirmed'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('تأكيد'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectWithReason(b['id']),
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.error),
                        label: const Text(
                          'رفض',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

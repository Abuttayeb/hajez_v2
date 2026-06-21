import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../services/farm_service.dart';
import '../widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await FarmService.getNotifications();
      final data = res['notifications']?['data'] as List? ?? [];
      final count = res['unread_count'] ?? 0;
      if (mounted) {
        setState(() {
          _notifications = data;
          _unreadCount = count as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await FarmService.markAllRead();
    setState(() {
      for (var n in _notifications) { n['is_read'] = true; }
      _unreadCount = 0;
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking_created': return Icons.calendar_today_outlined;
      case 'booking_confirmed': return Icons.check_circle_outline;
      case 'booking_cancelled': return Icons.cancel_outlined;
      case 'booking_completed': return Icons.task_alt_outlined;
      case 'review_added': case 'review_approved': return Icons.star_outline;
      case 'farm_approved': return Icons.verified_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking_created': return AppColors.primary;
      case 'booking_confirmed': return AppColors.success;
      case 'booking_cancelled': return AppColors.error;
      case 'booking_completed': return const Color(0xFF6A1B9A);
      case 'review_added': case 'review_approved': return AppColors.gold;
      case 'farm_approved': return const Color(0xFF2E7D32);
      default: return AppColors.grey500;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('تحديد الكل كمقروء', style: AppText.smallBold.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? const EmptyView(message: 'لا توجد إشعارات', icon: Icons.notifications_none_rounded)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i] as Map<String, dynamic>;
                      final isRead = n['is_read'] == true;
                      final type = n['type'] as String? ?? 'general';
                      final color = _colorForType(type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? AppColors.white : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: isRead ? null : Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.lg)),
                              child: Icon(_iconForType(type), color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(n['title'] as String? ?? '', style: AppText.heading4)),
                                      if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(n['body'] as String? ?? '', style: AppText.bodyGrey.copyWith(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Text(_timeAgo(n['created_at']?.toString()), style: AppText.caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
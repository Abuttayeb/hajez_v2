import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/farm_service.dart';
import '../owner/owner_dashboard.dart';
import '../owner/my_farms_screen.dart';
import '../owner/owner_bookings_screen.dart';
import '../favorites_screen.dart';
import '../notifications_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _notificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await FarmService.getUnreadCount();
      final count = (res['unread_count'] ?? 0) as int;
      if (mounted) setState(() => _notificationsCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.isOwner;
    final name = auth.user?['name'] ?? '';
    final email = auth.user?['email'] ?? '';
    final initial = name.isNotEmpty ? name[0] : 'م';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Profile Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxl)),
              ),
              child: Column(children: [
                CircleAvatar(radius: 44, backgroundColor: Colors.white24, child: Text(initial, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.white, fontFamily: 'Cairo'))),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isOwner ? Icons.home_work_outlined : Icons.person_outline, color: AppColors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(isOwner ? 'مالك مزرعة' : 'زبون', style: const TextStyle(color: AppColors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Owner Section
            if (isOwner) ...[
              _section('لوحة التحكم', [
                _tile(Icons.dashboard_outlined, 'لوحة تحكم المالك', 'إحصائيات وتحكم شامل', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()))),
                _tile(Icons.agriculture_outlined, 'مزارعي', 'إضافة وتعديل المزارع', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFarmsScreen()))),
                _tile(Icons.book_online_outlined, 'طلبات الحجز', 'تأكيد وإدارة الحجوزات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerBookingsScreen()))),
              ]),
              const SizedBox(height: 12),
            ],

            // Account Section
            _section('الحساب', [
              _tile(Icons.person_outline, 'تعديل الملف الشخصي', 'الاسم والجوال وكلمة المرور', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              _tile(Icons.favorite_outline, 'المفضلة', 'الأماكن المحفوظة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
              _tile(Icons.notifications_outlined, 'الإشعارات', _notificationsCount > 0 ? '$_notificationsCount إشعارات جديدة' : null, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _loadUnreadCount());
              }, badge: _notificationsCount),
              _tile(Icons.help_outline, 'المساعدة والدعم', null, () {}),
              _tile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', null, () {}),
              _tile(Icons.info_outline, 'عن حاجز', 'الإصدار 2.0.0', () {}),
            ]),
            const SizedBox(height: 12),

            // Logout
            Container(
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
              child: ListTile(
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppRadius.md)), child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18)),
                title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey500),
                onTap: () async {
                  final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
                    title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
                    content: const Text('هل أنت متأكد؟', style: TextStyle(fontFamily: 'Cairo')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
                    ],
                  ));
                  if (confirm == true) {
                    await auth.logout();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('حاجز v2.0.0 — صُنع بـ ❤️ في الأردن', style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(bottom: 8, right: 4), child: Text(title, style: AppText.smallBold)),
      Container(
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(children: items),
      ),
    ],
  );

  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap, {int badge = 0}) => ListTile(
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(icon, color: AppColors.primary, size: 18)),
    title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
    subtitle: subtitle != null ? Text(subtitle, style: AppText.caption) : null,
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      if (badge > 0) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)), child: Text('$badge', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700))),
      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey500),
    ]),
    onTap: onTap,
  );
}
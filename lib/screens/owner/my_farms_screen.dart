import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../services/farm_service.dart';
import 'add_farm_screen.dart';

class MyFarmsScreen extends StatefulWidget {
  const MyFarmsScreen({super.key});

  @override
  State<MyFarmsScreen> createState() => _MyFarmsScreenState();
}

class _MyFarmsScreenState extends State<MyFarmsScreen> {
  List<dynamic> _farms = [];
  bool _loading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await FarmService.getMyFarms();
      setState(() {
        _farms = (res['data'] as List?) ?? [];
        _currentPage = (res['current_page'] as int?) ?? 1;
        _lastPage = (res['last_page'] as int?) ?? 1;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await FarmService.getMyFarms(page: nextPage);
      final data = (res['data'] as List?) ?? [];
      setState(() {
        _farms.addAll(data);
        _currentPage = (res['current_page'] as int?) ?? nextPage;
        _lastPage = (res['last_page'] as int?) ?? _lastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://hajez.esnaad-sa.com$url';
  }

  void _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: const Text(
          'حذف المزرعة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه المزرعة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(
                color: AppColors.error,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FarmService.deleteFarm(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مزارعي'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFarmScreen()),
        ).then((_) => _load()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'إضافة مزرعة',
          style: TextStyle(color: AppColors.white, fontFamily: 'Cairo'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _farms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.agriculture_outlined,
                          size: 80, color: AppColors.grey400),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد مزارع بعد',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddFarmScreen()),
                        ).then((_) => _load()),
                        icon: const Icon(Icons.add),
                        label: const Text('أضف مزرعتك الأولى'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
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
                      final coverUrl = _fixUrl(f['cover_image']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                            if (f['cover_image'] != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.xl)),
                                child: coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            Container(
                                          height: 140,
                                          color: AppColors.grey200,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            Container(
                                          height: 140,
                                          color: AppColors.grey200,
                                          child: const Icon(
                                            Icons.home_work_outlined,
                                            size: 40,
                                            color: AppColors.grey400,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 140,
                                        color: AppColors.grey200,
                                        child: const Icon(
                                          Icons.home_work_outlined,
                                          size: 40,
                                          color: AppColors.grey400,
                                        ),
                                      ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(f['name'] ?? '',
                                            style: AppText.heading3),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.location_on_rounded,
                                                size: 13,
                                                color:
                                                    AppColors.primary),
                                            Text(f['city'] ?? '',
                                                style: AppText.small),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${f['price_per_night']} د.أ/ليلة',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontFamily: 'Cairo',
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit,
                                                color:
                                                    AppColors.primary,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text('تعديل',
                                                style: TextStyle(
                                                    fontFamily: 'Cairo')),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color:
                                                    AppColors.error,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text('حذف',
                                                style: TextStyle(
                                                    fontFamily: 'Cairo')),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (v) {
                                      if (v == 'edit')
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddFarmScreen(farm: f),
                                          ),
                                        ).then((_) => _load());
                                      else if (v == 'delete')
                                        _delete(f['id']);
                                    },
                                  ),
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

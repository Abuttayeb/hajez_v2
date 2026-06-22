import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic> filters;
  const FilterScreen({super.key, required this.filters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String _type = '';
  bool _hasPool = false;
  RangeValues _priceRange = const RangeValues(0, 500);
  int _capacity = 0;

  @override
  void initState() {
    super.initState();
    _type = widget.filters['type'] ?? '';
    _hasPool = widget.filters['has_pool'] ?? false;
    _priceRange = RangeValues(widget.filters['min_price']?.toDouble() ?? 0, widget.filters['max_price']?.toDouble() ?? 500);
    _capacity = widget.filters['capacity'] ?? 0;
  }

  void _apply() {
    final filters = <String, dynamic>{};
    // Preserve category_id from home screen selection
    if (widget.filters['category_id'] != null) {
      filters['category_id'] = widget.filters['category_id'];
    }
    if (_type.isNotEmpty) filters['type'] = _type;
    if (_hasPool) filters['has_pool'] = true;
    if (_priceRange.start > 0) filters['min_price'] = _priceRange.start;
    if (_priceRange.end < 500) filters['max_price'] = _priceRange.end;
    if (_capacity > 0) filters['capacity'] = _capacity;
    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('فلترة النتائج'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [TextButton(onPressed: () => Navigator.pop(context, {}), child: Text('مسح الكل', style: AppText.smallBold.copyWith(color: AppColors.primary)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('نوع المكان', style: AppText.heading4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                {'value': '', 'label': 'الكل', 'icon': Icons.apps_rounded},
                {'value': 'farm', 'label': 'مزرعة', 'icon': Icons.agriculture_outlined},
                {'value': 'chalet', 'label': 'شاليه', 'icon': Icons.cottage_outlined},
                {'value': 'villa', 'label': 'فيلا', 'icon': Icons.villa_outlined},
                {'value': 'resort', 'label': 'منتجع', 'icon': Icons.spa_outlined},
              ].map((t) => GestureDetector(
                onTap: () => setState(() => _type = t['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _type == t['value'] ? AppColors.primary : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: _type == t['value'] ? null : Border.all(color: AppColors.grey200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t['icon'] as IconData, size: 16, color: _type == t['value'] ? AppColors.white : AppColors.darkSecondary),
                    const SizedBox(width: 6),
                    Text(t['label'] as String, style: TextStyle(color: _type == t['value'] ? AppColors.white : AppColors.dark, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  ]),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            // Pool
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(AppRadius.md)), child: const Icon(Icons.pool, color: Color(0xFF1565C0))),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('يوجد مسبح', style: AppText.heading4),
                      Text('عرض الأماكن التي تحتوي مسبح', style: AppText.caption),
                    ]),
                  ]),
                  Switch(value: _hasPool, onChanged: (v) => setState(() => _hasPool = v), activeColor: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Price
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('نطاق السعر', style: AppText.heading4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text('${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} د.أ', style: AppText.smallBold.copyWith(color: AppColors.primary)),
                ),
              ]),
              const SizedBox(height: 16),
              RangeSlider(values: _priceRange, min: 0, max: 500, divisions: 50, activeColor: AppColors.primary, onChanged: (v) => setState(() => _priceRange = v)),
            ]),
            const SizedBox(height: 24),
            // Capacity
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الحد الأدنى للأشخاص', style: AppText.heading4),
                Text('عدد الأشخاص المطلوب', style: AppText.caption),
              ]),
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.grey200), borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.remove, size: 18, color: AppColors.primary), onPressed: () { if (_capacity > 0) setState(() => _capacity -= 5); }),
                  Container(width: 48, alignment: Alignment.center, child: Text('$_capacity', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 18))),
                  IconButton(icon: const Icon(Icons.add, size: 18, color: AppColors.primary), onPressed: () => setState(() => _capacity += 5)),
                ]),
              ),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(onPressed: _apply, child: const Text('تطبيق الفلاتر')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../utils/app_theme.dart';
import '../../services/farm_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic>? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _loading = true);
    try {
      final res = await FarmService.getBooking(widget.bookingId);
      setState(() => _booking = res);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: const Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من إلغاء هذا الحجز؟',
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
              'نعم',
              style: TextStyle(color: AppColors.error, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FarmService.cancelBooking(widget.bookingId);
      _load();
    }
  }

  void _addReview() {
    int rating = 5;
    double cleanliness = 5, service = 5, value = 5, location = 5;
    bool isAnonymous = false;
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('أضف تقييمك', style: AppText.heading2),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                itemCount: 5,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star_rounded, color: AppColors.gold),
                onRatingUpdate: (r) => setSheet(() => rating = r.toInt()),
              ),
              const SizedBox(height: 20),
              // Sub-ratings
              _subRatingSlider('النظافة', cleanliness,
                  (v) => setSheet(() => cleanliness = v), setSheet),
              const SizedBox(height: 8),
              _subRatingSlider('الخدمة', service,
                  (v) => setSheet(() => service = v), setSheet),
              const SizedBox(height: 8),
              _subRatingSlider('القيمة مقابل المال', value,
                  (v) => setSheet(() => value = v), setSheet),
              const SizedBox(height: 8),
              _subRatingSlider('الموقع', location,
                  (v) => setSheet(() => location = v), setSheet),
              const SizedBox(height: 16),
              // Anonymous toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تقييم مجهول', style: AppText.body),
                  Switch(
                    value: isAnonymous,
                    onChanged: (v) => setSheet(() => isAnonymous = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'تعليقك (اختياري)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FarmService.addReview(
                      bookingId: widget.bookingId,
                      rating: rating,
                      comment: ctrl.text.isNotEmpty ? ctrl.text : null,
                      cleanliness: cleanliness,
                      service: service,
                      value: value,
                      location: location,
                      isAnonymous: isAnonymous,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      _load();
                    }
                  },
                  child: const Text('إرسال التقييم'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subRatingSlider(
    String label,
    double value,
    Function(double) onChange,
    Function(void Function()) setSheet,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppText.small),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.grey200,
            label: value.toStringAsFixed(1),
            onChanged: onChange,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.toStringAsFixed(1),
            style: AppText.smallBold,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _subRatingDisplay(String label, dynamic value) {
    final val = (value as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.small)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: val / 5,
                minHeight: 6,
                backgroundColor: AppColors.grey200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              val.toStringAsFixed(1),
              style: AppText.smallBold,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_booking == null) {
      return const Scaffold(
        body: Center(
          child: Text('حدث خطأ', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }

    final status = _booking!['status'];
    final farm = _booking!['farm'] ?? {};
    final canCancel = ['pending', 'confirmed'].contains(status);
    final canReview = status == 'completed' && _booking!['review'] == null;
    final hasReview = _booking!['review'] != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل الحجز'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${_booking!['id']}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.grey500,
                          fontSize: 13,
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    farm['name'] ?? '',
                    style: AppText.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farm['city'] ?? '',
                    style: AppText.bodyGrey,
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 24),
                  _row('تاريخ الوصول', _booking!['check_in'] ?? ''),
                  _row('تاريخ المغادرة', _booking!['check_out'] ?? ''),
                  _row('عدد الأشخاص', '${_booking!['guests']} أشخاص'),
                  _row(
                      'طريقة الدفع', _paymentLabel(_booking!['payment_method'])),
                  _row('حالة الدفع',
                      _paymentStatus(_booking!['payment_status'])),
                  if (_booking!['payment'] != null) ...[
                    _row('رقم العملية',
                        _booking!['payment']['transaction_id'] ?? ''),
                    _row('طريقة الدفع',
                        _paymentLabel(_booking!['payment']['method'])),
                  ],
                  const Divider(height: 20),
                  _row('المجموع', '${_booking!['total_price']} د.أ',
                      bold: true),
                ],
              ),
            ),

            // Notes
            if (_booking!['notes'] != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الملاحظات', style: AppText.heading3),
                    const SizedBox(height: 8),
                    Text(_booking!['notes'], style: AppText.body),
                  ],
                ),
              ),
            ],

            // Rejection reason
            if (_booking!['rejection_reason'] != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 6),
                        const Text('سبب الرفض',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _booking!['rejection_reason'],
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
            ],

            // Existing Review Display
            if (hasReview) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border:
                      Border.all(color: AppColors.gold.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 18),
                        SizedBox(width: 6),
                        Text('تقييمك', style: AppText.heading4),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _subRatingDisplay(
                        'النظافة', _booking!['review']['cleanliness_rating']),
                    _subRatingDisplay(
                        'الخدمة', _booking!['review']['service_rating']),
                    _subRatingDisplay(
                        'القيمة', _booking!['review']['value_rating']),
                    _subRatingDisplay(
                        'الموقع', _booking!['review']['location_rating']),
                    if (_booking!['review']['comment'] != null &&
                        (_booking!['review']['comment'] as String)
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        _booking!['review']['comment'],
                        style: AppText.body,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Action Buttons
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.error),
                  label: const Text(
                    'إلغاء الحجز',
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            if (canReview) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addReview,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('أضف تقييمك'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.bodyGrey),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? AppColors.primary : AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _statusBadge(String status) {
    final map = {
      'pending': ['قيد المراجعة', AppColors.warning],
      'confirmed': ['مؤكد', AppColors.success],
      'cancelled': ['ملغي', AppColors.error],
      'completed': ['مكتمل', AppColors.primary],
    };
    final c = map[status] ?? ['', AppColors.grey500];
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: (c[1] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        c[0] as String,
        style: TextStyle(
          color: c[1] as Color,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'cliq':
        return 'CliQ';
      case 'efawateer':
        return 'eFAWATEERcom';
      case 'whatsapp':
        return 'واتساب';
      default:
        return 'كاش عند الوصول';
    }
  }

  String _paymentStatus(String? status) {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'pending':
        return 'بانتظار الدفع';
      case 'failed':
        return 'فشل الدفع';
      case 'refunded':
        return 'مسترد';
      default:
        return status ?? 'كاش عند الوصول';
    }
  }
}

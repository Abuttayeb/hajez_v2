import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/farm_service.dart';
import '../../providers/booking_provider.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> farm;
  const BookingScreen({super.key, required this.farm});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkIn, _checkOut;
  int _guests = 2;
  String _paymentMethod = 'cash';
  String _notes = '';
  bool _checking = false;
  Map<String, dynamic>? _availability;

  // Coupon fields
  String _couponCode = '';
  Map<String, dynamic>? _couponResult;
  bool _validatingCoupon = false;

  void _onDaySelected(DateTime selected, _) {
    setState(() {
      if (_checkIn == null || (_checkIn != null && _checkOut != null)) {
        _checkIn = selected;
        _checkOut = null;
        _availability = null;
        _couponResult = null;
      } else if (selected.isAfter(_checkIn!)) {
        _checkOut = selected;
        _checkAvailability();
        _couponResult = null;
      } else {
        _checkIn = selected;
        _checkOut = null;
        _availability = null;
        _couponResult = null;
      }
    });
  }

  void _checkAvailability() async {
    if (_checkIn == null || _checkOut == null) return;
    setState(() => _checking = true);
    try {
      final res = await FarmService.checkAvailability(
        widget.farm['id'],
        DateFormat('yyyy-MM-dd').format(_checkIn!),
        DateFormat('yyyy-MM-dd').format(_checkOut!),
        guests: _guests,
      );
      setState(() => _availability = res);
    } catch (_) {}
    setState(() => _checking = false);
  }

  Future<void> _validateCoupon() async {
    if (_couponCode.isEmpty) return;
    setState(() => _validatingCoupon = true);
    try {
      final nights = (_checkIn != null && _checkOut != null)
          ? _checkOut!.difference(_checkIn!).inDays
          : 0;
      final price =
          double.tryParse(widget.farm['price_per_night'].toString()) ?? 0;
      final orderAmount = nights * price;
      final res =
          await FarmService.validateCoupon(_couponCode, orderAmount);
      if (mounted) setState(() => _couponResult = res);
    } catch (_) {
      if (mounted) {
        setState(() => _couponResult = {
              'valid': false,
              'message': 'تعذر التحقق من الكود',
            });
      }
    }
    if (mounted) setState(() => _validatingCoupon = false);
  }

  void _book() async {
    if (_checkIn == null || _checkOut == null) {
      _showError('اختر تواريخ الحجز');
      return;
    }
    if (_availability?['available'] == false) {
      _showError('المزرعة غير متاحة');
      return;
    }

    final prov = context.read<BookingProvider>();
    final ok = await prov.createBooking(
      farmId: widget.farm['id'],
      checkIn: DateFormat('yyyy-MM-dd').format(_checkIn!),
      checkOut: DateFormat('yyyy-MM-dd').format(_checkOut!),
      guests: _guests,
      paymentMethod: _paymentMethod,
      notes: _notes.isNotEmpty ? _notes : null,
      couponCode: _couponResult?['valid'] == true ? _couponCode : null,
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
            'تم الحجز بنجاح!',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ));
      } else {
        _showError('حدث خطأ');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: const TextStyle(fontFamily: 'Cairo'),
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final nights = (_checkIn != null && _checkOut != null)
        ? _checkOut!.difference(_checkIn!).inDays
        : 0;
    final price =
        double.tryParse(widget.farm['price_per_night'].toString()) ?? 0.0;

    // Use server total when available, otherwise fall back to local calc
    double serverTotal = 0;
    if (_availability != null && _availability!['available'] == true) {
      serverTotal =
          (_availability!['total_price'] as num?)?.toDouble() ?? 0.0;
    }
    final displayTotal = serverTotal > 0 ? serverTotal : nights * price;

    // Apply coupon discount
    double discountAmount = 0;
    if (_couponResult != null &&
        _couponResult!['valid'] == true &&
        serverTotal > 0) {
      final disc = (_couponResult!['discount_amount'] as num?)?.toDouble() ?? 0;
      if (_couponResult!['discount_type'] == 'percentage') {
        discountAmount = displayTotal * (disc / 100);
      } else {
        discountAmount = disc;
      }
    }
    final finalTotal = (displayTotal - discountAmount).clamp(0.0, double.infinity);

    final bookingProv = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('حجز ${widget.farm['name']}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _checkIn ?? DateTime.now(),
                selectedDayPredicate: (day) =>
                    isSameDay(day, _checkIn) || isSameDay(day, _checkOut),
                rangeStartDay: _checkIn,
                rangeEndDay: _checkOut,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                onDaySelected: _onDaySelected,
                locale: 'ar',
                calendarStyle: CalendarStyle(
                  rangeHighlightColor:
                      AppColors.primary.withOpacity(0.12),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(fontFamily: 'Cairo'),
                  weekendTextStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.error,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            if (_checking)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(color: AppColors.primary),
              ),

            // Availability result
            if (_availability != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _availability!['available'] == true
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius:
                      BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  children: [
                    Icon(
                      _availability!['available'] == true
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _availability!['available'] == true
                          ? AppColors.success
                          : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _availability!['available'] == true
                            ? 'متاح - $nights ليالٍ - المجموع: ${serverTotal > 0 ? serverTotal.toStringAsFixed(0) : (nights * price).toStringAsFixed(0)} د.أ'
                            : 'غير متاح في هذه الأيام',
                        style: TextStyle(
                          color:
                              _availability!['available'] == true
                                  ? AppColors.success
                                  : AppColors.error,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guests
                  _sectionCard(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.md),
                              ),
                              child: const Icon(
                                  Icons.people_outline,
                                  color: AppColors.primary,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('عدد الأشخاص',
                                style: AppText.heading4),
                          ],
                        ),
                        Row(
                          children: [
                            _countBtn(Icons.remove, () {
                              if (_guests > 1) {
                                setState(() => _guests--);
                              }
                            }),
                            Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: Text(
                                '$_guests',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            _countBtn(Icons.add, () {
                              final cap = int.tryParse(widget
                                      .farm['capacity']
                                      .toString()) ??
                                  100;
                              if (_guests < cap) {
                                setState(() => _guests++);
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.md),
                              ),
                              child: const Icon(
                                  Icons.payment_outlined,
                                  color: AppColors.primary,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('طريقة الدفع',
                                style: AppText.heading4),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...[
                          {
                            'value': 'cash',
                            'label': 'كاش عند الوصول',
                            'icon': Icons.money_rounded,
                            'desc':
                                'ادفع نقداً عند الوصول للمزرعة',
                          },
                          {
                            'value': 'cliq',
                            'label': 'CliQ',
                            'icon': Icons.phone_android_rounded,
                            'desc':
                                'تحويل فوري عبر تطبيق CliQ',
                          },
                          {
                            'value': 'efawateer',
                            'label': 'eFAWATEERcom',
                            'icon': Icons.receipt_long_rounded,
                            'desc':
                                'الدفع الإلكتروني عبر eFAWATEERcom',
                          },
                        ].map((p) => GestureDetector(
                              onTap: () => setState(
                                  () => _paymentMethod = p['value'] as String),
                              child: Container(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _paymentMethod == p['value']
                                      ? AppColors.primarySurface
                                      : AppColors.grey100,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.lg),
                                  border: Border.all(
                                    color: _paymentMethod == p['value']
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      p['icon'] as IconData,
                                      color: _paymentMethod ==
                                              p['value']
                                          ? AppColors.primary
                                          : AppColors.grey500,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            p['label'] as String,
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.w700,
                                              color: _paymentMethod ==
                                                      p['value']
                                                  ? AppColors.primary
                                                  : AppColors.dark,
                                            ),
                                          ),
                                          Text(
                                            p['desc'] as String,
                                            style: AppText.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_paymentMethod ==
                                        p['value'])
                                      const Icon(
                                        Icons
                                            .check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Coupon Section
                  _couponSection(),

                  const SizedBox(height: 12),

                  // Notes
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          maxLines: 3,
                          onChanged: (v) => _notes = v,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            hintText: 'اي طلبات خاصة...',
                            prefixIcon: Icon(
                              Icons.note_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary
                  if (_checkIn != null && _checkOut != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.04),
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _summaryRow(
                            'الوصول',
                            DateFormat('dd/MM/yyyy')
                                .format(_checkIn!),
                          ),
                          _summaryRow(
                            'المغادرة',
                            DateFormat('dd/MM/yyyy')
                                .format(_checkOut!),
                          ),
                          _summaryRow('عدد الليالي', '$nights ليالٍ'),
                          _summaryRow(
                              'عدد الأشخاص', '$_guests أشخاص'),
                          const Divider(height: 20),

                          // Weekend pricing breakdown
                          if (_availability != null &&
                              _availability!['price_breakdown'] !=
                                  null) ...[
                            const SizedBox(height: 8),
                            const Text('تفاصيل التسعير',
                                style: AppText.heading4),
                            const SizedBox(height: 8),
                            ...(_availability!['price_breakdown']
                                    as List)
                                .map((night) => Container(
                                      margin:
                                          const EdgeInsets.only(
                                              bottom: 4),
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 8),
                                      decoration: BoxDecoration(
                                        color: night['is_weekend'] ==
                                                true
                                            ? AppColors.warningLight
                                            : AppColors.grey100,
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.md),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              night['day_name'] ?? '',
                                              style: AppText.small,
                                            ),
                                          ),
                                          Text(
                                            '${night['date']}',
                                            style: AppText.caption,
                                          ),
                                          if (night['is_weekend'] ==
                                              true)
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              margin:
                                                  const EdgeInsets
                                                      .only(
                                                      right: 8),
                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    AppColors.warning,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            4),
                                              ),
                                              child: const Text(
                                                'ويكند',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.white,
                                                  fontSize: 9,
                                                  fontFamily:
                                                      'Cairo',
                                                  fontWeight:
                                                      FontWeight
                                                          .w700,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            '${night['price']} د.أ',
                                            style:
                                                AppText.smallBold,
                                          ),
                                        ],
                                      ),
                                    )),
                            const Divider(height: 20),
                          ],

                          // Subtotal
                          if (serverTotal > 0)
                            _summaryRow(
                              'المجموع الفرعي',
                              '${serverTotal.toStringAsFixed(0)} د.أ',
                            ),

                          // Discount line
                          if (discountAmount > 0) ...[
                            _summaryRow(
                              'الخصم',
                              '-${discountAmount.toStringAsFixed(0)} د.أ',
                              color: AppColors.success,
                            ),
                            const Divider(height: 20),
                          ],

                          _summaryRow(
                            'الإجمالي النهائي',
                            '${finalTotal.toStringAsFixed(0)} د.أ',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  bookingProv.isActionLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _book,
                            child: const Text('تأكيد الحجز'),
                          ),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coupon Section ──
  Widget _couponSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.local_offer_outlined,
                    color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('كود خصم', style: AppText.heading4),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => _couponCode = v,
                  decoration: const InputDecoration(
                    hintText: 'ادخل كود الخصم',
                    prefixIcon: Icon(Icons.card_giftcard_outlined,
                        color: AppColors.gold, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _validatingCoupon ? null : _validateCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                  ),
                  child: _validatingCoupon
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('تطبيق'),
                ),
              ),
            ],
          ),
          // Coupon valid result
          if (_couponResult != null &&
              _couponResult!['valid'] == true) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم تطبيق الكود! خصم ${_couponResult!['discount_amount']} ${_couponResult!['discount_type'] == 'percentage' ? '%' : 'د.أ'}',
                      style: AppText.smallBold
                          .copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Coupon invalid result
          if (_couponResult != null &&
              _couponResult!['valid'] == false) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _couponResult!['message'] ?? 'كود غير صالح',
                      style: AppText.small
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: child,
      );

  Widget _countBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child:
              Icon(icon, size: 18, color: AppColors.primary),
        ),
      );

  Widget _summaryRow(String label, String value,
          {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.bodyGrey),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight:
                  bold ? FontWeight.w800 : FontWeight.normal,
              fontSize: bold ? 16 : 14,
              color: color ?? (bold ? AppColors.primary : AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}
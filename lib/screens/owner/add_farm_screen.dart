import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/app_theme.dart';
import '../../services/farm_service.dart';

class AddFarmScreen extends StatefulWidget {
  final Map<String, dynamic>? farm;
  const AddFarmScreen({super.key, this.farm});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;
  int? _savedFarmId;
  List<XFile> _selectedImages = [];
  bool _uploadingImages = false;
  LatLng? _selectedLocation;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceWeekendCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  String _city = 'عمان';
  String _type = 'farm';
  bool _hasPool = false;
  TimeOfDay _checkIn = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _checkOut = const TimeOfDay(hour: 12, minute: 0);

  final List<String> _cities = [
    'عمان', 'إربد', 'الزرقاء', 'السلط', 'الكرك', 'العقبة', 'جرش', 'عجلون', 'مادبا', 'البحر الميت'
  ];
  final List<Map<String, String>> _types = [
    {'value': 'farm', 'label': 'مزرعة'},
    {'value': 'chalet', 'label': 'شاليه'},
    {'value': 'villa', 'label': 'فيلا'},
    {'value': 'resort', 'label': 'منتجع'},
  ];

  // مراكز المدن الأردنية
  static const Map<String, LatLng> _cityCenters = {
    'عمان': LatLng(31.9454, 35.9284),
    'إربد': LatLng(32.5556, 35.8500),
    'الزرقاء': LatLng(32.0728, 36.0878),
    'السلط': LatLng(32.0392, 35.7278),
    'الكرك': LatLng(31.1853, 35.7048),
    'العقبة': LatLng(29.5267, 35.0062),
    'جرش': LatLng(32.2792, 35.8994),
    'عجلون': LatLng(32.3325, 35.7517),
    'مادبا': LatLng(31.7167, 35.7833),
    'البحر الميت': LatLng(31.5590, 35.4732),
  };

  bool get _isEdit => widget.farm != null;

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://hajez.esnaad-sa.com$url';
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _savedFarmId = widget.farm!['id'];
      _nameCtrl.text = widget.farm!['name'] ?? '';
      _descCtrl.text = widget.farm!['description'] ?? '';
      _city = widget.farm!['city'] ?? 'عمان';
      _addressCtrl.text = widget.farm!['address'] ?? '';
      _priceCtrl.text = '${widget.farm!['price_per_night'] ?? ''}';
      _capacityCtrl.text = '${widget.farm!['capacity'] ?? ''}';
      _type = widget.farm!['type'] ?? 'farm';
      _hasPool = widget.farm!['has_pool'] ?? false;
      _whatsappCtrl.text = widget.farm!['whatsapp'] ?? '';
      _rulesCtrl.text = widget.farm!['rules'] ?? '';
      final weekendPrice = widget.farm!['price_per_night_weekend'];
      if (weekendPrice != null) {
        _priceWeekendCtrl.text = '$weekendPrice';
      }
      final lat = double.tryParse(
          widget.farm!['latitude']?.toString() ?? '');
      final lng = double.tryParse(
          widget.farm!['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
      }
      // Parse check-in/out times if available
      if (widget.farm!['check_in_time'] != null) {
        final parts =
            widget.farm!['check_in_time'].toString().split(':');
        if (parts.length >= 2) {
          _checkIn = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 14,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      if (widget.farm!['check_out_time'] != null) {
        final parts =
            widget.farm!['check_out_time'].toString().split(':');
        if (parts.length >= 2) {
          _checkOut = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 12,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
  }

  void _save() async {
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'city': _city,
        'address': _addressCtrl.text.trim(),
        'price_per_night':
            double.tryParse(_priceCtrl.text) ?? 0,
        'price_per_night_weekend':
            _priceWeekendCtrl.text.isNotEmpty
                ? double.tryParse(_priceWeekendCtrl.text)
                : null,
        'capacity': int.tryParse(_capacityCtrl.text) ?? 0,
        'type': _type,
        'has_pool': _hasPool,
        'whatsapp': _whatsappCtrl.text.trim(),
        'rules': _rulesCtrl.text.trim(),
        'check_in_time':
            '${_checkIn.hour.toString().padLeft(2, '0')}:${_checkIn.minute.toString().padLeft(2, '0')}',
        'check_out_time':
            '${_checkOut.hour.toString().padLeft(2, '0')}:${_checkOut.minute.toString().padLeft(2, '0')}',
        if (_selectedLocation != null)
          'latitude': _selectedLocation!.latitude,
        if (_selectedLocation != null)
          'longitude': _selectedLocation!.longitude,
      };

      Map<String, dynamic> res;
      if (_isEdit) {
        res = await FarmService.updateFarm(
            widget.farm!['id'], data);
        // updateFarm response: {farm: {...}} or {message: ...}
        if (res['farm'] != null) {
          _savedFarmId = res['farm']['id'] ?? _savedFarmId;
        }
      } else {
        res = await FarmService.createFarm(data);
        if (res['farm'] != null) {
          _savedFarmId = res['farm']['id'];
        }
      }

      if (res['farm'] != null) {
        setState(() => _step = 2);
        _pageCtrl.jumpToPage(2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? 'خطأ',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر الاتصال',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _uploadImages() async {
    if (_savedFarmId == null || _selectedImages.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _uploadingImages = true);
    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        await FarmService.uploadFarmImage(
          farmId: _savedFarmId!,
          imageFile: File(_selectedImages[i].path),
          isCover: i == 0,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'تم التحديث ✅' : 'تمت الإضافة ✅',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر رفع الصور',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => _uploadingImages = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل المزرعة' : 'إضافة مزرعة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: AppColors.grey100,
            color: AppColors.primary,
          ),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [_step1(), _step2(), _step3()],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Row(
          children: [
            if (_step > 0 && _step < 2)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _step--);
                    _pageCtrl.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('رجوع'),
                ),
              ),
            if (_step > 0 && _step < 2) const SizedBox(width: 12),
            if (_step < 2)
              Expanded(
                child: _step < 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() => _step++);
                          _pageCtrl.nextPage(
                            duration:
                                const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('التالي'),
                      )
                    : _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          )
                        : ElevatedButton(
                            onPressed: _save,
                            child: Text(_isEdit
                                ? 'حفظ التعديلات'
                                : 'إضافة المزرعة'),
                          ),
              ),
            if (_step == 2)
              Expanded(
                child: _uploadingImages
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    : ElevatedButton(
                        onPressed: _uploadImages,
                        child: Text(_selectedImages.isEmpty
                            ? 'تخطي'
                            : 'رفع الصور وإنهاء'),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _step1() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المعلومات الأساسية', style: AppText.heading2),
            const SizedBox(height: 20),
            _field(_nameCtrl, 'اسم المزرعة',
                Icons.home_work_outlined),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'وصف المزرعة',
                prefixIcon: Icon(
                    Icons.description_outlined, color: AppColors.primary),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            _dropdown('المدينة', _city, _cities,
                (v) => setState(() => _city = v!)),
            const SizedBox(height: 14),
            _field(_addressCtrl, 'العنوان التفصيلي',
                Icons.location_on_outlined),
            const SizedBox(height: 14),
            _field(_whatsappCtrl, 'رقم واتساب (اختياري)',
                Icons.chat_outlined),
          ],
        ),
      );

  Widget _step2() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('التفاصيل والأسعار', style: AppText.heading2),
            const SizedBox(height: 20),
            const Text('نوع المكان', style: AppText.heading3),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _types
                  .map((t) => GestureDetector(
                        onTap: () =>
                            setState(() => _type = t['value']!),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == t['value']
                                ? AppColors.primary
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            t['label']!,
                            style: TextStyle(
                              color: _type == t['value']
                                  ? AppColors.white
                                  : AppColors.dark,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(_priceCtrl, 'السعر/ليلة (د.أ)',
                      Icons.attach_money, isNumber: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_priceWeekendCtrl, 'سعر الويكند',
                      Icons.weekend, isNumber: true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(_capacityCtrl, 'السعة (عدد الأشخاص)',
                Icons.people_outline, isNumber: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pool, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('يوجد مسبح', style: AppText.body),
                    ],
                  ),
                  Switch(
                    value: _hasPool,
                    onChanged: (v) =>
                        setState(() => _hasPool = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _timePicker('وقت الدخول', _checkIn,
                      (t) => setState(() => _checkIn = t)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timePicker('وقت الخروج', _checkOut,
                      (t) => setState(() => _checkOut = t)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── الموقع ──
            const Text('الموقع على الخريطة', style: AppText.heading3),
            const SizedBox(height: 6),
            Text(
              _selectedLocation != null
                  ? 'تم تحديد الموقع ✓'
                  : 'اضغط على الخريطة لتحديد موقع المزرعة (اختياري)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: _selectedLocation != null
                    ? AppColors.success
                    : AppColors.grey500,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedLocation ??
                        (_cityCenters[_city] ??
                            const LatLng(31.9454, 35.9284)),
                    initialZoom: 12,
                    onTap: (_, point) =>
                        setState(() => _selectedLocation = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hajez.app',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin,
                                color: AppColors.primary, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (_selectedLocation != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _selectedLocation = null),
                icon: const Icon(Icons.clear,
                    size: 16, color: AppColors.error),
                label: const Text(
                  'مسح الموقع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _step3() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('صور المزرعة', style: AppText.heading2),
            const SizedBox(height: 8),
            const Text(
              'أضف صوراً لمزرعتك — الصورة الأولى ستكون الغلاف',
              style: AppText.bodyGrey,
            ),
            const SizedBox(height: 20),

            // Existing images when editing
            if (_isEdit &&
                widget.farm!['images'] != null &&
                (widget.farm!['images'] as List).isNotEmpty) ...[
              const Text(
                'الصور الحالية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      (widget.farm!['images'] as List).length,
                  itemBuilder: (_, i) {
                    final img = widget.farm!['images'][i];
                    final imgUrl = _fixUrl(img['image_path']);
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.grey200,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imgUrl.isNotEmpty
                            ? Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                  color: AppColors.grey100,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppColors.grey400,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.grey100,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppColors.grey400,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Upload new images
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 40, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'اضغط لاختيار الصور',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${_selectedImages.length} صور مختارة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (_, i) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages[i].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (i == 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'غلاف',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedImages.removeAt(i)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _rulesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'قواعد المزرعة (اختياري)',
                hintText:
                    'مثال: عائلات فقط، ممنوع التدخين...',
                prefixIcon:
                    Icon(Icons.rule, color: AppColors.primary),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {bool isNumber = false}) =>
      TextFormField(
        controller: ctrl,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
        ),
      );

  Widget _dropdown(String label, String value, List<String> items,
          Function(String?) onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items
                .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text(i,
                          style: const TextStyle(fontFamily: 'Cairo')),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _timePicker(String label, TimeOfDay time,
          Function(TimeOfDay) onChanged) =>
      GestureDetector(
        onTap: () async {
          final t =
              await showTimePicker(context: context, initialTime: time);
          if (t != null) onChanged(t);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.small),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

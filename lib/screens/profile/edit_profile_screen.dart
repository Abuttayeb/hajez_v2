import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _loading = false;
  File? _avatarFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.user?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: auth.user?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked != null) setState(() => _avatarFile = File(picked.path));
  }

  void _save() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'تم تحديث الملف الشخصي' : (auth.error ?? 'حدث خطأ'),
          style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ));
      if (success) Navigator.pop(context);
    }
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: Icon(Icons.lock, color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: Icon(Icons.lock_clock_outlined, color: AppColors.primary)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => TextButton(
              onPressed: auth.isLoading ? null : () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('كلمتا المرور غير متطابقتين', style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل', style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
                final ok = await auth.changePassword(currentPassword: currentCtrl.text, newPassword: newCtrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.success,
                    ));
                  }
                }
              },
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Text('تغيير', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        actions: [
          _loading
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
              : TextButton(onPressed: _save, child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        image: _avatarFile != null
                            ? DecorationImage(image: FileImage(_avatarFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _avatarFile == null
                          ? Center(
                              child: Text(
                                _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'م',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.white, fontFamily: 'Cairo'),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.grey200, width: 2)),
                        child: const Center(child: Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline, color: AppColors.primary)),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(AppRadius.lg)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.grey500, size: 20),
                  const SizedBox(width: 14),
                  Expanded(child: Text(context.watch<AuthProvider>().email, style: AppText.bodyGrey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(6)),
                    child: Text('لا يمكن التعديل', style: AppText.caption),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم الجوال', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary)),
            ),
            const SizedBox(height: 32),
            // Change Password
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                title: Text('تغيير كلمة المرور', style: AppText.heading4.copyWith(color: AppColors.primary)),
                subtitle: const Text('أدخل كلمة المرور الحالية واختر كلمة جديدة', style: AppText.small),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                onTap: _showChangePasswordDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
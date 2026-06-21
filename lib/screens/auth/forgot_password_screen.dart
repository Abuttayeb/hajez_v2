import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final emailCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.xl)),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 24),
            const Text('نسيت كلمة المرور؟', style: AppText.heading1),
            const SizedBox(height: 8),
            Text('أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور', style: AppText.bodyGrey.copyWith(height: 1.6)),
            const SizedBox(height: 32),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(auth.error!, style: AppText.smallBold.copyWith(color: AppColors.error))),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            auth.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ElevatedButton(
                    onPressed: () async {
                      final success = await auth.forgotPassword(email: emailCtrl.text.trim());
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('تم إرسال رابط إعادة التعيين! تحقق من بريدك', style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('إرسال رابط إعادة التعيين'),
                  ),
          ],
        ),
      ),
    );
  }
}
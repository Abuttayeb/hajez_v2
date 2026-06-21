import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure = true;

    return StatefulBuilder(
      builder: (context, setInnerState) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.vertical(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      LOGO_BASE64.isEmpty
                          ? Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.home_work_outlined, size: 36, color: AppColors.white),
                            )
                          : Image.memory(base64Decode(LOGO_BASE64), height: 90),
                      const SizedBox(height: 20),
                      const Text('مرحباً بعودتك', style: TextStyle(color: AppColors.white, fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('سجّل دخولك للاستمرار', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 14)),
                    ],
                  ),
                ),
                // Form
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text('تسجيل الدخول', style: AppText.heading2),
                        const SizedBox(height: 4),
                        Text('أدخل بياناتك للمتابعة', style: AppText.bodyGrey),
                        const SizedBox(height: 28),

                        // Error
                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppRadius.lg)),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(auth.error!, style: AppText.smallBold.copyWith(color: AppColors.error))),
                              GestureDetector(onTap: () => auth.clearError(), child: const Icon(Icons.close, size: 16, color: AppColors.error)),
                            ]),
                          ),
                        ],

                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary)),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'مطلوب';
                            if (!v.contains('@')) return 'بريد غير صالح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.grey500),
                              onPressed: () => setInnerState(() => obscure = !obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: Text('نسيت كلمة المرور؟', style: AppText.smallBold.copyWith(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        auth.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final ok = await auth.login(email: emailCtrl.text.trim(), password: passCtrl.text);
                                    if (context.mounted && ok) Navigator.pushReplacementNamed(context, '/home');
                                  },
                                  child: const Text('تسجيل الدخول'),
                                ),
                              ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('ما عندك حساب؟', style: AppText.bodyGrey),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text('إنشاء حساب', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
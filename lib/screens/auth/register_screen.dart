import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'customer';
    bool obscure = true;

    return StatefulBuilder(
      builder: (context, setInnerState) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                  ),
                  child: Column(children: [
                    LOGO_BASE64.isEmpty
                        ? Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.home_work_outlined, size: 28, color: AppColors.white))
                        : Image.memory(base64Decode(LOGO_BASE64), height: 70),
                    const SizedBox(height: 10),
                    const Text('إنشاء حساب جديد', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 14)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مرحباً!', style: AppText.heading2),
                        const SizedBox(height: 4),
                        Text('أنشئ حسابك للبدء', style: AppText.bodyGrey),
                        const SizedBox(height: 24),

                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppRadius.lg)),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(auth.error!, style: AppText.smallBold.copyWith(color: AppColors.error))),
                            ]),
                          ),
                        ],

                        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline, color: AppColors.primary)), validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                        const SizedBox(height: 14),
                        TextFormField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary)), validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                        const SizedBox(height: 14),
                        TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رقم الجوال', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary)), validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: passCtrl, obscureText: obscure,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                            suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.grey500), onPressed: () => setInnerState(() => obscure = !obscure)),
                          ),
                          validator: (v) => v != null && v.length < 6 ? '6 أحرف على الأقل' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text('نوع الحساب', style: AppText.heading4),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _roleCard('customer', 'زبون', Icons.person_outline, 'احجز مزارع وشاليهات', role, (v) => setInnerState(() => role = v))),
                          const SizedBox(width: 12),
                          Expanded(child: _roleCard('owner', 'مالك', Icons.home_work_outlined, 'أضف وأدر مزارعك', role, (v) => setInnerState(() => role = v))),
                        ]),
                        const SizedBox(height: 24),
                        auth.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final ok = await auth.register(name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), phone: phoneCtrl.text.trim(), password: passCtrl.text, role: role);
                                  if (context.mounted && ok) Navigator.pushReplacementNamed(context, '/home');
                                },
                                child: const Text('إنشاء الحساب'),
                              )),
                        const SizedBox(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('عندك حساب؟', style: AppText.bodyGrey),
                          TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('سجّل دخولك', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
                        ]),
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

Widget _roleCard(String value, String title, IconData icon, String sub, String current, Function(String) onTap) {
  final sel = current == value;
  return GestureDetector(
    onTap: () => onTap(value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sel ? AppColors.primary.withOpacity(0.06) : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: sel ? AppColors.primary : AppColors.grey200, width: sel ? 2 : 1),
      ),
      child: Column(children: [
        Icon(icon, color: sel ? AppColors.primary : AppColors.grey500, size: 28),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: sel ? AppColors.primary : AppColors.dark, fontFamily: 'Cairo', fontSize: 13)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: sel ? AppColors.secondary : AppColors.grey500, fontSize: 10, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      ]),
    ),
  );
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.8, curve: Curves.elasticOut)));
    _ctrl.forward();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (!onboarded) { Navigator.pushReplacementNamed(context, '/onboarding'); return; }
    final loggedIn = await AuthService.isLoggedIn();
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topRight, end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: LOGO_BASE64.isEmpty
                        ? const Icon(Icons.home_work_outlined, size: 120, color: Colors.white)
                        : Image.memory(base64Decode(LOGO_BASE64), height: 160),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fade,
                  child: const Text(APP_TAGLINE, style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo'), textAlign: TextAlign.center),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fade,
                  child: const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

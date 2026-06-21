import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'مرحباً في حاجز',
      'subtitle': 'منصة متكاملة لحجز المزارع والشاليهات والفلل والمنتجعات في الأردن',
      'icon': Icons.home_work_outlined,
      'color1': AppColors.primaryDark,
      'color2': AppColors.primaryLight,
      'illustration': Icons.explore_outlined,
    },
    {
      'title': 'آلاف الخيارات',
      'subtitle': 'اكتشف أجمل الأماكن في عمان والعقبة وجرش وكل مدن الأردن مع تقييمات حقيقية',
      'icon': Icons.location_city,
      'color1': AppColors.primary,
      'color2': AppColors.accent,
      'illustration': Icons.search_rounded,
    },
    {
      'title': 'حجز ذكي وسريع',
      'subtitle': 'احجز بضغطة واحدة، ادفع بالكاش أو CliQ أو eFAWATEERcom، واستمتع بتجربة فريدة',
      'icon': Icons.calendar_today_outlined,
      'color1': AppColors.secondary,
      'color2': AppColors.primaryLight,
      'illustration': Icons.payment_outlined,
    },
  ];

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (_pages[_currentPage]['color1'] as Color),
              (_pages[_currentPage]['color2'] as Color).withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: TextButton(onPressed: _finish, child: const Text('تخطي', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontWeight: FontWeight.w600))),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration
                          Container(
                            width: 180, height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Icon(page['illustration'] as IconData, size: 56, color: AppColors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(page['title'] as String, style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Cairo'), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          Text(page['subtitle'] as String, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16, fontFamily: 'Cairo', height: 1.7), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    const SizedBox(height: 36),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _currentPage == _pages.length - 1
                            ? _finish
                            : () => _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.primary),
                        child: Text(_currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
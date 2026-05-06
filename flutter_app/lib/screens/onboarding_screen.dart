import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final _slides = const [
    _Slide(
      color: AppColors.primary,
      icon: Icons.storefront_outlined,
      emoji: '🏺',
      title: 'اكتشف الحرفيين',
      subtitle:
          'تصفح مئات المنتجات اليدوية الأصيلة من حرفيين جزائريين موثوقين في منطقتك',
      lightColor: Color(0xFF1D9E75),
    ),
    _Slide(
      color: Color(0xFF0F6E56),
      icon: Icons.map_outlined,
      emoji: '📍',
      title: 'ابحث بالخريطة',
      subtitle:
          'اعثر على أقرب حرفي إليك عبر الخريطة التفاعلية وتواصل معه مباشرة',
      lightColor: Color(0xFF0F6E56),
    ),
    _Slide(
      color: Color(0xFFBA7517),
      icon: Icons.school_outlined,
      emoji: '🎓',
      title: 'تعلم حرفة جديدة',
      subtitle:
          'سجل في جلسات تعليمية مع حرفيين محترفين وتعلم حرفة جديدة من راحة منزلك',
      lightColor: Color(0xFFBA7517),
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Get.offNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
          ),

          // Skip button
          Positioned(
            top: 52,
            right: 20,
            child: SafeArea(
              child: TextButton(
                onPressed: _finish,
                child: const Text('تخطي',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(children: [
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Next / Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _slides[_currentPage].color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _next,
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'ابدأ الآن' : 'التالي',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Single slide widget ───────────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: slide.color,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Big emoji in a circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      Text(slide.emoji, style: const TextStyle(fontSize: 72)),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                slide.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.6),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────
class _Slide {
  final Color color;
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Color lightColor;
  const _Slide({
    required this.color,
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.lightColor,
  });
}

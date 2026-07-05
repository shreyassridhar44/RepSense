import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_button.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardData(this.icon, this.title, this.subtitle);
}

const _pages = [
  _OnboardData(
    Icons.visibility_rounded,
    'AI watches your movement.',
    'Real-time computer vision tracks 33 body landmarks, every rep, every angle.',
  ),
  _OnboardData(
    Icons.shield_moon_rounded,
    'AI prevents injuries.',
    'Biomechanical analysis flags unsafe patterns before they become an injury.',
  ),
  _OnboardData(
    Icons.trending_up_rounded,
    'AI tracks your improvement.',
    'Long-term performance trends across strength, form, and consistency.',
  ),
  _OnboardData(
    Icons.sports_gymnastics_rounded,
    'AI becomes your trainer.',
    'Personalized, explainable coaching — like a biomechanics lab in your pocket.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.glassGradient,
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Icon(p.icon, size: 64, color: AppColors.electricBlue),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i ? AppColors.electricBlue : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(
                label: _index == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_index == _pages.length - 1) {
                    context.go('/auth');
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

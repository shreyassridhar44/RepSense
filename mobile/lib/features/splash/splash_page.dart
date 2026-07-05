import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Skeleton joints forming" — simplified as animated dot grid
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricBlue.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        duration: 1200.ms,
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.05, 1.05),
                      ),
                  const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 56),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'RepSense',
              style: Theme.of(context).textTheme.displayMedium,
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Every Rep. Perfected.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(letterSpacing: 0.5),
            ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

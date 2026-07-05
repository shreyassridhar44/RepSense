import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import 'home_page.dart';
import '../workout/workout_selection_page.dart';
import '../progress/progress_page.dart';
import '../coach/coach_page.dart';
import '../profile/profile_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    WorkoutSelectionPage(embedded: true),
    ProgressPage(),
    CoachPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Guest Mode Banner
          if (isGuest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.amber.withOpacity(0.15),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.amber, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        AppStrings.guestModeBanner,
                        style: TextStyle(color: AppColors.amber, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to auth
                        clearGuestMode();
                        // Router will handle redirect
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Main Content
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

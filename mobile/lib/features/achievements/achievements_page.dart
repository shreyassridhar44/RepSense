import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/overview_tab.dart';
import 'widgets/badges_tab.dart';
import 'widgets/challenges_tab.dart';
import 'widgets/leaderboard_tab.dart';

/// Main achievements screen with tabs
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load data on init
    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        ref.read(achievementsNotifierProvider(userId).notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final state = ref.watch(achievementsNotifierProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Tab bar
            _buildTabBar(context),
            
            // Tab views
            Expanded(
              child: state.isLoading && state.achievements.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.hasError
                      ? _buildError(context, userId)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            OverviewTab(userId: userId),
                            BadgesTab(userId: userId),
                            ChallengesTab(userId: userId),
                            LeaderboardTab(userId: userId),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.electricBlue,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Badges'),
          Tab(text: 'Challenges'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load achievements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(achievementsNotifierProvider(userId).notifier).loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

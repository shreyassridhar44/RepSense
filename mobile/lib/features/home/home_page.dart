import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/score_gauge.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning,', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Athlete', style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                child: const Icon(Icons.person_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Workout', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Full Body Strength · 6 exercises', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: 'Start Training',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => context.push('/workouts'),
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Streak', value: '12', icon: Icons.local_fire_department_rounded, color: AppColors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Calories', value: '482', icon: Icons.bolt_rounded, color: AppColors.emerald)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Recovery', value: '86%', icon: Icons.favorite_rounded, color: AppColors.violet)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Consistency', value: '94%', icon: Icons.calendar_month_rounded, color: AppColors.electricBlue)),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Movement Quality Score', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    ScoreGauge(score: 92, label: 'Overall'),
                    ScoreGauge(score: 88, label: 'Stability'),
                    ScoreGauge(score: 95, label: 'Symmetry'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Recent Achievements', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.amber),
                      const SizedBox(height: 6),
                      Text('Badge ${i + 1}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.streakDays,
    required this.calories,
    required this.consistency,
    required this.weeklyWorkouts,
  });

  final int streakDays;
  final double calories;
  final double consistency;
  final int weeklyWorkouts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: streakDays == 0 ? 'Start today!' : '$streakDays days',
                color: AppColors.amber,
              ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Calories',
                value: calories == 0 ? '—' : '${calories.toInt()} kcal',
                color: AppColors.emerald,
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.favorite,
                label: 'Consistency',
                value: '${consistency.toInt()}%',
                color: AppColors.violet,
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                label: 'Workouts',
                value: '$weeklyWorkouts this week',
                color: AppColors.electricBlue,
              ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

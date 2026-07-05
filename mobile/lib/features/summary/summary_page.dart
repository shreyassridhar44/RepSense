import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/score_gauge.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key, required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final reps = result['reps'] ?? 0;
    final avgScore = (result['avgScore'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Workout Summary', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Here\'s how your set went.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _metric(context, '$reps', 'Total Reps')),
                const SizedBox(width: 12),
                Expanded(child: _metric(context, '$reps', 'Correct Reps')),
                const SizedBox(width: 12),
                Expanded(child: _metric(context, '0', 'Incorrect')),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  Text('Form Quality Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    runSpacing: 16,
                    children: [
                      ScoreGauge(score: avgScore, label: 'Overall'),
                      const ScoreGauge(score: 88, label: 'Joint\nAlignment'),
                      const ScoreGauge(score: 90, label: 'Range of\nMotion'),
                      const ScoreGauge(score: 85, label: 'Tempo'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Observations', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _observation(context, 'Your knees moved inward on reps 4 and 7.',
                      'This increases knee stress. Try pushing your knees outward.', 'Moderate'),
                  const Divider(height: 24),
                  _observation(context, 'Depth was excellent throughout the set.',
                      'Full range of motion improves muscle activation.', 'Good'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: 'Done',
                    onPressed: () => context.go('/home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _observation(BuildContext context, String problem, String correction, String severity) {
    final color = severity == 'Good' ? AppColors.emerald : AppColors.amber;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(problem, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(correction, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

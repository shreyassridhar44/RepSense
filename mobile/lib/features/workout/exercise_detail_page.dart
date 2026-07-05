import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});
  final String exerciseId;

  String get _title => exerciseId
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ],
            ),
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 72),
              ),
            ),
            const SizedBox(height: 20),
            Text(_title, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'AI evaluates range of motion, tempo, stability, joint alignment, '
              'and symmetry in real time while you perform this movement.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Common Mistakes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _bullet(context, 'Knees collapsing inward during descent'),
                  _bullet(context, 'Excessive forward torso lean'),
                  _bullet(context, 'Incomplete range of motion'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Start Analysis',
              icon: Icons.videocam_rounded,
              onPressed: () => context.push('/camera/$exerciseId'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 8),
              child: Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
            ),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

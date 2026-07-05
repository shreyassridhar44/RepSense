import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Text('Progress', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Your trends over time.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Form Score Trend', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.electricBlue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.electricBlue.withOpacity(0.3),
                                AppColors.electricBlue.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          spots: const [
                            FlSpot(0, 78),
                            FlSpot(1, 82),
                            FlSpot(2, 80),
                            FlSpot(3, 88),
                            FlSpot(4, 91),
                            FlSpot(5, 89),
                            FlSpot(6, 94),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Prediction', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  "You're likely to improve your squat depth by 18% this month based on your current consistency.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _record(context, 'Squat 1RM est.', '92 kg')),
              const SizedBox(width: 12),
              Expanded(child: _record(context, 'Best Streak', '21 days')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _record(BuildContext context, String label, String value) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/progress_models.dart';

/// Line chart displaying form score trend over time
class FormScoreChart extends StatelessWidget {
  final List<FormScoreTrend> trends;
  final TrendPeriod period;

  const FormScoreChart({
    super.key,
    required this.trends,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.textSecondary.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getBottomInterval(),
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= trends.length) {
                    return const SizedBox.shrink();
                  }
                  final date = trends[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: trends.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.avgScore,
                );
              }).toList(),
              isCurved: true,
              color: AppColors.electricBlue,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.electricBlue,
                    strokeWidth: 2,
                    strokeColor: AppColors.backgroundDark,
                  );
                },
              ),
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
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final trend = trends[spot.x.toInt()];
                  return LineTooltipItem(
                    '${trend.avgScore.toStringAsFixed(1)}%\n${DateFormat('MMM d').format(trend.date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getBottomInterval() {
    if (trends.length <= 7) return 1;
    if (trends.length <= 14) return 2;
    if (trends.length <= 30) return 5;
    return 10;
  }

  String _formatDate(DateTime date) {
    switch (period) {
      case TrendPeriod.week:
        return DateFormat('EEE').format(date);
      case TrendPeriod.month:
      case TrendPeriod.threeMonths:
        return DateFormat('MMM d').format(date);
      case TrendPeriod.year:
        return DateFormat('MMM').format(date);
    }
  }
}

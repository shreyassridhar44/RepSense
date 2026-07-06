import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/progress_models.dart';

/// GitHub-style contribution heatmap showing workout consistency
class ConsistencyHeatmap extends StatelessWidget {
  final List<ConsistencyDay> days;

  const ConsistencyHeatmap({
    super.key,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Group days by week
    final weeks = <List<ConsistencyDay>>[];
    var currentWeek = <ConsistencyDay>[];

    for (final day in days) {
      if (currentWeek.isNotEmpty && day.date.weekday == DateTime.monday) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
      currentWeek.add(day);
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels
          Row(
            children: [
              const SizedBox(width: 24), // Offset for alignment
              ...['M', 'T', 'W', 'T', 'F', 'S', 'S'].map(
                (label) => SizedBox(
                  width: 16,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Heatmap grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks.asMap().entries.map((entry) {
              final weekIndex = entry.key;
              final week = entry.value;
              final firstDayOfWeek = week.first.date;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month label
                  if (firstDayOfWeek.day <= 7)
                    SizedBox(
                      width: 20,
                      child: Text(
                        DateFormat('MMM').format(firstDayOfWeek).substring(0, 1),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 20),
                  // Week column
                  Column(
                    children: [
                      // Fill empty days at start
                      ...List.generate(
                        week.first.date.weekday - 1,
                        (_) => _buildEmptyCell(),
                      ),
                      // Actual days
                      ...week.map(_buildDayCell),
                      // Fill empty days at end
                      ...List.generate(
                        7 - week.last.date.weekday,
                        (_) => _buildEmptyCell(),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              _buildLegendCell(0),
              const SizedBox(width: 2),
              _buildLegendCell(1),
              const SizedBox(width: 2),
              _buildLegendCell(2),
              const SizedBox(width: 2),
              _buildLegendCell(3),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(ConsistencyDay day) {
    return Tooltip(
      message: '${DateFormat('MMM d, yyyy').format(day.date)}\n${day.workoutCount} workout${day.workoutCount != 1 ? 's' : ''}',
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getColorForIntensity(day.intensity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.all(2),
    );
  }

  Widget _buildLegendCell(int intensity) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getColorForIntensity(intensity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColorForIntensity(int intensity) {
    switch (intensity) {
      case 0:
        return AppColors.textSecondary.withOpacity(0.1);
      case 1:
        return AppColors.electricBlue.withOpacity(0.3);
      case 2:
        return AppColors.electricBlue.withOpacity(0.6);
      case 3:
      default:
        return AppColors.electricBlue;
    }
  }
}

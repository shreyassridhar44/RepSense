import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/progress_models.dart';

/// Radar chart showing muscle group balance
class MuscleBalanceRadar extends StatelessWidget {
  final List<MuscleBalancePoint> points;

  const MuscleBalanceRadar({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('No muscle group data available'),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RadarChartPainter(points: points),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<MuscleBalancePoint> points;

  _RadarChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 60;
    final angleStep = (2 * math.pi) / points.length;

    // Draw grid circles
    _drawGridCircles(canvas, center, radius);

    // Draw axes and labels
    _drawAxesAndLabels(canvas, center, radius, angleStep);

    // Draw data polygon
    _drawDataPolygon(canvas, center, radius, angleStep);

    // Draw data points
    _drawDataPoints(canvas, center, radius, angleStep);
  }

  void _drawGridCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * (i / 5), paint);
    }
  }

  void _drawAxesAndLabels(
    Canvas canvas,
    Offset center,
    double radius,
    double angleStep,
  ) {
    final axisPaint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < points.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Draw axis line
      canvas.drawLine(center, endPoint, axisPaint);

      // Draw label
      final labelPoint = Offset(
        center.dx + (radius + 30) * math.cos(angle),
        center.dy + (radius + 30) * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: _abbreviateMuscleGroup(points[i].muscleGroup),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    double angleStep,
  ) {
    final path = Path();
    final paint = Paint()
      ..color = AppColors.electricBlue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = points[i].normalizedScore / 100;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.electricBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  void _drawDataPoints(
    Canvas canvas,
    Offset center,
    double radius,
    double angleStep,
  ) {
    final paint = Paint()
      ..color = AppColors.electricBlue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = points[i].normalizedScore / 100;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );

      canvas.drawCircle(point, 4, paint);
    }
  }

  String _abbreviateMuscleGroup(String muscle) {
    final map = {
      'Chest': 'Chest',
      'Back': 'Back',
      'Shoulders': 'Shoulders',
      'Arms': 'Arms',
      'Legs': 'Legs',
      'Core': 'Core',
      'Glutes': 'Glutes',
      'Cardio': 'Cardio',
    };
    return map[muscle] ?? muscle;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

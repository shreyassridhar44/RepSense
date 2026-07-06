import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Result from inference service analysis
class InferenceResult {
  final String exerciseId;
  final int totalReps;
  final double avgScore;
  final ScoresBreakdown scoresBreakdown;
  final List<RepResult> reps;
  final List<FormIssue> topIssues;
  final String coachingSummary;

  const InferenceResult({
    required this.exerciseId,
    required this.totalReps,
    required this.avgScore,
    required this.scoresBreakdown,
    required this.reps,
    required this.topIssues,
    required this.coachingSummary,
  });

  factory InferenceResult.fromJson(Map<String, dynamic> json) {
    return InferenceResult(
      exerciseId: json['exercise'] as String? ?? '',
      totalReps: json['total_reps'] as int? ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      scoresBreakdown: json['scores_breakdown'] != null
          ? ScoresBreakdown.fromJson(json['scores_breakdown'] as Map<String, dynamic>)
          : const ScoresBreakdown(
              rangeOfMotion: 0,
              symmetry: 0,
              stability: 0,
              tempo: 0,
              lockout: 0,
              overall: 0,
            ),
      reps: (json['reps'] as List<dynamic>?)
              ?.map((e) => RepResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topIssues: (json['top_issues'] as List<dynamic>?)
              ?.map((e) => FormIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      coachingSummary: json['coaching_summary'] as String? ?? '',
    );
  }

  // Convenience getters
  bool get isHighQuality => avgScore >= 85;

  String get scoreLabel {
    if (avgScore >= 85) return 'Excellent';
    if (avgScore >= 70) return 'Good';
    if (avgScore >= 50) return 'Fair';
    return 'Needs Work';
  }

  Color get scoreColor {
    if (avgScore >= 85) return AppTheme.emerald;
    if (avgScore >= 70) return AppTheme.electricBlue;
    if (avgScore >= 50) return AppTheme.amber;
    return AppTheme.error;
  }
}

/// Breakdown of form scores
class ScoresBreakdown {
  final double rangeOfMotion;
  final double symmetry;
  final double stability;
  final double tempo;
  final double lockout;
  final double overall;

  const ScoresBreakdown({
    required this.rangeOfMotion,
    required this.symmetry,
    required this.stability,
    required this.tempo,
    required this.lockout,
    required this.overall,
  });

  factory ScoresBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoresBreakdown(
      rangeOfMotion: (json['range_of_motion'] as num?)?.toDouble() ?? 0.0,
      symmetry: (json['symmetry'] as num?)?.toDouble() ?? 0.0,
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      tempo: (json['tempo'] as num?)?.toDouble() ?? 0.0,
      lockout: (json['lockout'] as num?)?.toDouble() ?? 0.0,
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'range_of_motion': rangeOfMotion,
      'symmetry': symmetry,
      'stability': stability,
      'tempo': tempo,
      'lockout': lockout,
      'overall': overall,
    };
  }
}

/// Per-rep analysis result
class RepResult {
  final int repIndex;
  final double overallScore;
  final ScoresBreakdown scores;
  final List<FormIssue> issues;

  const RepResult({
    required this.repIndex,
    required this.overallScore,
    required this.scores,
    required this.issues,
  });

  factory RepResult.fromJson(Map<String, dynamic> json) {
    return RepResult(
      repIndex: json['rep_index'] as int? ?? 0,
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      scores: json['scores'] != null
          ? ScoresBreakdown.fromJson(json['scores'] as Map<String, dynamic>)
          : const ScoresBreakdown(
              rangeOfMotion: 0,
              symmetry: 0,
              stability: 0,
              tempo: 0,
              lockout: 0,
              overall: 0,
            ),
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => FormIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isCorrect => overallScore >= 70;

  Map<String, dynamic> toJson() {
    return {
      'rep_index': repIndex,
      'overall_score': overallScore,
      'scores': scores.toJson(),
      'issues': issues.map((i) => i.toJson()).toList(),
    };
  }
}

/// Form issue detected in a rep
class FormIssue {
  final String problem;
  final String reason;
  final String correction;
  final double confidence;
  final String severity;

  const FormIssue({
    required this.problem,
    required this.reason,
    required this.correction,
    required this.confidence,
    required this.severity,
  });

  factory FormIssue.fromJson(Map<String, dynamic> json) {
    return FormIssue(
      problem: json['problem'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      correction: json['correction'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'Minor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'problem': problem,
      'reason': reason,
      'correction': correction,
      'confidence': confidence,
      'severity': severity,
    };
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppTheme.error;
      case 'moderate':
        return AppTheme.amber;
      default:
        return AppTheme.emerald;
    }
  }

  IconData get severityIcon {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Icons.error;
      case 'moderate':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

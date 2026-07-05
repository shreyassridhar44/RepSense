import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../camera_state.dart';

class RepCounterWidget extends StatefulWidget {
  final int repCount;
  final int targetReps;
  final RepPhase currentPhase;
  final bool lastRepWasCorrect;

  const RepCounterWidget({
    super.key,
    required this.repCount,
    required this.targetReps,
    required this.currentPhase,
    required this.lastRepWasCorrect,
  });

  @override
  State<RepCounterWidget> createState() => _RepCounterWidgetState();
}

class _RepCounterWidgetState extends State<RepCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _lastRepCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _lastRepCount = widget.repCount;
  }

  @override
  void didUpdateWidget(RepCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation on rep count change
    if (widget.repCount != _lastRepCount) {
      _lastRepCount = widget.repCount;
      _controller.forward().then((_) => _controller.reverse());
      
      // Shake on incorrect rep
      if (!widget.lastRepWasCorrect) {
        // TODO: Add shake animation
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rep number with glow
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.richBlack.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: widget.lastRepWasCorrect
                      ? AppTheme.emerald.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              '${widget.repCount}',
              style: TextStyle(
                color: widget.lastRepWasCorrect
                    ? AppTheme.emerald
                    : Colors.red,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Target indicator
        if (widget.targetReps > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.richBlack.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '/ ${widget.targetReps} reps',
              style: const TextStyle(
                color: AppTheme.platinum,
                fontSize: 14,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Phase indicator
        _buildPhaseIndicator(),
      ],
    );
  }

  Widget _buildPhaseIndicator() {
    String phaseText;
    Color phaseColor;

    switch (widget.currentPhase) {
      case RepPhase.down:
        phaseText = 'DESCENDING';
        phaseColor = Colors.amber;
        break;
      case RepPhase.pause:
        phaseText = 'BOTTOM';
        phaseColor = Colors.orange;
        break;
      case RepPhase.up:
        phaseText = 'ASCENDING';
        phaseColor = AppTheme.electricBlue;
        break;
      case RepPhase.lockout:
        phaseText = 'READY';
        phaseColor = AppTheme.emerald;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.richBlack.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor, width: 2),
      ),
      child: Text(
        phaseText,
        style: TextStyle(
          color: phaseColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

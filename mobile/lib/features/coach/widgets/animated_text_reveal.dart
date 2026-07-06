import 'dart:async';
import 'package:flutter/material.dart';

/// Animated text reveal widget for typing effect
class AnimatedTextReveal extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration characterDelay;
  final VoidCallback? onComplete;
  final bool animate;

  const AnimatedTextReveal({
    super.key,
    required this.text,
    this.style,
    this.characterDelay = const Duration(milliseconds: 8),
    this.onComplete,
    this.animate = true,
  });

  @override
  State<AnimatedTextReveal> createState() => _AnimatedTextRevealState();
}

class _AnimatedTextRevealState extends State<AnimatedTextReveal> {
  final StringBuffer _visibleText = StringBuffer();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.animate && widget.text.isNotEmpty) {
      _startAnimation();
    } else {
      _visibleText.write(widget.text);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    // For long text (> 300 chars), reveal in batches of 3 characters
    final batchSize = widget.text.length > 300 ? 3 : 1;

    _timer = Timer.periodic(widget.characterDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final endIndex = (_currentIndex + batchSize).clamp(0, widget.text.length);
        _visibleText.write(widget.text.substring(_currentIndex, endIndex));
        _currentIndex = endIndex;

        if (_currentIndex >= widget.text.length) {
          timer.cancel();
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _visibleText.toString(),
      style: widget.style,
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CountdownOverlay extends StatefulWidget {
  final int countdown;

  const CountdownOverlay({
    super.key,
    required this.countdown,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(CountdownOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countdown != oldWidget.countdown) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.richBlack.withOpacity(0.8),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Text(
            widget.countdown > 0 ? '${widget.countdown}' : 'GO!',
            style: TextStyle(
              color: widget.countdown > 0
                  ? AppTheme.electricBlue
                  : AppTheme.emerald,
              fontSize: 120,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: (widget.countdown > 0
                          ? AppTheme.electricBlue
                          : AppTheme.emerald)
                      .withOpacity(0.5),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

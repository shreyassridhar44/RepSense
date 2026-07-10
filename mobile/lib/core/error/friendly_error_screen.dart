import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../../shared/widgets/gradient_button.dart';

/// Friendly error screen shown in release mode when an unhandled error occurs
class FriendlyErrorScreen extends StatefulWidget {
  final FlutterErrorDetails details;

  const FriendlyErrorScreen({super.key, required this.details});

  @override
  State<FriendlyErrorScreen> createState() => _FriendlyErrorScreenState();
}

class _FriendlyErrorScreenState extends State<FriendlyErrorScreen> {
  late final String errorCode;

  @override
  void initState() {
    super.initState();
    // Generate a unique error code for support reference
    final uuid = const Uuid().v4();
    errorCode = uuid.substring(uuid.length - 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large wrench icon
                Icon(
                  Icons.build_rounded,
                  size: 64,
                  color: AppTheme.electricBlue,
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'RepSense encountered an unexpected error. Your data is safe.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Manrope',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Error code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error Code: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Text(
                        errorCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.electricBlue,
                          fontFamily: 'Manrope',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Restart button
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: () {
                      // Hot restart the app without losing the process
                      Phoenix.rebirth(context);
                    },
                    child: const Text('Restart App'),
                  ),
                ),
                const SizedBox(height: 12),

                // Send report button (optional - can be implemented later)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Capture error details and submit feedback
                      // For now, just restart
                      Phoenix.rebirth(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.electricBlue),
                      foregroundColor: AppTheme.electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Send Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

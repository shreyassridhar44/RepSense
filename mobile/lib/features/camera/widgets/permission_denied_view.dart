import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';

class PermissionDeniedView extends StatelessWidget {
  final bool isPermanent;
  final VoidCallback onRequestPermission;

  const PermissionDeniedView({
    super.key,
    required this.isPermanent,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppTheme.platinum,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.platinum,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isPermanent
                  ? 'Camera access is required for pose detection. Please grant permission in your device settings.'
                  : 'Camera access is required to analyze your exercise form in real-time.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.platinum.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: isPermanent
                  ? () => openAppSettings()
                  : onRequestPermission,
              icon: Icon(isPermanent ? Icons.settings : Icons.camera_alt),
              label: Text(isPermanent ? 'Open Settings' : 'Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Go Back',
                style: TextStyle(color: AppTheme.platinum),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

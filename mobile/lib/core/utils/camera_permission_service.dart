import 'package:permission_handler/permission_handler.dart';
import 'app_logger.dart';

/// Service to handle camera permission requests
class CameraPermissionService {
  CameraPermissionService._();
  static final CameraPermissionService instance = CameraPermissionService._();

  /// Request camera permission
  /// Returns true if granted
  Future<bool> requestCameraPermission() async {
    try {
      AppLogger.info('📷 Requesting camera permission');
      
      final status = await Permission.camera.request();
      
      if (status.isGranted) {
        AppLogger.info('✅ Camera permission granted');
        return true;
      } else if (status.isDenied) {
        AppLogger.warning('⚠️ Camera permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        AppLogger.warning('⚠️ Camera permission permanently denied');
        return false;
      }
      
      return false;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to request camera permission', e, stack);
      return false;
    }
  }

  /// Get current camera permission status without requesting
  Future<PermissionStatus> getCameraStatus() async {
    try {
      return await Permission.camera.status;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to get camera status', e, stack);
      return PermissionStatus.denied;
    }
  }

  /// Open app settings so user can grant permission manually
  Future<void> openSettings() async {
    try {
      AppLogger.info('⚙️ Opening app settings');
      await openAppSettings();
    } catch (e, stack) {
      AppLogger.error('❌ Failed to open app settings', e, stack);
    }
  }
}

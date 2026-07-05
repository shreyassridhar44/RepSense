import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Convert CameraImage to InputImage for ML Kit pose detection
/// This is the CRITICAL function that makes pose detection work
InputImage? convertCameraImageToInputImage(
  CameraImage image,
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  try {
    // Step 1: Determine InputImageRotation based on platform and sensor orientation
    final InputImageRotation rotation = _getRotation(
      camera.sensorOrientation,
      deviceOrientation,
      camera.lensDirection,
    );

    // Step 2: Determine InputImageFormat based on image format
    final InputImageFormat? format = _getFormat(image.format.group);
    if (format == null) {
      AppLogger.warning('⚠️ Unsupported image format: ${image.format.group}');
      return null;
    }

    // Step 3: Build InputImageMetadata
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width,
    );

    // Step 4: Concatenate all image planes into a single Uint8List
    final Uint8List bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  } catch (e, stack) {
    AppLogger.error('❌ Failed to convert CameraImage to InputImage', e, stack);
    return null;
  }
}

/// Determine the correct InputImageRotation
InputImageRotation _getRotation(
  int sensorOrientation,
  DeviceOrientation deviceOrientation,
  CameraLensDirection lensDirection,
) {
  // iOS: Always return Rotation0 - CoreImage handles rotation internally
  if (Platform.isIOS) {
    return InputImageRotation.rotation0deg;
  }

  // Android: Complex rotation based on sensor orientation and device orientation
  // Most Android devices have sensorOrientation of 90° (rear) or 270° (front)
  
  // For portrait mode (most common)
  if (deviceOrientation == DeviceOrientation.portraitUp) {
    if (lensDirection == CameraLensDirection.front) {
      // Front camera: sensor is typically 270°
      return InputImageRotation.rotation270deg;
    } else {
      // Rear camera: sensor is typically 90°
      return InputImageRotation.rotation90deg;
    }
  }

  // For landscape left
  if (deviceOrientation == DeviceOrientation.landscapeLeft) {
    if (lensDirection == CameraLensDirection.front) {
      return InputImageRotation.rotation180deg;
    } else {
      return InputImageRotation.rotation0deg;
    }
  }

  // For portrait down (upside down)
  if (deviceOrientation == DeviceOrientation.portraitDown) {
    if (lensDirection == CameraLensDirection.front) {
      return InputImageRotation.rotation90deg;
    } else {
      return InputImageRotation.rotation270deg;
    }
  }

  // For landscape right
  if (deviceOrientation == DeviceOrientation.landscapeRight) {
    if (lensDirection == CameraLensDirection.front) {
      return InputImageRotation.rotation0deg;
    } else {
      return InputImageRotation.rotation180deg;
    }
  }

  // Default: portrait up with rear camera
  return InputImageRotation.rotation90deg;
}

/// Determine InputImageFormat from CameraImage format
InputImageFormat? _getFormat(ImageFormatGroup formatGroup) {
  switch (formatGroup) {
    case ImageFormatGroup.nv21:
      return InputImageFormat.nv21; // Android
    case ImageFormatGroup.yuv420:
      return InputImageFormat.yuv420; // Android
    case ImageFormatGroup.bgra8888:
      return InputImageFormat.bgra8888; // iOS
    default:
      return null;
  }
}

/// Concatenate all image planes into a single byte array
Uint8List _concatenatePlanes(List<Plane> planes) {
  if (planes.isEmpty) {
    return Uint8List(0);
  }

  // For BGRA8888 (iOS): use first plane directly
  if (planes.length == 1) {
    return planes[0].bytes;
  }

  // For NV21/YUV420 (Android): concatenate all planes
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in planes) {
    allBytes.putUint8List(plane.bytes);
  }
  
  return allBytes.done().buffer.asUint8List();
}

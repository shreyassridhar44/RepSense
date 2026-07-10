import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:repsense/core/utils/app_exception.dart';
import 'package:repsense/core/utils/app_logger.dart';

/// Service for picking and processing images
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<({String base64, String mediaType})?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (file == null) return null; // User cancelled

      return await _processImage(file);
    } catch (e) {
      AppLogger.error('Failed to pick from gallery', e);
      return null;
    }
  }

  /// Pick image from camera
  Future<({String base64, String mediaType})?> pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (file == null) return null; // User cancelled

      return await _processImage(file);
    } catch (e) {
      AppLogger.error('Failed to pick from camera', e);
      return null;
    }
  }

  /// Process image: resize, compress, encode to base64
  Future<({String base64, String mediaType})> _processImage(XFile file) async {
    try {
      AppLogger.info('📸 Processing image');

      // Read image bytes
      final bytes = await file.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw AppException(message: 'Failed to decode image');
      }

      // Resize to max 1024px on longest side
      if (image.width > 1024 || image.height > 1024) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: 1024);
        } else {
          image = img.copyResize(image, height: 1024);
        }
        AppLogger.debug('Resized image to ${image.width}x${image.height}');
      }

      // Encode to JPEG at 85% quality
      final jpegBytes = img.encodeJpg(image, quality: 85);

      // Convert to base64
      final base64String = base64Encode(jpegBytes);

      // Check size (5MB limit)
      final sizeInMB = (base64String.length * 0.75) / (1024 * 1024);
      if (sizeInMB > 5) {
        throw AppException(message: 'Image is too large — try a smaller screenshot');
      }

      AppLogger.info('✅ Image processed: ${(sizeInMB).toStringAsFixed(2)}MB');

      return (base64: base64String, mediaType: 'image/jpeg');
    } catch (e) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to process image', e);
      throw AppException(message: 'Failed to process image');
    }
  }
}

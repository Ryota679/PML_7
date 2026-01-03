import 'dart:typed_data';
import 'dart:io'; // Import for file system access on mobile
import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../config/appwrite_config.dart';
import '../providers/appwrite_provider.dart';
import '../utils/logger.dart';

/// Service for handling image upload with compression
class ImageUploadService {
  final Storage _storage;

  ImageUploadService(this._storage);

  /// Pick image from device, compress it, and upload to Appwrite Storage
  /// 
  /// Returns the public URL of the uploaded image, or null if cancelled/failed
  /// 
  /// [bucketId] - The storage bucket ID to upload to
  /// [maxSizeKB] - Maximum file size in KB after compression (default: 500KB)
  /// [quality] - Initial JPEG quality (default: 85)
  Future<String?> pickAndUploadImage({
    required String bucketId,
    int maxSizeKB = 500,
    int quality = 85,
  }) async {
    try {
      // Step 1: Pick image from device
      AppLogger.info('Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null) {
        AppLogger.info('Image picker cancelled by user');
        return null; // User cancelled
      }

      final file = result.files.first;
      Uint8List originalBytes;
      
      // Read bytes differently for web vs mobile
      if (file.bytes != null) {
        // Web platform - bytes are directly available
        AppLogger.info('Reading file bytes from web (file.bytes)');
        originalBytes = file.bytes!;
      } else if (file.path != null) {
        // Mobile/Desktop platform - need to read from path
        AppLogger.info('Reading file bytes from mobile path: ${file.path}');
        final fileFromPath = File(file.path!);
        originalBytes = await fileFromPath.readAsBytes();
      } else {
        AppLogger.error('Failed to read file: no bytes or path available', null, null);
        throw Exception('Failed to read file');
      }

      final originalSizeKB = (originalBytes.length / 1024).round();
      AppLogger.info('Original image size: ${originalSizeKB}KB');

      // Step 2: Compress image
      AppLogger.info('Compressing image...');
      final compressedBytes = await _compressImage(
        originalBytes,
        maxSizeKB: maxSizeKB,
        quality: quality,
      );

      final compressedSizeKB = (compressedBytes.length / 1024).round();
      AppLogger.info('Compressed image size: ${compressedSizeKB}KB (${((1 - compressedSizeKB / originalSizeKB) * 100).toStringAsFixed(1)}% reduction)');

      // Step 3: Upload to Appwrite Storage
      AppLogger.info('Uploading image to storage...');
      final fileId = ID.unique();
      final fileName = '$fileId.jpg'; // Always save as JPEG after compression

      final uploadedFile = await _storage.createFile(
        bucketId: bucketId,
        fileId: fileId,
        file: InputFile.fromBytes(
          bytes: compressedBytes,
          filename: fileName,
        ),
      );

      // Step 4: Generate public URL
      final fileUrl = _getFileUrl(bucketId, uploadedFile.$id);
      AppLogger.info('✅ Image uploaded successfully: $fileUrl');

      return fileUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Error uploading image', e, stackTrace);
      rethrow;
    }
  }

  /// Compress image to target size
  /// 
  /// Strategy:
  /// 1. Decode image
  /// 2. Resize if too large (max 1200px)
  /// 3. Encode as JPEG with quality
  /// 4. If still > maxSizeKB, reduce quality iteratively
  Future<Uint8List> _compressImage(
    Uint8List bytes, {
    required int maxSizeKB,
    required int quality,
  }) async {
    // Decode image
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if image is too large (maintain aspect ratio)
    const maxDimension = 1200;
    if (image.width > maxDimension || image.height > maxDimension) {
      AppLogger.info('Resizing image from ${image.width}x${image.height}');
      
      if (image.width > image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
      
      AppLogger.info('Resized to ${image.width}x${image.height}');
    }

    // Compress as JPEG
    int currentQuality = quality;
    Uint8List compressed = Uint8List.fromList(
      img.encodeJpg(image, quality: currentQuality),
    );

    // Iteratively reduce quality if still too large
    final maxBytes = maxSizeKB * 1024;
    const minQuality = 70; // Don't go below this

    while (compressed.length > maxBytes && currentQuality > minQuality) {
      currentQuality -= 5;
      AppLogger.info('File still ${(compressed.length / 1024).round()}KB, reducing quality to $currentQuality');
      
      compressed = Uint8List.fromList(
        img.encodeJpg(image, quality: currentQuality),
      );
    }

    return compressed;
  }

  /// Generate public URL for uploaded file
  String _getFileUrl(String bucketId, String fileId) {
    return '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  /// Delete uploaded image from storage
  Future<void> deleteImage(String bucketId, String fileId) async {
    try {
      await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
      AppLogger.info('Image deleted: $fileId');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting image', e, stackTrace);
      rethrow;
    }
  }
}

/// Provider for ImageUploadService
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final storage = ref.watch(appwriteStorageProvider);
  return ImageUploadService(storage);
});

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  /// Compress image to reduce file size before uploading
  ///
  /// [file] - Original image file
  /// [quality] - Compression quality (0-100), default 70
  ///
  /// Returns compressed file or original if compression fails
  static Future<File> compressImage(
    File file, {
    int quality = 70,
    int minWidth = 1024,
    int minHeight = 1024,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);

        // Get file sizes for logging
        final originalSize = await file.length();
        final compressedSize = await compressedFile.length();
        final reduction = ((originalSize - compressedSize) / originalSize * 100)
            .toStringAsFixed(1);

        print(
            'Image compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} ($reduction% reduction)');

        return compressedFile;
      } else {
        print('Image compression failed, using original file');
        return file;
      }
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  /// Format bytes to human-readable format
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

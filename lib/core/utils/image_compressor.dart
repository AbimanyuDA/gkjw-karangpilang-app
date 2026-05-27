import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressor {
  /// Compress an image file to be under [targetSizeBytes] (default: 100 KB).
  /// Resizes the image so that the maximum dimension (width or height) is [maxDimension] (default: 1280).
  /// Runs on a background isolate using Flutter's [compute] to prevent UI thread blocking.
  static Future<File> compressImage(
    File file, {
    int targetSizeBytes = 100 * 1024,
    int maxDimension = 1280,
  }) async {
    final bytes = await file.readAsBytes();

    final compressedBytes = await compute(_compressTask, {
      'bytes': bytes,
      'targetSize': targetSizeBytes,
      'maxDimension': maxDimension,
    });

    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);
    return tempFile;
  }

  static Uint8List _compressTask(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final int targetSize = params['targetSize'];
    final int maxDimension = params['maxDimension'];

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // 1. Resize if image is larger than maxDimension
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width > image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    // 2. Compress quality iteratively until file size is under targetSize
    int quality = 85;
    Uint8List compressed = img.encodeJpg(image, quality: quality);

    while (compressed.length > targetSize && quality > 15) {
      quality -= 10;
      compressed = img.encodeJpg(image, quality: quality);
    }

    return compressed;
  }
}

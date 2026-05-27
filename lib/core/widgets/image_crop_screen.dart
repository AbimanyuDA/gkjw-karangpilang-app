import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio;
  final String title;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.aspectRatio,
    this.title = 'Sesuaikan Gambar',
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final _cropController = CropController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isProcessing)
            TextButton(
              onPressed: () {
                setState(() => _isProcessing = true);
                _cropController.crop();
              },
              child: const Text(
                'Pilih',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  aspectRatio: widget.aspectRatio,
                  interactive: true,
                  fixCropRect: true,
                  baseColor: Colors.black,
                  maskColor: Colors.black.withValues(alpha: 0.6),
                  onCropped: (result) {
                    if (!mounted) return;
                    setState(() => _isProcessing = false);
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        Navigator.pop(context, croppedImage);
                      case CropFailure(:final cause):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal memotong gambar: $cause',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: Colors.black,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.crop_free, color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Cubit untuk Zoom · Geser untuk Menyesuaikan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

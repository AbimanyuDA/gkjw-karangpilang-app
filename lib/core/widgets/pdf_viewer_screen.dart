// lib/core/widgets/pdf_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (pages != null && pages! > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${currentPage! + 1} / $pages',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true, // True agar proporsi jarak lebih rapi saat di-fit
            pageFling: false,
            pageSnap: false,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.WIDTH, // Penuhi ke kanan-kiri
            fitEachPage: true, // Pastikan tiap halaman ter-zoom maksimal
            onRender: (pages) {
              setState(() {
                this.pages = pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // Anda bisa menyimpan controller ini jika butuh tombol navigasi eksternal
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          if (errorMessage.isEmpty && !isReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (errorMessage.isNotEmpty)
            Center(
              child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            )
        ],
      ),
    );
  }
}

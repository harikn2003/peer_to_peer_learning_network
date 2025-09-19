import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as path;

class PdfViewerPage extends StatelessWidget {
  final File file;
  const PdfViewerPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final String fileName = path.basename(file.path);
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      body: PDFView(
        filePath: file.path,
        enableSwipe: true,       // Allow changing pages with a swipe
        swipeHorizontal: false,  // Vertical scrolling
        autoSpacing: false,      // Display pages without extra space
        pageFling: true,         // Fling between pages
        onError: (error) {
          print(error.toString());
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
      ),
    );
  }
}
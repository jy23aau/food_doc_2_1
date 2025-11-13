import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/storage.dart';

class InvoiceUploadScreen extends StatefulWidget {
  const InvoiceUploadScreen({super.key});

  @override
  State<InvoiceUploadScreen> createState() => _InvoiceUploadScreenState();
}

class _InvoiceUploadScreenState extends State<InvoiceUploadScreen> {
  String? _photoPath;
  String _extracted = '';

  Future<void> _pickImageAndScan() async {
    final p = ImagePicker();
    final file = await p.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _photoPath = file.path);

    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      final text = result.text;
      setState(() => _extracted = text);

      // crude parsing examples (supplier, dates, cost) - adjust as needed
      final supplierMatch = RegExp(
        r"Supplier[:\s]*([A-Za-z &,.0-9-]+)",
        caseSensitive: false,
      ).firstMatch(text);
      final totalMatch = RegExp(
        r"Total[:\s]*£?([0-9,.]+)",
        caseSensitive: false,
      ).firstMatch(text);
      final dateMatch = RegExp(r"(\d{2}/\d{2}/\d{2,4})").firstMatch(text);

      final parsed = {
        'supplier': supplierMatch?.group(1)?.trim() ?? 'Unknown',
        'total': totalMatch?.group(1) ?? '',
        'date': dateMatch?.group(1) ?? '',
        'raw': text,
        'photo': file.path,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await StorageService().saveRecord(
        DateTime.now().millisecondsSinceEpoch.toString(),
        parsed,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice scanned and saved')),
      );
    } catch (e) {
      setState(() => _extracted = 'OCR not available: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR failed - saved image only')),
      );
      await StorageService().saveRecord(
        DateTime.now().millisecondsSinceEpoch.toString(),
        {'photo': file.path, 'timestamp': DateTime.now().toIso8601String()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Upload & OCR')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageAndScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture invoice'),
            ),
            const SizedBox(height: 12),
            if (_photoPath != null) Image.file(File(_photoPath!), height: 180),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _extracted.isEmpty ? 'No extracted text yet' : _extracted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/storage.dart';
import '../services/notifications.dart';

class FridgeCheckScreen extends StatefulWidget {
  const FridgeCheckScreen({super.key});

  @override
  State<FridgeCheckScreen> createState() => _FridgeCheckScreenState();
}

class _FridgeCheckScreenState extends State<FridgeCheckScreen> {
  final TextEditingController _tempController = TextEditingController();
  String? _photoPath;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _lastWords = '';

  Future<void> _pickPhoto() async {
    final p = ImagePicker();
    final file = await p.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file != null) {
      setState(() => _photoPath = file.path);
    }
  }

  Future<void> _saveCheck() async {
    final temp = double.tryParse(_tempController.text.replaceAll(',', '.'));
    final record = {
      'type': 'fridge',
      'timestamp': DateTime.now().toIso8601String(),
      'temp': temp,
      'photo': _photoPath,
      'notes': _lastWords,
    };
    await StorageService().saveRecord(
      DateTime.now().millisecondsSinceEpoch.toString(),
      record,
    );
    if (temp != null && temp > 4.0) {
      await NotificationService().showAlert(
        title: 'Fridge temp alert',
        body: 'Fridge temperature $temp°C exceeds 4°C — take action',
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fridge check saved')));
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fridge Check')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Record fridge temperature (keep below 4°C)',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tempController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Temperature °C',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Photo'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _startListening,
                  icon: const Icon(Icons.mic),
                  label: const Text('Voice note'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_photoPath != null) Image.file(File(_photoPath!), height: 160),
            const SizedBox(height: 12),
            Text('Voice note: $_lastWords'),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveCheck,
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('Save Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

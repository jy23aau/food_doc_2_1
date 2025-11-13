import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/storage.dart';
import '../services/notifications.dart';

class OvenLogsScreen extends StatefulWidget {
  const OvenLogsScreen({super.key});

  @override
  State<OvenLogsScreen> createState() => _OvenLogsScreenState();
}

class _OvenLogsScreenState extends State<OvenLogsScreen> {
  final TextEditingController _tempController = TextEditingController();
  String? _photoPath;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _notes = '';
  String _mode = 'hot_hold'; // or 'calibration'

  Future<void> _pickPhoto() async {
    final p = ImagePicker();
    final file = await p.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (result) {
          setState(() => _notes = result.recognizedWords);
        },
      );
    }
  }

  Future<void> _saveLog() async {
    final temp = double.tryParse(_tempController.text.replaceAll(',', '.'));
    final record = {
      'type': 'oven',
      'mode': _mode,
      'timestamp': DateTime.now().toIso8601String(),
      'temp': temp,
      'photo': _photoPath,
      'notes': _notes,
    };
    await StorageService().saveCheckpoint(record);

    if (_mode == 'hot_hold') {
      // For hot-holding, ensure temp >= 60°C
      if (temp == null || temp < 60.0) {
        await NotificationService().showAlert(
          title: 'Oven hot-hold alert',
          body:
              'Hot-holding temperature ${temp ?? 'N/A'}°C is below 60°C — unsafe',
        );
      }
    }

    if (_mode == 'calibration') {
      // simplistic: if calibration recorded with abnormally high/low temp, alert
      if (temp != null && (temp < 30.0 || temp > 300.0)) {
        await NotificationService().showAlert(
          title: 'Oven calibration alert',
          body: 'Calibration reading $temp°C looks abnormal',
        );
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Oven log saved')));
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
      appBar: AppBar(title: const Text('Oven Logs')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Record oven temperature and calibration',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [_mode == 'hot_hold', _mode == 'calibration'],
              onPressed: (i) =>
                  setState(() => _mode = i == 0 ? 'hot_hold' : 'calibration'),
              children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('Hot hold')),
                Padding(padding: EdgeInsets.all(8), child: Text('Calibration')),
              ],
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
            const SizedBox(height: 8),
            Text('Notes: $_notes'),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveLog,
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('Save Oven Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

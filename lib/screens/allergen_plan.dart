import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/storage.dart';
import '../services/notifications.dart';

const List<String> majorAllergens = [
  'Celery',
  'Cereals (gluten)',
  'Crustaceans',
  'Eggs',
  'Fish',
  'Lupin',
  'Milk',
  'Molluscs',
  'Mustard',
  'Nuts',
  'Peanuts',
  'Sesame',
  'Soya',
  'Sulphur dioxide',
];

class AllergenPlanScreen extends StatefulWidget {
  const AllergenPlanScreen({super.key});

  @override
  State<AllergenPlanScreen> createState() => _AllergenPlanScreenState();
}

class _AllergenPlanScreenState extends State<AllergenPlanScreen> {
  String? _selected;
  bool _segregationOk = true;
  bool _labelingOk = true;
  bool _crossContamRisk = false;
  String? _photoPath;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _notes = '';

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

  Future<void> _savePlan() async {
    final record = {
      'type': 'allergen',
      'allergen': _selected ?? 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
      'segregation_ok': _segregationOk,
      'labeling_ok': _labelingOk,
      'cross_contam_risk': _crossContamRisk,
      'photo': _photoPath,
      'notes': _notes,
    };
    await StorageService().saveAllergen(record);

    if (!_segregationOk || !_labelingOk || _crossContamRisk) {
      await NotificationService().showAlert(
        title: 'Allergen violation',
        body: 'Potential allergen handling issue: ${_selected ?? 'Unknown'}',
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Allergen check saved')));
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allergen Plan')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select allergen and verify segregation, labeling, and risk',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selected,
              items: majorAllergens
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Allergen',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Segregation OK'),
              value: _segregationOk,
              onChanged: (v) => setState(() => _segregationOk = v),
            ),
            SwitchListTile(
              title: const Text('Labeling OK'),
              value: _labelingOk,
              onChanged: (v) => setState(() => _labelingOk = v),
            ),
            SwitchListTile(
              title: const Text('Cross-contamination risk'),
              value: _crossContamRisk,
              onChanged: (v) => setState(() => _crossContamRisk = v),
            ),
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
            const SizedBox(height: 8),
            if (_photoPath != null) Image.file(File(_photoPath!), height: 140),
            const SizedBox(height: 8),
            Text('Notes: $_notes'),
            const Spacer(),
            ElevatedButton(
              onPressed: _savePlan,
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('Save Allergen Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  String _selectedFridge = 'Fridge 1';
  bool _isOpening = true; // true for opening, false for closing
  bool _showHistory = false;

  final List<String> fridges = ['Fridge 1', 'Fridge 2', 'Fridge 3'];

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
      'fridge': _selectedFridge,
      'timestamp': DateTime.now().toIso8601String(),
      'checkType': _isOpening ? 'opening' : 'closing',
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
        body: '$_selectedFridge temperature $temp°C exceeds 4°C — take action',
      );
    }
    
    // Reset form
    _tempController.clear();
    setState(() {
      _photoPath = null;
      _lastWords = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedFridge ${_isOpening ? 'opening' : 'closing'} check saved')),
      );
    }
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

  List<Map<String, dynamic>> _getAllFridgeHistory() {
    return StorageService().queryRecords(type: 'fridge');
  }

  String _formatDateTime(String iso8601) {
    try {
      final dt = DateTime.parse(iso8601);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso8601;
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
      appBar: AppBar(title: const Text('Fridge Checks')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _showHistory ? _buildHistoryView() : _buildCheckForm(),
      ),
    );
  }

  Widget _buildCheckForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Record fridge temperature (keep below 4°C)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Fridge selector
          const Text('Select Fridge:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: fridges.map((fridge) {
              final isSelected = _selectedFridge == fridge;
              return ChoiceChip(
                label: Text(fridge, style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFridge = fridge);
                },
                backgroundColor: Colors.grey[300],
                selectedColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Check type selector
          const Text('Check Type:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(label: Text('Opening'), value: true),
                    ButtonSegment(label: Text('Closing'), value: false),
                  ],
                  selected: <bool>{_isOpening},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() => _isOpening = newSelection.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temperature input
          TextField(
            controller: _tempController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Temperature °C',
              border: OutlineInputBorder(),
              hintText: 'Enter temperature',
            ),
          ),
          const SizedBox(height: 12),

          // Photo and voice buttons
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
                label: const Text('Voice'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Photo preview
          if (_photoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(_photoPath!), height: 160, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),

          // Voice note display
          if (_lastWords.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Voice note:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_lastWords),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Save and view history buttons
          ElevatedButton(
            onPressed: _saveCheck,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
            ),
            child: const Text('Save Check', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _showHistory = true);
            },
            icon: const Icon(Icons.history),
            label: const Text('View History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    final allHistory = _getAllFridgeHistory();
    final sorted = allHistory
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) {
        final timeA = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime(1970);
        final timeB = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime(1970);
        return timeB.compareTo(timeA); // newest first
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fridge Temperature History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _showHistory = false);
              },
              child: const Text('Back'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No fridge checks recorded yet', textAlign: TextAlign.center),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final record = sorted[index];
                final fridge = record['fridge'] ?? 'Unknown';
                final checkType = record['checkType'] ?? 'check';
                final temp = record['temp'];
                final timestamp = record['timestamp'] ?? '';
                final notes = record['notes'] ?? '';
                final isBreach = (temp is num) && temp > 4.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: isBreach ? Colors.red[50] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fridge,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isBreach ? Colors.red : Colors.black,
                              ),
                            ),
                            Chip(
                              label: Text(
                                checkType.toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: checkType == 'opening' ? Colors.blue[100] : Colors.amber[100],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Temp: ${temp?.toString() ?? 'N/A'}°C',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isBreach ? Colors.red : Colors.green,
                              ),
                            ),
                            Text(
                              _formatDateTime(timestamp),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notes: $notes',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

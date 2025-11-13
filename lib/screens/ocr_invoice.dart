import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/storage.dart';

class OcrInvoiceScreen extends StatefulWidget {
  const OcrInvoiceScreen({super.key});

  @override
  State<OcrInvoiceScreen> createState() => _OcrInvoiceScreenState();
}

class _OcrInvoiceScreenState extends State<OcrInvoiceScreen> {
  String? _imagePath;
  List<Map<String, dynamic>> _parsedItems = [];
  String _rawText = '';
  bool _loading = false;

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() {
      _imagePath = file.path;
      _parsedItems = [];
      _rawText = '';
    });
    await _runOcr(file.path);
  }

  Future<void> _runOcr(String path) async {
    setState(() => _loading = true);
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    _rawText = recognizedText.text;

    final lines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        lines.add(line.text.trim());
      }
    }

    _parsedItems = _parseLines(lines);
    await textRecognizer.close();
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _parseLines(List<String> lines) {
    final List<Map<String, dynamic>> out = [];
    final qtyReg = RegExp(r'([0-9]+(?:[\.,][0-9]+)?)\s*(kg|g|l|ml|pkt|pkts|pcs|pack|packs|ltr)?', caseSensitive: false);
    for (final l in lines) {
      final m = qtyReg.firstMatch(l);
      if (m != null) {
        final qtyRaw = m.group(1)!.replaceAll(',', '.');
        final qty = double.tryParse(qtyRaw) ?? 0;
        final unit = m.group(2) ?? '';
        final name = l.substring(0, m.start).replaceAll(RegExp(r'[:\-\t]+'), '').trim();
        if (name.isNotEmpty) {
          out.add({
            'name': name,
            'quantity': qty,
            'unit': unit,
            'include': true,
            'matchedId': null,
            'confidence': 0.0,
          });
        }
      }
    }

    // If nothing parsed, try fallback splitting by lines and taking words
    if (out.isEmpty) {
      for (final l in lines) {
        if (l.trim().isEmpty) continue;
        out.add({'name': l.trim(), 'quantity': 1.0, 'unit': '', 'include': true, 'matchedId': null, 'confidence': 0.0});
      }
    }

    // Try to fuzzy match to existing inventory
    final inventory = StorageService().queryRecords(type: 'inventory');
    for (final item in out) {
      final name = (item['name'] as String).toLowerCase();
      double bestScore = 0.0;
      String? bestId;
      for (final inv in inventory) {
        final invName = (inv['name'] ?? '').toString().toLowerCase();
        final score = _simpleSimilarity(name, invName);
        if (score > bestScore) {
          bestScore = score;
          bestId = inv['id'] ?? null;
        }
      }
      item['confidence'] = bestScore;
      if (bestScore >= 0.6) item['matchedId'] = bestId;
    }

    return out;
  }

  double _simpleSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final aWords = a.split(RegExp(r'\s+')).toSet();
    final bWords = b.split(RegExp(r'\s+')).toSet();
    final common = aWords.intersection(bWords).length;
    final avg = (aWords.length + bWords.length) / 2.0;
    return common / (avg == 0 ? 1 : avg);
  }

  Future<void> _confirmAndApply() async {
    if (_imagePath == null) return;
    final invoiceId = 'invoice_${DateTime.now().millisecondsSinceEpoch}';
    final invoiceRecord = {
      'id': invoiceId,
      'type': 'invoice_ocr',
      'timestamp': DateTime.now().toIso8601String(),
      'photo': _imagePath,
      'rawText': _rawText,
      'parsedItems': _parsedItems,
      'user': 'local_user',
      'synced': false,
    };
    await StorageService().saveRecord(invoiceId, invoiceRecord);

    // Apply stock updates
    for (final p in _parsedItems) {
      if (p['include'] != true) continue;
      final qty = (p['quantity'] is num) ? p['quantity'] * 1.0 : double.tryParse(p['quantity'].toString()) ?? 0.0;
      final unit = p['unit'] ?? '';
      final name = p['name'] ?? 'Unnamed';
      String invId = p['matchedId'] ?? '';
      if (invId.isEmpty) {
        // create new inventory item
        invId = 'inv_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}';
        final newInv = {'id': invId, 'type': 'inventory', 'name': name, 'unit': unit, 'current_quantity': qty};
        await StorageService().saveRecord(invId, newInv);
      } else {
        final existing = StorageService().getRecord(invId);
        if (existing != null) {
          final before = (existing['current_quantity'] ?? 0) as num;
          final after = before + qty;
          existing['current_quantity'] = after;
          await StorageService().updateRecord(invId, existing);
        }
      }

      // create stock_in record
      final stockId = 'stock_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}';
      final stockRec = {
        'id': stockId,
        'type': 'stock_in',
        'source': 'invoice_ocr',
        'invoiceId': invoiceId,
        'itemName': name,
        'itemId': invId,
        'deltaQuantity': qty,
        'unit': unit,
        'timestamp': DateTime.now().toIso8601String(),
        'user': 'local_user',
      };
      await StorageService().saveRecord(stockId, stockRec);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice processed and stock updated')));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imagePath != null) Image.file(File(_imagePath!), height: 160, fit: BoxFit.cover),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Invoice'),
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _parsedItems.isNotEmpty) ...[
              const Text('Parsed Items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedItems.length,
                  itemBuilder: (context, i) {
                    final it = _parsedItems[i];
                    return Card(
                      child: ListTile(
                        title: Text('${it['name']}'),
                        subtitle: Text('Qty: ${it['quantity']} ${it['unit']} • Confidence: ${(it['confidence'] as double).toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final res = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (ctx) {
                                final nameCtrl = TextEditingController(text: it['name']);
                                final qtyCtrl = TextEditingController(text: it['quantity'].toString());
                                final unitCtrl = TextEditingController(text: it['unit']);
                                return AlertDialog(
                                  title: const Text('Edit Item'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                                      TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
                                      TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx, {'name': nameCtrl.text, 'quantity': double.tryParse(qtyCtrl.text) ?? it['quantity'], 'unit': unitCtrl.text});
                                        },
                                        child: const Text('Save'))
                                  ],
                                );
                              },
                            );
                            if (res != null) {
                              setState(() {
                                it['name'] = res['name'];
                                it['quantity'] = res['quantity'];
                                it['unit'] = res['unit'];
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _confirmAndApply,
                child: const Padding(padding: EdgeInsets.all(12.0), child: Text('Confirm & Add to Stock')),
              ),
            ],
            if (!_loading && _parsedItems.isEmpty) const Text('No parsed items yet — capture an invoice to begin.'),
          ],
        ),
      ),
    );
  }
}

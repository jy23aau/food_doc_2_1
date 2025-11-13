import 'package:flutter/material.dart';
import '../services/storage.dart';
import 'ocr_invoice.dart';

class CurrentInventoryScreen extends StatefulWidget {
  const CurrentInventoryScreen({super.key});

  @override
  State<CurrentInventoryScreen> createState() => _CurrentInventoryScreenState();
}

class _CurrentInventoryScreenState extends State<CurrentInventoryScreen> {
  bool _isCreating = false;

  Future<void> _createProductionOrder(String shift) async {
    setState(() => _isCreating = true);
    final record = {
      'type': 'production_order',
      'shift': shift,
      'timestamp': DateTime.now().toIso8601String(),
      'items': <Map<String, dynamic>>[],
    };

    await StorageService().saveRecord(
      'prod_${DateTime.now().millisecondsSinceEpoch}',
      record,
    );

    setState(() => _isCreating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$shift production order created')),
      );
    }
  }

  List<Map<String, dynamic>> _loadOrders() {
    final all = StorageService().queryRecords(type: 'production_order');
    all.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime(1970);
      final tb = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime(1970);
      return tb.compareTo(ta);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final orders = _loadOrders();
    final inventory = StorageService().queryRecords(type: 'inventory');

    return Scaffold(
      appBar: AppBar(title: const Text('Current Inventory & Production')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stock In House
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Stock In House', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    inventory.isEmpty
                        ? const Text('No inventory records yet')
                        : Column(
                            children: inventory.take(6).map((inv) {
                              final name = inv['name'] ?? 'Unknown';
                              final qty = inv['current_quantity'] ?? 0;
                              final unit = inv['unit'] ?? '';
                              return ListTile(
                                dense: true,
                                title: Text(name),
                                trailing: Text('$qty ${unit}'),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OcrInvoiceScreen()),
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('OCR Invoice / Add Delivery'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Ingredients needed for bakery items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Ingredients Needed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Common ingredients grouped by product:'),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: const Text('Sourdough Bread'),
                      children: const [
                        ListTile(title: Text('Strong white bread flour')),
                        ListTile(title: Text('Wholemeal flour')),
                        ListTile(title: Text('Water')),
                        ListTile(title: Text('Salt')),
                        ListTile(title: Text('Sourdough starter')),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Croissants (incl. Pain au Chocolat, Almond)'),
                      children: const [
                        ListTile(title: Text('Strong flour')),
                        ListTile(title: Text('Milk')),
                        ListTile(title: Text('Sugar')),
                        ListTile(title: Text('Salt')),
                        ListTile(title: Text('Butter (dough & lamination)')),
                        ListTile(title: Text('Sourdough starter')),
                        ListTile(title: Text('Chocolate')),
                        ListTile(title: Text('Almond extract')),
                        ListTile(title: Text('Ground almonds')),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Chocolate Brownies'),
                      children: const [
                        ListTile(title: Text('Flour (all-purpose)')),
                        ListTile(title: Text('Sugar')),
                        ListTile(title: Text('Cocoa solids')),
                        ListTile(title: Text('Eggs')),
                        ListTile(title: Text('Unsalted butter')),
                        ListTile(title: Text('Chocolate')),
                        ListTile(title: Text('Vanilla extract')),
                        ListTile(title: Text('Icing sugar')),
                        ListTile(title: Text('Salt')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Production Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Create a production order for the morning or evening shift.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : () => _createProductionOrder('Morning'),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              child: Text('Morning Order'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : () => _createProductionOrder('Evening'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              child: Text('Evening Order'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Existing Production Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('No production orders yet'))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final o = orders[index];
                        final shift = o['shift'] ?? 'Unknown';
                        final ts = o['timestamp'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('$shift production'),
                            subtitle: Text(ts.toString()),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

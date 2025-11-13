import 'package:flutter/material.dart';
import '../services/storage.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Current Inventory & Production')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

import 'package:flutter/material.dart';
import '../services/storage.dart';

class ProductionOrdersScreen extends StatefulWidget {
  const ProductionOrdersScreen({super.key});

  @override
  State<ProductionOrdersScreen> createState() => _ProductionOrdersScreenState();
}

class _ProductionOrdersScreenState extends State<ProductionOrdersScreen> {
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
      final ta =
          DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime(1970);
      final tb =
          DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime(1970);
      return tb.compareTo(ta);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final orders = _loadOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Orders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Create New Order Buttons
            const Text(
              'Create New Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isCreating
                  ? null
                  : () => _createProductionOrder('Morning'),
              child: const Text(
                'Morning Shift Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isCreating
                  ? null
                  : () => _createProductionOrder('Evening'),
              child: const Text(
                'Evening Shift Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Existing Production Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text('No production orders yet'),
                    )
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final shift = order['shift'] ?? 'Unknown';
                        final timestamp = order['timestamp'] ?? '';
                        final dt = DateTime.tryParse(timestamp);
                        final dateStr = dt != null
                            ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : timestamp;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text('$shift Shift'),
                            subtitle: Text(dateStr),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order details for $shift'),
                                ),
                              );
                            },
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

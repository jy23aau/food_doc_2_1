import 'package:flutter/material.dart';
import '../widgets/big_button.dart';
import 'fridge_check.dart';
import 'invoice_upload.dart';
import 'sync.dart';
import 'oven_logs.dart';
import 'allergen_plan.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bread of Life — Compliance Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  BigButton(
                    label: 'Fridge Checks',
                    icon: Icons.kitchen,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FridgeCheckScreen(),
                      ),
                    ),
                  ),
                  BigButton(
                    label: 'Oven Logs',
                    icon: Icons.local_fire_department,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OvenLogsScreen()),
                    ),
                  ),
                  BigButton(
                    label: 'Allergen Plans',
                    icon: Icons.warning,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllergenPlanScreen(),
                      ),
                    ),
                  ),
                  BigButton(
                    label: 'Pest Checks',
                    icon: Icons.bug_report,
                    onPressed: () {},
                  ),
                  BigButton(
                    label: 'Cleaning Rotas',
                    icon: Icons.cleaning_services,
                    onPressed: () {},
                  ),
                  BigButton(
                    label: 'Staff Training',
                    icon: Icons.school,
                    onPressed: () {},
                  ),
                  BigButton(
                    label: 'Invoice OCR',
                    icon: Icons.receipt_long,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvoiceUploadScreen(),
                      ),
                    ),
                  ),
                  BigButton(
                    label: 'Cloud Sync',
                    icon: Icons.cloud_upload,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SyncScreen()),
                    ),
                  ),
                  BigButton(
                    label: 'Reports / Email',
                    icon: Icons.email,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Large buttons and simple workflow for busy bakery staff',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:food_doc_2_1/checklist_screen.dart';
import 'package:food_doc_2_1/screens/inventory_screen.dart';
import 'package:food_doc_2_1/screens/production_orders_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for checklists
    final List<String> checklists = [
      'Morning Opening Checklist',
      'Daily Temperature Checks',
      'Cleaning and Sanitation Schedule',
      'Closing Duties',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Today\'s Tasks',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFC107), // Vibrant yellow
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Big Buttons Section
              const SizedBox(height: 8),
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Current Inventory Button
              _buildTrendyButton(
                context,
                label: 'Current Inventory',
                icon: Icons.inventory_2,
                backgroundColor: const Color(0xFFFFC107), // Vibrant yellow
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CurrentInventoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Production Orders Button
              _buildTrendyButton(
                context,
                label: 'Production Orders',
                icon: Icons.production_quantity_limits,
                backgroundColor: const Color(0xFFFF6B35), // Energetic orange
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductionOrdersScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Fridge Checks Button
              _buildTrendyButton(
                context,
                label: 'Fridge Checks',
                icon: Icons.kitchen,
                backgroundColor: const Color(0xFF00D4FF), // Sky blue
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fridge Checks coming soon')),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Daily Tasks Section
              const Text(
                'Daily Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Checklists ListView
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFFFC107),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFFFFC107),
                      ),
                      title: Text(
                        checklists[index],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFFFC107),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChecklistScreen(
                              checklistName: checklists[index],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendyButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

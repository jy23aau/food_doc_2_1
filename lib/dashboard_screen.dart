import 'package:flutter/material.dart';
import 'package:food_doc_2_1/checklist_screen.dart';

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
        title: const Text('Today\'s Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: checklists.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(checklists[index]),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChecklistScreen(checklistName: checklists[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

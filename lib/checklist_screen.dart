import 'package:flutter/material.dart';

class ChecklistScreen extends StatefulWidget {
  final String checklistName;

  const ChecklistScreen({super.key, required this.checklistName});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // Dummy data for checklist items
  final Map<String, List<String>> _checklistItems = {
    'Morning Opening Checklist': [
      'Check all lights are working',
      'Check for any signs of pests',
      'Ensure all surfaces are clean',
    ],
    'Daily Temperature Checks': [
      'Fridge 1 Temperature',
      'Fridge 2 Temperature',
      'Freezer 1 Temperature',
    ],
    'Cleaning and Sanitation Schedule': [
      'Clean and sanitize all food preparation surfaces',
      'Clean and sanitize all equipment',
      'Empty all bins',
    ],
    'Closing Duties': [
      'Turn off all equipment',
      'Lock all doors and windows',
      'Set the alarm',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = _checklistItems[widget.checklistName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checklistName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ListTile(
                    title: Text(items[index]),
                    // Add interactive elements like checkboxes or text fields here
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Save checklist data
                Navigator.pop(context);
              },
              child: const Text('Complete Checklist'),
            ),
          ),
        ],
      ),
    );
  }
}

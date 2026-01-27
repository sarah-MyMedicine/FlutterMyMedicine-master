import 'package:flutter/material.dart';

class BloodPressurePage extends StatelessWidget {
  const BloodPressurePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder implementation: list of recent readings
    final readings = [
      '120/80 - Today',
      '118/78 - Yesterday',
      '125/82 - 2 days ago',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Pressure')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: readings.length,
        itemBuilder: (context, i) => Card(child: ListTile(title: Text(readings[i]))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: add new reading modal
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
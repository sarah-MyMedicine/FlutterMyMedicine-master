import 'package:flutter/material.dart';

class BloodSugarPage extends StatelessWidget {
  const BloodSugarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final readings = [
      '95 mg/dL - Today',
      '110 mg/dL - Yesterday',
      '100 mg/dL - 2 days ago',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Sugar')),
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
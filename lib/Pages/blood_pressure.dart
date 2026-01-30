import 'package:flutter/material.dart';

class BloodPressurePage extends StatefulWidget {
  const BloodPressurePage({super.key});

  @override
  State<BloodPressurePage> createState() => _BloodPressurePageState();
}

class _BloodPressurePageState extends State<BloodPressurePage> {
  // Sample data structure
  late List<Map<String, dynamic>> readings;

  @override
  void initState() {
    super.initState();
    readings = [
      {'systolic': 120, 'diastolic': 80, 'date': 'Today'},
      {'systolic': 118, 'diastolic': 78, 'date': 'Yesterday'},
      {'systolic': 125, 'diastolic': 82, 'date': '2 days ago'},
    ];
  }

  void _deleteReading(int index) {
    setState(() {
      readings.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blood pressure reading deleted')),
    );
  }

  void _editReading(int index) {
    // TODO: Open edit modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit reading: ${readings[index]['systolic']}/${readings[index]['diastolic']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Pressure')),
      body: readings.isEmpty
          ? Center(
              child: Text(
                'No readings recorded',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: readings.length,
              itemBuilder: (context, i) => Card(
                child: ListTile(
                  title: Text(
                    '${readings[i]['systolic']}/${readings[i]['diastolic']} mmHg',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(readings[i]['date']),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReading(i);
                      } else if (value == 'delete') {
                        _deleteReading(i);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
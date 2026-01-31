import 'package:flutter/material.dart';

class BloodSugarPage extends StatefulWidget {
  const BloodSugarPage({super.key});

  @override
  State<BloodSugarPage> createState() => _BloodSugarPageState();
}

class _BloodSugarPageState extends State<BloodSugarPage> {
  // Sample data structure
  late List<Map<String, dynamic>> readings;

  @override
  void initState() {
    super.initState();
    readings = [
      {'value': 95, 'unit': 'mg/dL', 'date': 'Today'},
      {'value': 110, 'unit': 'mg/dL', 'date': 'Yesterday'},
      {'value': 100, 'unit': 'mg/dL', 'date': '2 days ago'},
    ];
  }

  void _deleteReading(int index) {
    setState(() {
      readings.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blood sugar reading deleted')),
    );
  }

  void _editReading(int index) {
    // TODO: Open edit modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit reading: ${readings[index]['value']} ${readings[index]['unit']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Sugar')),
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
                    '${readings[i]['value']} ${readings[i]['unit']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(readings[i]['date']),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () async {
                      final RenderBox button = context.findRenderObject() as RenderBox;
                      final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      );
                      
                      final String? selected = await showMenu<String>(
                        context: context,
                        position: position,
                        items: [
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
                      );
                      
                      if (selected == 'edit') {
                        _editReading(i);
                      } else if (selected == 'delete') {
                        _deleteReading(i);
                      }
                    },
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
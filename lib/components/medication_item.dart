import 'dart:io';
import 'package:flutter/material.dart';

class MedicationItem extends StatelessWidget {
  final String name;
  final String dose;
  final String? imagePath;
  final String? intervalHours;
  final String? startTime;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationItem({
    super.key,
    required this.name,
    required this.dose,
    this.imagePath,
    this.intervalHours,
    this.startTime,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: imagePath != null
            ? ClipOval(
                child: Image.file(
                  File(imagePath!),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  cacheWidth: 80,
                  cacheHeight: 80,
                ),
              )
            : CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.secondary.withAlpha(38),
                child: Icon(Icons.medication, color: Theme.of(context).colorScheme.secondary),
              ),
        title: Text(name, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text('$dose · every ${intervalHours ?? '24'}h${startTime != null ? ' · $startTime' : ''}', style: Theme.of(context).textTheme.bodyMedium),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit?.call();
            } else if (value == 'delete') {
              onDelete?.call();
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
        onTap: onTap,
      ),
    );
  }
}

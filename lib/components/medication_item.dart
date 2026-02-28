import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/adherence_provider.dart';

class MedicationItem extends StatelessWidget {
  final String name;
  final String dose;
  final String? imagePath;
  final String? intervalHours;
  final String? startTime;
  final String? startDate;
  final String? chronicDisease;
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
    this.startDate,
    this.chronicDisease,
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
        subtitle: Consumer<AdherenceProvider>(
          builder: (context, adherenceProvider, child) {
            // Calculate adherence score
            final intervalHrs = int.tryParse(intervalHours ?? '24') ?? 24;
            DateTime? medStartDate;
            if (startDate != null) {
              try {
                medStartDate = DateTime.parse(startDate!);
              } catch (e) {
                medStartDate = null;
              }
            }
            
            final adherenceScore = adherenceProvider.calculateMedicationAdherence(
              medicationName: name,
              intervalHours: intervalHrs,
              startDate: medStartDate,
              daysToCheck: 30,
            );
            
            // Determine color based on score
            Color? scoreColor;
            IconData? scoreIcon;
            if (adherenceScore >= 80) {
              scoreColor = Colors.green[700];
              scoreIcon = Icons.check_circle;
            } else if (adherenceScore >= 60) {
              scoreColor = Colors.orange[700];
              scoreIcon = Icons.warning;
            } else {
              scoreColor = Colors.red[700];
              scoreIcon = Icons.error;
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dose · كل ${intervalHours ?? '24'} ساعة${startTime != null ? ' · $startTime' : ''}', style: Theme.of(context).textTheme.bodyMedium),
                if (chronicDisease != null && chronicDisease!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            chronicDisease!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(scoreIcon, size: 14, color: scoreColor),
                      const SizedBox(width: 4),
                      Text(
                        'الالتزام: ${adherenceScore.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
                  Text('تعديل'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('حذف', style: TextStyle(color: Colors.red)),
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

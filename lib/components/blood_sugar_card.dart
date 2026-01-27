import 'package:flutter/material.dart';

class BloodSugarCard extends StatelessWidget {
  final VoidCallback onTap;
  const BloodSugarCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: SizedBox(
          width: 160,
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blood Sugar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Last: 95 mg/dL', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
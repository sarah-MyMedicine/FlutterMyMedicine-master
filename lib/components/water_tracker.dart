import 'package:flutter/material.dart';

class WaterTracker extends StatelessWidget {
  final int glasses;
  const WaterTracker({super.key, this.glasses = 4});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.water, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            Text('Water: $glasses glasses today', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            ElevatedButton(onPressed: () {}, child: const Text('Track'))
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import 'medication_list.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(icon: Icons.add_alert, label: 'Reminder'),
          MyMedicinesTile(),
          _ActionButton(icon: Icons.water, label: 'Hydration'),
          _ActionButton(icon: Icons.analytics, label: 'Reports'),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () {},
          mini: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          heroTag: label,
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// A special tile that previews the patient's medicines and opens the
/// medication list when tapped. Any medicine added through the app will
/// automatically be reflected here because it listens to `MedicationProvider`.
class MyMedicinesTile extends StatelessWidget {
  const MyMedicinesTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medProv, _) {
        final items = medProv.items;
        return GestureDetector(
          onTap: () {
            // Open the full medication list as a bottom sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.85,
                child: MedicationList(),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF36BBA0),
                      child: const Icon(Icons.local_pharmacy, color: Colors.white),
                    ),
                    if (items.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                          child: Text('${items.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('أدويتي', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

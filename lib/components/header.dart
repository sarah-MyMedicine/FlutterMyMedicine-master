import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.onPrimary, child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'My Medicine',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../sim/sim_isolate.dart';

class Inspector extends StatelessWidget {
  const Inspector({super.key, required this.selected});

  final EntitySnapshot? selected;

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return const Card(
        color: Colors.black45,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Tap an entity to inspect'),
        ),
      );
    }
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected!.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ID ${selected!.id}'),
            if (selected!.extra != null) ...[
              const SizedBox(height: 8),
              for (final entry in selected!.extra!.entries)
                Text('${entry.key}: ${entry.value is double ? (entry.value as double).toStringAsFixed(2) : entry.value}'),
            ],
          ],
        ),
      ),
    );
  }
}

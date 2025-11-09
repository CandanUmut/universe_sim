import 'package:flutter/material.dart';

import '../../sim/scenarios.dart';

class ScenarioPickerDialog extends StatelessWidget {
  const ScenarioPickerDialog({super.key, required this.library});

  final ScenarioLibrary library;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Select Scenario'),
      children: library.scenarios
          .map(
            (scenario) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(scenario),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scenario.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(scenario.description, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

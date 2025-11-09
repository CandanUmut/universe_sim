import 'package:flutter/material.dart';

import '../../sim/scenarios.dart';

class NewGameDialog extends StatefulWidget {
  const NewGameDialog({super.key, required this.onScenarioSelected});

  final ValueChanged<ScenarioDefinition> onScenarioSelected;

  @override
  State<NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  late Future<List<ScenarioDefinition>> _future;

  @override
  void initState() {
    super.initState();
    _future = ScenarioLibrary.load().then((lib) => lib.scenarios);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Game'),
      content: SizedBox(
        width: 360,
        height: 360,
        child: FutureBuilder<List<ScenarioDefinition>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final scenarios = snapshot.data!;
            return ListView.builder(
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                return ListTile(
                  title: Text(scenario.name),
                  subtitle: Text(scenario.description),
                  onTap: () {
                    widget.onScenarioSelected(scenario);
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

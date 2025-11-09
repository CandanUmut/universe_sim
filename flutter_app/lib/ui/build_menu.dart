import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../render/game_root.dart';

class BuildMenu extends StatelessWidget {
  const BuildMenu({
    super.key,
    required this.onPlaceStar,
    required this.onSeedLife,
    required this.onBuildRelay,
    required this.game,
  });

  final void Function(vm.Vector2 position) onPlaceStar;
  final void Function(int entityId) onSeedLife;
  final void Function(int entityId) onBuildRelay;
  final GameRoot game;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Build', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                onPlaceStar(game.cameraController.position.clone());
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Place Star'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                final selected = game.selected;
                if (selected != null) {
                  onSeedLife(selected.id);
                }
              },
              icon: const Icon(Icons.eco_outlined),
              label: const Text('Seed Life'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                final selected = game.selected;
                if (selected != null) {
                  onBuildRelay(selected.id);
                }
              },
              icon: const Icon(Icons.sensors),
              label: const Text('Deploy Relay'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../render/game_root.dart';
import '../render/painters/overlays.dart';
import '../sim/sim_isolate.dart';
import 'build_menu.dart';
import 'inspector.dart';
import 'minimap.dart';
import 'overlays_panel.dart';
import 'tech_tree.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  static const id = 'hud';
  final GameRoot game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildTopBar(context),
        Positioned(
          left: 16,
          bottom: 16,
          child: BuildMenu(
            onPlaceStar: (Vector2 pos) => game.placeStar(pos),
            onSeedLife: (entityId) => game.seedLife(entityId),
            onBuildRelay: (entityId) => game.buildRelay(entityId),
            game: game,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ValueListenableBuilder<OverlayMode>(
            valueListenable: game.overlayNotifier,
            builder: (context, mode, _) {
              return OverlaysPanel(
                currentMode: mode,
                onChanged: (value) {
                  game.setOverlay(value);
                },
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          top: 80,
          child: SizedBox(
            width: 240,
          child: ValueListenableBuilder<EntitySnapshot?>(
            valueListenable: game.selectedNotifier,
            builder: (context, value, _) {
              return Inspector(selected: value);
            },
          ),
          ),
        ),
        Positioned(
          left: 16,
          top: 80,
          child: ValueListenableBuilder<SimSnapshot?>(
            valueListenable: game.snapshotNotifier,
            builder: (context, snapshot, _) {
              return Minimap(
                snapshot: snapshot,
                onFocus: (Vector2 pos) => game.cameraController.focus(pos),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: ValueListenableBuilder<SimSnapshot?>(
        valueListenable: game.snapshotNotifier,
        builder: (context, snapshot, _) {
          final starlight = snapshot?.starlight ?? game.starlight;
          final order = snapshot?.order ?? game.order;
          return Row(
            children: [
              _resourceChip(Icons.wb_sunny_outlined, 'Starlight', starlight),
              const SizedBox(width: 12),
              _resourceChip(Icons.device_hub_outlined, 'Order', order),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => TechTreeDialog(game: game),
                  );
                },
                icon: const Icon(Icons.auto_graph),
                label: const Text('Tech Tree'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _resourceChip(IconData icon, String label, double value) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label ${value.toStringAsFixed(1)}'),
      backgroundColor: Colors.black54,
    );
  }
}

import 'package:flutter/material.dart';

import '../render/painters/overlays.dart';

class OverlaysPanel extends StatelessWidget {
  const OverlaysPanel({super.key, required this.currentMode, required this.onChanged});

  final OverlayMode currentMode;
  final ValueChanged<OverlayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: OverlayMode.values
              .where((mode) => mode != OverlayMode.none)
              .map(
                (mode) => RadioListTile<OverlayMode>(
                  dense: true,
                  value: mode,
                  groupValue: currentMode,
                  onChanged: (value) {
                    onChanged(value ?? OverlayMode.none);
                  },
                  title: Text(mode.name),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

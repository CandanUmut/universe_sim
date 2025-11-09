import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  double _musicVolume = 0.5;
  double _effectsVolume = 0.7;
  bool _showHints = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: _showHints,
              onChanged: (value) => setState(() => _showHints = value),
              title: const Text('Show tooltips'),
            ),
            const SizedBox(height: 12),
            _slider('Music volume', _musicVolume, (v) => setState(() => _musicVolume = v)),
            const SizedBox(height: 12),
            _slider('Effects volume', _effectsVolume, (v) => setState(() => _effectsVolume = v)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

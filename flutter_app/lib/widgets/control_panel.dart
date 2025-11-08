import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onReset,
    required this.onPresetSelected,
    required this.timeScale,
    required this.onTimeScaleChanged,
    required this.showTrails,
    required this.onTrailsChanged,
    required this.showBarycenter,
    required this.onBarycenterChanged,
  });

  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onReset;
  final ValueChanged<String> onPresetSelected;
  final double timeScale;
  final ValueChanged<double> onTimeScaleChanged;
  final bool showTrails;
  final ValueChanged<bool> onTrailsChanged;
  final bool showBarycenter;
  final ValueChanged<bool> onBarycenterChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = GoogleFonts.orbitron(
      color: Colors.white,
      letterSpacing: 0.5,
      fontSize: 12,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: onTogglePlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlaying
                      ? const Color(0xFFEF476F)
                      : const Color(0xFF06D6A0),
                ),
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(isPlaying ? 'Pause' : 'Play'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26547C),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                color: const Color(0xFF1B263B),
                icon: const Icon(Icons.auto_awesome, color: Colors.white70),
                tooltip: 'Switch scenario',
                onSelected: onPresetSelected,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'solar',
                    child: Text('Realistic Solar System', style: labelStyle),
                  ),
                  PopupMenuItem<String>(
                    value: 'binary',
                    child: Text('Binary Star Ballet', style: labelStyle),
                  ),
                  PopupMenuItem<String>(
                    value: 'cluster',
                    child: Text('Procedural Cluster', style: labelStyle),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Time dilation', style: labelStyle),
          Slider(
            value: timeScale,
            min: 0.1,
            max: 32,
            divisions: 32,
            label: '${timeScale.toStringAsFixed(1)}x',
            onChanged: onTimeScaleChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: SwitchListTile.adaptive(
                  dense: true,
                  value: showTrails,
                  activeColor: const Color(0xFF06D6A0),
                  contentPadding: EdgeInsets.zero,
                  onChanged: onTrailsChanged,
                  title: Text('Show orbital trails', style: labelStyle),
                ),
              ),
              Expanded(
                child: SwitchListTile.adaptive(
                  dense: true,
                  value: showBarycenter,
                  activeColor: const Color(0xFF48CAE4),
                  contentPadding: EdgeInsets.zero,
                  onChanged: onBarycenterChanged,
                  title: Text('Highlight barycenter', style: labelStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

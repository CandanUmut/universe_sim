import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'simulation/particle.dart';
import 'simulation/presets.dart';
import 'simulation/simulation_engine.dart';
import 'widgets/control_panel.dart';
import 'widgets/overlay_info.dart';
import 'widgets/universe_painter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PruUniverseApp());
}

class PruUniverseApp extends StatelessWidget {
  const PruUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF48CAE4));
    return MaterialApp(
      title: 'PRU Universe',
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme.copyWith(brightness: Brightness.dark),
        textTheme: GoogleFonts.interTightTextTheme().apply(bodyColor: Colors.white),
        sliderTheme: SliderThemeData(
          thumbColor: scheme.secondary,
          activeTrackColor: scheme.secondary,
          inactiveTrackColor: Colors.white24,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: const UniverseSimulationPage(),
    );
  }
}

class UniverseSimulationPage extends StatefulWidget {
  const UniverseSimulationPage({super.key});

  @override
  State<UniverseSimulationPage> createState() => _UniverseSimulationPageState();
}

class _UniverseSimulationPageState extends State<UniverseSimulationPage>
    with SingleTickerProviderStateMixin {
  late final SimulationEngine _engine;
  late final Ticker _ticker;
  late List<Particle> _initialPreset;

  final math.Random _random = math.Random(42);
  final List<Offset> _starfield = List<Offset>.generate(
    320,
    (int index) => Offset(
      math.Random(index).nextDouble(),
      math.Random(index + 17).nextDouble(),
    ),
  );

  Offset _panOffset = Offset.zero;
  double _scale = 0.0004;
  bool _isPlaying = true;
  double _timeScale = 6;
  bool _showTrails = true;
  bool _showBarycenter = true;
  int _spawnedBodies = 0;
  int _clusterSeed = 99;

  Duration? _lastTick;
  Offset? _previousFocalPoint;
  double _initialScaleOnGesture = 1.0;

  @override
  void initState() {
    super.initState();
    _initialPreset = PresetSystems.solarSystem();
    _engine = SimulationEngine(particles: _initialPreset);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }
    final double deltaSeconds =
        (elapsed - _lastTick!).inMicroseconds / Duration.microsecondsPerSecond * 3600 * _timeScale;
    _lastTick = elapsed;
    if (!_isPlaying || deltaSeconds.isNaN) {
      return;
    }
    setState(() {
      _engine.step(deltaSeconds.clamp(0, 3600 * 60));
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousFocalPoint = details.focalPoint;
    _initialScaleOnGesture = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_previousFocalPoint == null) {
      _previousFocalPoint = details.focalPoint;
    }
    setState(() {
      _scale = (_initialScaleOnGesture * details.scale).clamp(0.0001, 0.01);
      _panOffset += details.focalPoint - _previousFocalPoint!;
      _previousFocalPoint = details.focalPoint;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _previousFocalPoint = null;
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _resetSimulation() {
    setState(() {
      _engine.resetParticles(_initialPreset);
      _isPlaying = true;
      _timeScale = 6;
      _spawnedBodies = 0;
      _scale = 0.0004;
      _panOffset = Offset.zero;
    });
  }

  void _applyPreset(String id) {
    late List<Particle> preset;
    switch (id) {
      case 'binary':
        preset = PresetSystems.binaryDance();
        break;
      case 'cluster':
        _clusterSeed = DateTime.now().millisecondsSinceEpoch % 10000;
        preset = PresetSystems.proceduralCluster(_clusterSeed);
        break;
      case 'solar':
      default:
        preset = PresetSystems.solarSystem();
    }
    setState(() {
      _initialPreset = preset;
      _engine.resetParticles(preset);
      _spawnedBodies = 0;
      _scale = 0.0004;
      _panOffset = Offset.zero;
    });
  }

  void _spawnComet() {
    final double radius = (0.5 + _random.nextDouble()) * 8e5;
    final double angle = _random.nextDouble() * 2 * math.pi;
    final Vector3 position = Vector3(
      math.cos(angle) * radius,
      math.sin(angle) * radius,
      0,
    );
    final Vector3 velocity = Vector3(-math.sin(angle), math.cos(angle), 0)
      ..scale(150 + _random.nextDouble() * 120);
    final Color color = HSVColor.fromAHSV(
      1,
      _random.nextDouble() * 360,
      0.8,
      1,
    ).toColor();

    final Particle comet = Particle(
      name: 'Comet-${_spawnedBodies + 1}',
      mass: 8e22 + _random.nextDouble() * 1e23,
      radius: 7,
      color: color,
      position: position,
      velocity: velocity,
      spin: _random.nextDouble() * 0.02,
    );
    setState(() {
      _engine.addParticle(comet);
      _spawnedBodies += 1;
    });
  }

  void _resetCamera() {
    setState(() {
      _panOffset = Offset.zero;
      _scale = 0.0004;
    });
  }

  List<String> _buildOverlayLines() {
    final Vector3 bary = _engine.barycenter;
    final double baryDistance = bary.length / 1000; // in Mm approx
    return <String>[
      'Bodies: ${_engine.particles.length}',
      'Time warp: ${_timeScale.toStringAsFixed(1)}×',
      'Spawned comets: $_spawnedBodies',
      'Barycentric radius: ${baryDistance.toStringAsFixed(2)} Mm',
      if (_clusterSeed != 99) 'Cluster seed: $_clusterSeed',
      'Double tap to reset camera',
      'Pinch/drag to explore the cosmos',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: _resetCamera,
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: UniversePainter(
                    particles: _engine.particles,
                    scale: _scale,
                    panOffset: _panOffset,
                    showTrails: _showTrails,
                    showBarycenter: _showBarycenter,
                    barycenter: _engine.barycenter,
                    starfield: _starfield,
                  ),
                ),
                OverlayInfo(lines: _buildOverlayLines()),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ControlPanel(
                    isPlaying: _isPlaying,
                    onTogglePlay: _togglePlay,
                    onReset: _resetSimulation,
                    onPresetSelected: _applyPreset,
                    timeScale: _timeScale,
                    onTimeScaleChanged: (double value) {
                      setState(() {
                        _timeScale = value;
                      });
                    },
                    showTrails: _showTrails,
                    onTrailsChanged: (bool value) {
                      setState(() {
                        _showTrails = value;
                      });
                    },
                    showBarycenter: _showBarycenter,
                    onBarycenterChanged: (bool value) {
                      setState(() {
                        _showBarycenter = value;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _spawnComet,
        backgroundColor: const Color(0xFFFFD166),
        icon: const Icon(Icons.auto_graph),
        label: const Text('Spawn comet'),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../core/mathf.dart';
import '../core/noise.dart';
import 'pru_types.dart';
import 'world_seed.dart';

class PRURuleSet {
  PRURuleSet({required this.seed, required this.rules})
      : _noise = ValueNoise2D(seed: seed);

  final int seed;
  final Map<String, dynamic> rules;
  final ValueNoise2D _noise;

  static Future<PRURuleSet> load(UniverseSeed seed) async {
    try {
      final text = await rootBundle.loadString('assets/rules.yaml');
      final yamlMap = loadYaml(text) as YamlMap;
      return PRURuleSet(
        seed: seed.rulesSeed,
        rules: jsonDecode(jsonEncode(yamlMap)) as Map<String, dynamic>,
      );
    } catch (_) {
      return PRURuleSet(seed: seed.rulesSeed, rules: _fallbackRules());
    }
  }

  PRUField composeCell({
    required GridLevel level,
    required int cellX,
    required int cellY,
    List<PRUField> localSources = const [],
  }) {
    final base = _baseField(level, cellX, cellY);
    var field = base;
    for (final source in localSources) {
      field = field.add(source);
    }
    return _clampField(level, field);
  }

  PRUField _baseField(GridLevel level, int cellX, int cellY) {
    final map = rules[level.name] as Map<String, dynamic>?;
    final Vector2like centerBias = Vector2like.fromMap(map?['center_bias']);
    final radialFalloff = (map?['radial_falloff'] as num?)?.toDouble() ?? 0.6;
    final noiseAmp = (map?['noise_amplitude'] as num?)?.toDouble() ?? 0.25;
    final massBase = (map?['mass_base'] as num?)?.toDouble() ?? 0.5;
    final energyBase = (map?['energy_base'] as num?)?.toDouble() ?? 0.4;

    final posX = cellX * level.cellSize;
    final posY = cellY * level.cellSize;
    final radius = math.sqrt(posX * posX + posY * posY);
    final angle = math.atan2(posY, posX);

    final centerBiasValue = centerBias.x * math.cos(angle) + centerBias.y * math.sin(angle);
    final radial = math.exp(-radialFalloff * radius / 10000.0);
    final spiral = math.sin(angle * 3 + seed * 0.1) * 0.5 + 0.5;
    final bias = Mathf.lerp(centerBiasValue * 0.5 + 0.5, spiral, 0.5);

    final noise = _noise.noise(posX / 1000.0, posY / 1000.0) * noiseAmp;

    final mass = massBase * radial * (0.8 + noise * 0.2) + bias * 0.1;
    final energy = energyBase * (0.7 + noise * 0.3) + radial * 0.2;
    final angular = (spiral - 0.5) * 0.8;
    final habitability = radial * (0.4 + noise * 0.2);
    final civ = math.max(0, habitability - 0.2) * 0.6;
    final anomaly = noise.abs() * 0.5;

    return PRUField(
      massDensity: mass,
      energyFlux: energy,
      angularBias: angular,
      habitability: habitability,
      civPressure: civ,
      anomaly: anomaly,
    );
  }

  PRUField _clampField(GridLevel level, PRUField field) {
    final map = rules[level.name] as Map<String, dynamic>?;
    final min = map?['min'] as Map<String, dynamic>?;
    final max = map?['max'] as Map<String, dynamic>?;
    final minField = min != null ? VectorField.fromMap(min) : VectorField.zero;
    final maxField = max != null ? VectorField.fromMap(max) : VectorField.ones;
    return field.clamp(minField.toField(), maxField.toField());
  }

  PRUField influenceForRelay(double strength) {
    return PRUField(
      massDensity: 0,
      energyFlux: strength * 0.3,
      angularBias: 0,
      habitability: strength * 0.4,
      civPressure: strength * 0.5,
      anomaly: 0,
    );
  }

  static Map<String, dynamic> _fallbackRules() {
    return {
      'galaxy': {
        'mass_base': 0.9,
        'energy_base': 0.6,
        'radial_falloff': 0.3,
        'noise_amplitude': 0.25,
        'center_bias': {'x': 0.1, 'y': 0.2},
        'min': {'massDensity': 0, 'energyFlux': 0, 'habitability': 0},
        'max': {'massDensity': 2, 'energyFlux': 2, 'habitability': 1.5},
      },
      'sector': {
        'mass_base': 0.7,
        'energy_base': 0.5,
        'radial_falloff': 0.4,
        'noise_amplitude': 0.35,
        'center_bias': {'x': 0.05, 'y': 0.1},
        'min': {'massDensity': 0, 'energyFlux': 0, 'habitability': 0},
        'max': {'massDensity': 2, 'energyFlux': 2, 'habitability': 1.2},
      },
      'system': {
        'mass_base': 0.6,
        'energy_base': 0.7,
        'radial_falloff': 0.6,
        'noise_amplitude': 0.45,
        'center_bias': {'x': 0.02, 'y': 0.05},
        'min': {'massDensity': 0, 'energyFlux': 0, 'habitability': 0},
        'max': {'massDensity': 3, 'energyFlux': 3, 'habitability': 2},
      },
    };
  }
}

class Vector2like {
  const Vector2like({required this.x, required this.y});

  factory Vector2like.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const Vector2like(x: 0, y: 0);
    }
    return Vector2like(
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
    );
  }

  final double x;
  final double y;
}

class VectorField {
  const VectorField({
    required this.massDensity,
    required this.energyFlux,
    required this.angularBias,
    required this.habitability,
    required this.civPressure,
    required this.anomaly,
  });

  factory VectorField.fromMap(Map<String, dynamic> map) {
    return VectorField(
      massDensity: (map['massDensity'] as num?)?.toDouble() ?? 0,
      energyFlux: (map['energyFlux'] as num?)?.toDouble() ?? 0,
      angularBias: (map['angularBias'] as num?)?.toDouble() ?? 0,
      habitability: (map['habitability'] as num?)?.toDouble() ?? 0,
      civPressure: (map['civPressure'] as num?)?.toDouble() ?? 0,
      anomaly: (map['anomaly'] as num?)?.toDouble() ?? 0,
    );
  }

  static const zero = VectorField(
    massDensity: 0,
    energyFlux: 0,
    angularBias: 0,
    habitability: 0,
    civPressure: 0,
    anomaly: 0,
  );

  static const ones = VectorField(
    massDensity: 1,
    energyFlux: 1,
    angularBias: 1,
    habitability: 1,
    civPressure: 1,
    anomaly: 1,
  );

  final double massDensity;
  final double energyFlux;
  final double angularBias;
  final double habitability;
  final double civPressure;
  final double anomaly;

  PRUField toField() => PRUField(
        massDensity: massDensity,
        energyFlux: energyFlux,
        angularBias: angularBias,
        habitability: habitability,
        civPressure: civPressure,
        anomaly: anomaly,
      );
}

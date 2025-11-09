import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ScenarioDefinition {
  ScenarioDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.initialStars,
    required this.initialRadius,
    required this.cameraStart,
  });

  factory ScenarioDefinition.fromJson(Map<String, dynamic> json) {
    return ScenarioDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      initialStars: (json['initialStars'] as num).toInt(),
      initialRadius: (json['initialRadius'] as num).toDouble(),
      cameraStart: List<double>.from(json['cameraStart'] as List<dynamic>),
    );
  }

  final String id;
  final String name;
  final String description;
  final int initialStars;
  final double initialRadius;
  final List<double> cameraStart;
}

class ScenarioLibrary {
  ScenarioLibrary(this.scenarios);

  final List<ScenarioDefinition> scenarios;

  ScenarioDefinition byId(String id) {
    return scenarios.firstWhere((s) => s.id == id, orElse: () => scenarios.first);
  }

  static Future<ScenarioLibrary> load() async {
    try {
      final text = await rootBundle.loadString('lib/data/scenarios.json');
      final jsonList = jsonDecode(text) as List<dynamic>;
      final scenarios = jsonList
          .map((dynamic e) => ScenarioDefinition.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return ScenarioLibrary(scenarios);
    } catch (_) {
      return ScenarioLibrary(_fallback());
    }
  }

  static List<ScenarioDefinition> _fallback() {
    return [
      ScenarioDefinition(
        id: 'spiral_tiny',
        name: 'Tiny Spiral',
        description: 'A small, tightly wound spiral of hopeful suns.',
        initialStars: 12,
        initialRadius: 600,
        cameraStart: const [0, 0, 1.0],
      ),
    ];
  }
}

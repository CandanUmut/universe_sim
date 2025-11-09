import '../core/mathf.dart';

class PRUField {
  const PRUField({
    required this.massDensity,
    required this.energyFlux,
    required this.angularBias,
    required this.habitability,
    required this.civPressure,
    required this.anomaly,
  });

  final double massDensity;
  final double energyFlux;
  final double angularBias;
  final double habitability;
  final double civPressure;
  final double anomaly;

  static const zero = PRUField(
    massDensity: 0,
    energyFlux: 0,
    angularBias: 0,
    habitability: 0,
    civPressure: 0,
    anomaly: 0,
  );

  PRUField add(PRUField other) {
    return PRUField(
      massDensity: massDensity + other.massDensity,
      energyFlux: energyFlux + other.energyFlux,
      angularBias: angularBias + other.angularBias,
      habitability: habitability + other.habitability,
      civPressure: civPressure + other.civPressure,
      anomaly: anomaly + other.anomaly,
    );
  }

  PRUField addWeighted(PRUField other, double weight) {
    return PRUField(
      massDensity: massDensity + other.massDensity * weight,
      energyFlux: energyFlux + other.energyFlux * weight,
      angularBias: angularBias + other.angularBias * weight,
      habitability: habitability + other.habitability * weight,
      civPressure: civPressure + other.civPressure * weight,
      anomaly: anomaly + other.anomaly * weight,
    );
  }

  PRUField clamp(PRUField min, PRUField max) {
    return PRUField(
      massDensity: Mathf.clamp(massDensity, min.massDensity, max.massDensity),
      energyFlux: Mathf.clamp(energyFlux, min.energyFlux, max.energyFlux),
      angularBias: Mathf.clamp(angularBias, min.angularBias, max.angularBias),
      habitability: Mathf.clamp(habitability, min.habitability, max.habitability),
      civPressure: Mathf.clamp(civPressure, min.civPressure, max.civPressure),
      anomaly: Mathf.clamp(anomaly, min.anomaly, max.anomaly),
    );
  }

  static PRUField lerp(PRUField a, PRUField b, double t) {
    return PRUField(
      massDensity: Mathf.lerp(a.massDensity, b.massDensity, t),
      energyFlux: Mathf.lerp(a.energyFlux, b.energyFlux, t),
      angularBias: Mathf.lerp(a.angularBias, b.angularBias, t),
      habitability: Mathf.lerp(a.habitability, b.habitability, t),
      civPressure: Mathf.lerp(a.civPressure, b.civPressure, t),
      anomaly: Mathf.lerp(a.anomaly, b.anomaly, t),
    );
  }

  Map<String, double> toJson() => {
        'massDensity': massDensity,
        'energyFlux': energyFlux,
        'angularBias': angularBias,
        'habitability': habitability,
        'civPressure': civPressure,
        'anomaly': anomaly,
      };
}

enum GridLevel { galaxy, sector, system }

extension GridLevelX on GridLevel {
  double get cellSize {
    switch (this) {
      case GridLevel.galaxy:
        return 8192;
      case GridLevel.sector:
        return 1024;
      case GridLevel.system:
        return 128;
    }
  }

  int get index {
    switch (this) {
      case GridLevel.galaxy:
        return 0;
      case GridLevel.sector:
        return 1;
      case GridLevel.system:
        return 2;
    }
  }
}

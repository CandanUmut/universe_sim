class CivilizationComponent {
  CivilizationComponent({required this.level});

  CivilizationLevel level;
  double influence = 0;
  double cohesion = 0.5;
}

enum CivilizationLevel { nascent, planetary, interstellar }

class StarComponent {
  StarComponent({required this.luminosity, required this.temperature});

  double luminosity;
  double temperature;
  double age = 0;
  final List<int> planetIds = [];
}

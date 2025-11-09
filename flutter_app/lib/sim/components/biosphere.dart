class BiosphereComponent {
  BiosphereComponent({required this.stage});

  BiosphereStage stage;
  double progress = 0;
}

enum BiosphereStage { sterile, proto, simple, complex, intelligent }

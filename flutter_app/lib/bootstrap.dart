import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'render/game_root.dart';
import 'ui/hud.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final game = GameRoot();
  runApp(PRUverseApp(game: game));
}

class PRUverseApp extends StatelessWidget {
  const PRUverseApp({super.key, required this.game});

  final GameRoot game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRUverse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6CF7)),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: PRUverseHome(game: game),
    );
  }
}

class PRUverseHome extends StatelessWidget {
  const PRUverseHome({super.key, required this.game});

  final GameRoot game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget(
              game: game,
              overlayBuilderMap: {
                HudOverlay.id: (context, game) => HudOverlay(game: game as GameRoot),
              },
              initialActiveOverlays: const [HudOverlay.id],
            ),
          ],
        ),
      ),
    );
  }
}

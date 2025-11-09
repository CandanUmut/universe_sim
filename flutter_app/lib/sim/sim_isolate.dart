import 'dart:async';
import 'dart:isolate';

import 'package:vector_math/vector_math_64.dart';

import 'components/biosphere.dart';
import 'components/civilization.dart';
import 'components/relay.dart';
import 'components/star.dart';
import 'components/transform.dart';
import 'ecs.dart';
import 'pru_grid.dart';
import 'pru_rules.dart';
import 'world_seed.dart';

class SimInitMessage {
  const SimInitMessage({required this.seed, required this.rules});

  final UniverseSeed seed;
  final Map<String, dynamic> rules;
}

class SimCommandMessage {
  const SimCommandMessage(this.command, this.payload);

  final String command;
  final dynamic payload;
}

class EntitySnapshot {
  const EntitySnapshot({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.extra,
  });

  final int id;
  final String type;
  final double x;
  final double y;
  final Map<String, dynamic>? extra;
}

class SimSnapshot {
  const SimSnapshot({
    required this.time,
    required this.entities,
    required this.starlight,
    required this.order,
    required this.resources,
  });

  final double time;
  final List<EntitySnapshot> entities;
  final double starlight;
  final double order;
  final Map<String, double> resources;
}

class SimController {
  SimController(this.seed, this.ruleSet);

  final UniverseSeed seed;
  final PRURuleSet ruleSet;

  final StreamController<SimSnapshot> _snapshots = StreamController.broadcast();
  Stream<SimSnapshot> get snapshots => _snapshots.stream;

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  ReceivePort? _snapshotReceivePort;
  Isolate? _isolate;

  Future<void> start() async {
    final receivePort = ReceivePort();
    _receivePort = receivePort;
    _isolate = await Isolate.spawn(_entryPoint, receivePort.sendPort);
    _sendPort = await receivePort.first as SendPort;
    final responsePort = ReceivePort();
    _snapshotReceivePort = responsePort;
    _sendPort!.send(responsePort.sendPort);
    _sendPort!.send(SimInitMessage(seed: seed, rules: ruleSet.rules));
    responsePort.listen((message) {
      if (message is SimSnapshot) {
        _snapshots.add(message);
      }
    });
  }

  void sendCommand(String command, dynamic payload) {
    _sendPort?.send(SimCommandMessage(command, payload));
  }

  Future<void> dispose() async {
    await _snapshots.close();
    _receivePort?.close();
    _snapshotReceivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
  }
}

void _entryPoint(SendPort primaryPort) {
  final commandPort = ReceivePort();
  primaryPort.send(commandPort.sendPort);

  late SendPort snapshotPort;
  SimState? state;
  Timer? timer;

  commandPort.listen((dynamic message) {
    if (message is SendPort) {
      snapshotPort = message;
    } else if (message is SimInitMessage) {
      final rules = PRURuleSet(seed: message.seed.rulesSeed, rules: message.rules);
      final grid = UniverseGrid(rules: rules);
      state = SimState(seed: message.seed, grid: grid);
      WorldBuilder(state!).populateInitial();
      timer?.cancel();
      timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        _tick(state!, snapshotPort);
      });
    } else if (message is SimCommandMessage) {
      _handleCommand(state, message);
    }
  });
}

void _handleCommand(SimState? state, SimCommandMessage message) {
  if (state == null) {
    return;
  }
  switch (message.command) {
    case 'placeStar':
      final payload = message.payload as Map<String, dynamic>;
      final double x = (payload['x'] as num).toDouble();
      final double y = (payload['y'] as num).toDouble();
      final id = state.createEntity();
      state.transforms[id] = TransformComponent(position: Vector2(x, y), velocity: Vector2.zero());
      state.stars[id] = StarComponent(luminosity: 1.2, temperature: 5200);
      break;
    case 'seedLife':
      final int target = message.payload as int;
      final biosphere = state.biospheres[target];
      if (biosphere != null && biosphere.stage == BiosphereStage.sterile) {
        biosphere.stage = BiosphereStage.proto;
      }
      break;
    case 'buildRelay':
      final int target = message.payload as int;
      final transform = state.transforms[target];
      if (transform != null) {
        final relayId = state.createEntity();
        state.transforms[relayId] = TransformComponent(position: transform.position + Vector2(40, 0), velocity: Vector2.zero());
        state.relays[relayId] = RelayComponent(strength: 0.6);
      }
      break;
    default:
      break;
  }
}

void _tick(SimState state, SendPort port) {
  const dt = 1 / 30;
  state.update(dt);
  final entities = <EntitySnapshot>[];
  for (final entry in state.transforms.entries) {
    final id = entry.key;
    final transform = entry.value;
    final type = _entityType(state, id);
    final extra = _entityExtra(state, id);
    entities.add(EntitySnapshot(
      id: id,
      type: type,
      x: transform.position.x,
      y: transform.position.y,
      extra: extra,
    ));
  }
  port.send(SimSnapshot(
    time: state.elapsedTime,
    entities: entities,
    starlight: state.starlight,
    order: state.order,
    resources: {
      'starlight': state.starlight,
      'order': state.order,
    },
  ));
}

String _entityType(SimState state, int id) {
  if (state.stars.containsKey(id)) {
    return 'star';
  }
  if (state.planets.containsKey(id)) {
    return 'planet';
  }
  if (state.relays.containsKey(id)) {
    return 'relay';
  }
  return 'entity';
}

Map<String, dynamic>? _entityExtra(SimState state, int id) {
  if (state.biospheres.containsKey(id)) {
    final biosphere = state.biospheres[id]!;
    return {
      'stage': biosphere.stage.name,
      'progress': biosphere.progress,
    };
  }
  if (state.civilizations.containsKey(id)) {
    final civ = state.civilizations[id]!;
    return {
      'level': civ.level.name,
      'influence': civ.influence,
      'cohesion': civ.cohesion,
    };
  }
  if (state.planets.containsKey(id)) {
    final planet = state.planets[id]!;
    return {
      'formation': planet.formationProgress,
      'resources': planet.resourceValue,
    };
  }
  if (state.stars.containsKey(id)) {
    final star = state.stars[id]!;
    return {
      'luminosity': star.luminosity,
      'temperature': star.temperature,
    };
  }
  return null;
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../render/game_root.dart';

class TechTreeDialog extends StatefulWidget {
  const TechTreeDialog({super.key, required this.game});

  final GameRoot game;

  @override
  State<TechTreeDialog> createState() => _TechTreeDialogState();
}

class _TechTreeDialogState extends State<TechTreeDialog> {
  late Future<List<TechNode>> _nodesFuture;

  @override
  void initState() {
    super.initState();
    _nodesFuture = _loadNodes();
  }

  Future<List<TechNode>> _loadNodes() async {
    try {
      final text = await rootBundle.loadString('lib/data/tech_tree.json');
      final jsonList = jsonDecode(text) as List<dynamic>;
      return jsonList
          .map((dynamic e) => TechNode.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return TechNode.fallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: const Text('Tech Tree'),
      content: SizedBox(
        width: 360,
        height: 420,
        child: FutureBuilder<List<TechNode>>(
          future: _nodesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final nodes = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resources: Starlight ${widget.game.starlight.toStringAsFixed(1)} · Order ${widget.game.order.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return ListTile(
                        title: Text(node.name),
                        subtitle: Text(node.description),
                        trailing: Chip(label: Text('${node.cost} Order')),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class TechNode {
  TechNode({required this.id, required this.name, required this.description, required this.cost});

  factory TechNode.fromJson(Map<String, dynamic> json) {
    return TechNode(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cost: (json['cost'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String description;
  final double cost;

  static List<TechNode> fallback() {
    return [
      TechNode(id: 'relay', name: 'Relay Engineering', description: 'Allow construction of field relays.', cost: 20),
      TechNode(id: 'bio', name: 'Bio-Seeding', description: 'Seed primitive life on formed worlds.', cost: 30),
      TechNode(id: 'dyson', name: 'Dyson Concepts', description: 'Harvest entire stars for starlight.', cost: 120),
    ];
  }
}

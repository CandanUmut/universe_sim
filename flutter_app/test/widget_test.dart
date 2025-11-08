import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pru_universe/main.dart';

void main() {
  testWidgets('app renders control panel', (WidgetTester tester) async {
    await tester.pumpWidget(const PruUniverseApp());
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Spawn comet'), findsOneWidget);
  });
}

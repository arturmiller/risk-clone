import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/actions.dart';
import 'package:risk_mobile/providers/ui_provider.dart';

class _Trigger extends ConsumerWidget {
  final String action;
  const _Trigger(this.action);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => dispatchAction(action, ref),
      child: const SizedBox(width: 100, height: 100),
    );
  }
}

void main() {
  testWidgets('selectDice:2 updates UI state', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: _Trigger('selectDice:2')),
      ),
    ));
    await t.pumpAndSettle();

    expect(container.read(uIStateProvider).diceCount, 3); // default
    final gd = t.widget<GestureDetector>(find.byType(GestureDetector));
    gd.onTap!();
    expect(container.read(uIStateProvider).diceCount, 2);
  });

  testWidgets('unknown action is a no-op', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: _Trigger('bogus.action')),
      ),
    ));
    await t.pumpAndSettle();
    final gd = t.widget<GestureDetector>(find.byType(GestureDetector));
    gd.onTap!(); // no throw
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_mobile/hud/selected_when.dart';

class _Probe extends ConsumerWidget {
  final String expr;
  final void Function(bool) onEval;
  const _Probe({required this.expr, required this.onEval});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onEval(evaluateSelectedWhen(expr, ref));
    return const SizedBox();
  }
}

Future<bool> _eval(WidgetTester t, String expr) async {
  bool captured = false;
  await t.pumpWidget(ProviderScope(
    child: _Probe(expr: expr, onEval: (v) => captured = v),
  ));
  return captured;
}

void main() {
  testWidgets('ui.diceCount == 3 matches default', (t) async {
    expect(await _eval(t, 'ui.diceCount == 3'), isTrue);
  });

  testWidgets('ui.diceCount == 2 does not match default', (t) async {
    expect(await _eval(t, 'ui.diceCount == 2'), isFalse);
  });

  testWidgets('string literal comparison', (t) async {
    expect(await _eval(t, 'game.phaseLabel == "ATTACK PHASE"'), isFalse); // no game state
  });

  testWidgets('malformed expression returns false', (t) async {
    expect(await _eval(t, 'garbage'), isFalse);
  });
}

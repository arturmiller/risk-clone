import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_hand_visibility_provider.g.dart';

@Riverpod(keepAlive: true)
class CardHandVisibility extends _$CardHandVisibility {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

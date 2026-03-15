import 'package:freezed_annotation/freezed_annotation.dart';

part 'cards.freezed.dart';
part 'cards.g.dart';

enum CardType { infantry, cavalry, artillery, wild }

enum TurnPhase { reinforce, attack, fortify }

@freezed
abstract class Card with _$Card {
  const factory Card({
    String? territory,
    required CardType cardType,
  }) = _Card;

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);
}

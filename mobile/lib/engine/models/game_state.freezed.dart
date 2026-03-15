// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TerritoryState {

 int get owner; int get armies;
/// Create a copy of TerritoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerritoryStateCopyWith<TerritoryState> get copyWith => _$TerritoryStateCopyWithImpl<TerritoryState>(this as TerritoryState, _$identity);

  /// Serializes this TerritoryState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerritoryState&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.armies, armies) || other.armies == armies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,owner,armies);

@override
String toString() {
  return 'TerritoryState(owner: $owner, armies: $armies)';
}


}

/// @nodoc
abstract mixin class $TerritoryStateCopyWith<$Res>  {
  factory $TerritoryStateCopyWith(TerritoryState value, $Res Function(TerritoryState) _then) = _$TerritoryStateCopyWithImpl;
@useResult
$Res call({
 int owner, int armies
});




}
/// @nodoc
class _$TerritoryStateCopyWithImpl<$Res>
    implements $TerritoryStateCopyWith<$Res> {
  _$TerritoryStateCopyWithImpl(this._self, this._then);

  final TerritoryState _self;
  final $Res Function(TerritoryState) _then;

/// Create a copy of TerritoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? armies = null,}) {
  return _then(_self.copyWith(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as int,armies: null == armies ? _self.armies : armies // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TerritoryState].
extension TerritoryStatePatterns on TerritoryState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerritoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerritoryState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerritoryState value)  $default,){
final _that = this;
switch (_that) {
case _TerritoryState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerritoryState value)?  $default,){
final _that = this;
switch (_that) {
case _TerritoryState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int owner,  int armies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerritoryState() when $default != null:
return $default(_that.owner,_that.armies);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int owner,  int armies)  $default,) {final _that = this;
switch (_that) {
case _TerritoryState():
return $default(_that.owner,_that.armies);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int owner,  int armies)?  $default,) {final _that = this;
switch (_that) {
case _TerritoryState() when $default != null:
return $default(_that.owner,_that.armies);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TerritoryState implements TerritoryState {
  const _TerritoryState({required this.owner, required this.armies});
  factory _TerritoryState.fromJson(Map<String, dynamic> json) => _$TerritoryStateFromJson(json);

@override final  int owner;
@override final  int armies;

/// Create a copy of TerritoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerritoryStateCopyWith<_TerritoryState> get copyWith => __$TerritoryStateCopyWithImpl<_TerritoryState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TerritoryStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerritoryState&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.armies, armies) || other.armies == armies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,owner,armies);

@override
String toString() {
  return 'TerritoryState(owner: $owner, armies: $armies)';
}


}

/// @nodoc
abstract mixin class _$TerritoryStateCopyWith<$Res> implements $TerritoryStateCopyWith<$Res> {
  factory _$TerritoryStateCopyWith(_TerritoryState value, $Res Function(_TerritoryState) _then) = __$TerritoryStateCopyWithImpl;
@override @useResult
$Res call({
 int owner, int armies
});




}
/// @nodoc
class __$TerritoryStateCopyWithImpl<$Res>
    implements _$TerritoryStateCopyWith<$Res> {
  __$TerritoryStateCopyWithImpl(this._self, this._then);

  final _TerritoryState _self;
  final $Res Function(_TerritoryState) _then;

/// Create a copy of TerritoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? armies = null,}) {
  return _then(_TerritoryState(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as int,armies: null == armies ? _self.armies : armies // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlayerState {

 int get index; String get name; bool get isAlive;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);

  /// Serializes this PlayerState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.isAlive, isAlive) || other.isAlive == isAlive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,isAlive);

@override
String toString() {
  return 'PlayerState(index: $index, name: $name, isAlive: $isAlive)';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 int index, String name, bool isAlive
});




}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? name = null,Object? isAlive = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isAlive: null == isAlive ? _self.isAlive : isAlive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerState].
extension PlayerStatePatterns on PlayerState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String name,  bool isAlive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.index,_that.name,_that.isAlive);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String name,  bool isAlive)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.index,_that.name,_that.isAlive);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String name,  bool isAlive)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.index,_that.name,_that.isAlive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerState implements PlayerState {
  const _PlayerState({required this.index, required this.name, this.isAlive = true});
  factory _PlayerState.fromJson(Map<String, dynamic> json) => _$PlayerStateFromJson(json);

@override final  int index;
@override final  String name;
@override@JsonKey() final  bool isAlive;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.isAlive, isAlive) || other.isAlive == isAlive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,isAlive);

@override
String toString() {
  return 'PlayerState(index: $index, name: $name, isAlive: $isAlive)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 int index, String name, bool isAlive
});




}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? name = null,Object? isAlive = null,}) {
  return _then(_PlayerState(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isAlive: null == isAlive ? _self.isAlive : isAlive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GameState {

 Map<String, TerritoryState> get territories; List<PlayerState> get players; int get currentPlayerIndex; int get turnNumber; TurnPhase get turnPhase; int get tradeCount;// JSON map keys must be strings; access with cards[playerIndex.toString()]
 Map<String, List<Card>> get cards; List<Card> get deck; bool get conqueredThisTurn;
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateCopyWith<GameState> get copyWith => _$GameStateCopyWithImpl<GameState>(this as GameState, _$identity);

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState&&const DeepCollectionEquality().equals(other.territories, territories)&&const DeepCollectionEquality().equals(other.players, players)&&(identical(other.currentPlayerIndex, currentPlayerIndex) || other.currentPlayerIndex == currentPlayerIndex)&&(identical(other.turnNumber, turnNumber) || other.turnNumber == turnNumber)&&(identical(other.turnPhase, turnPhase) || other.turnPhase == turnPhase)&&(identical(other.tradeCount, tradeCount) || other.tradeCount == tradeCount)&&const DeepCollectionEquality().equals(other.cards, cards)&&const DeepCollectionEquality().equals(other.deck, deck)&&(identical(other.conqueredThisTurn, conqueredThisTurn) || other.conqueredThisTurn == conqueredThisTurn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(territories),const DeepCollectionEquality().hash(players),currentPlayerIndex,turnNumber,turnPhase,tradeCount,const DeepCollectionEquality().hash(cards),const DeepCollectionEquality().hash(deck),conqueredThisTurn);

@override
String toString() {
  return 'GameState(territories: $territories, players: $players, currentPlayerIndex: $currentPlayerIndex, turnNumber: $turnNumber, turnPhase: $turnPhase, tradeCount: $tradeCount, cards: $cards, deck: $deck, conqueredThisTurn: $conqueredThisTurn)';
}


}

/// @nodoc
abstract mixin class $GameStateCopyWith<$Res>  {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) _then) = _$GameStateCopyWithImpl;
@useResult
$Res call({
 Map<String, TerritoryState> territories, List<PlayerState> players, int currentPlayerIndex, int turnNumber, TurnPhase turnPhase, int tradeCount, Map<String, List<Card>> cards, List<Card> deck, bool conqueredThisTurn
});




}
/// @nodoc
class _$GameStateCopyWithImpl<$Res>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._self, this._then);

  final GameState _self;
  final $Res Function(GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? territories = null,Object? players = null,Object? currentPlayerIndex = null,Object? turnNumber = null,Object? turnPhase = null,Object? tradeCount = null,Object? cards = null,Object? deck = null,Object? conqueredThisTurn = null,}) {
  return _then(_self.copyWith(
territories: null == territories ? _self.territories : territories // ignore: cast_nullable_to_non_nullable
as Map<String, TerritoryState>,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as List<PlayerState>,currentPlayerIndex: null == currentPlayerIndex ? _self.currentPlayerIndex : currentPlayerIndex // ignore: cast_nullable_to_non_nullable
as int,turnNumber: null == turnNumber ? _self.turnNumber : turnNumber // ignore: cast_nullable_to_non_nullable
as int,turnPhase: null == turnPhase ? _self.turnPhase : turnPhase // ignore: cast_nullable_to_non_nullable
as TurnPhase,tradeCount: null == tradeCount ? _self.tradeCount : tradeCount // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as Map<String, List<Card>>,deck: null == deck ? _self.deck : deck // ignore: cast_nullable_to_non_nullable
as List<Card>,conqueredThisTurn: null == conqueredThisTurn ? _self.conqueredThisTurn : conqueredThisTurn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameState value)  $default,){
final _that = this;
switch (_that) {
case _GameState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameState value)?  $default,){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, TerritoryState> territories,  List<PlayerState> players,  int currentPlayerIndex,  int turnNumber,  TurnPhase turnPhase,  int tradeCount,  Map<String, List<Card>> cards,  List<Card> deck,  bool conqueredThisTurn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.territories,_that.players,_that.currentPlayerIndex,_that.turnNumber,_that.turnPhase,_that.tradeCount,_that.cards,_that.deck,_that.conqueredThisTurn);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, TerritoryState> territories,  List<PlayerState> players,  int currentPlayerIndex,  int turnNumber,  TurnPhase turnPhase,  int tradeCount,  Map<String, List<Card>> cards,  List<Card> deck,  bool conqueredThisTurn)  $default,) {final _that = this;
switch (_that) {
case _GameState():
return $default(_that.territories,_that.players,_that.currentPlayerIndex,_that.turnNumber,_that.turnPhase,_that.tradeCount,_that.cards,_that.deck,_that.conqueredThisTurn);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, TerritoryState> territories,  List<PlayerState> players,  int currentPlayerIndex,  int turnNumber,  TurnPhase turnPhase,  int tradeCount,  Map<String, List<Card>> cards,  List<Card> deck,  bool conqueredThisTurn)?  $default,) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.territories,_that.players,_that.currentPlayerIndex,_that.turnNumber,_that.turnPhase,_that.tradeCount,_that.cards,_that.deck,_that.conqueredThisTurn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameState implements GameState {
  const _GameState({required final  Map<String, TerritoryState> territories, required final  List<PlayerState> players, this.currentPlayerIndex = 0, this.turnNumber = 0, this.turnPhase = TurnPhase.reinforce, this.tradeCount = 0, final  Map<String, List<Card>> cards = const {}, final  List<Card> deck = const [], this.conqueredThisTurn = false}): _territories = territories,_players = players,_cards = cards,_deck = deck;
  factory _GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);

 final  Map<String, TerritoryState> _territories;
@override Map<String, TerritoryState> get territories {
  if (_territories is EqualUnmodifiableMapView) return _territories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_territories);
}

 final  List<PlayerState> _players;
@override List<PlayerState> get players {
  if (_players is EqualUnmodifiableListView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_players);
}

@override@JsonKey() final  int currentPlayerIndex;
@override@JsonKey() final  int turnNumber;
@override@JsonKey() final  TurnPhase turnPhase;
@override@JsonKey() final  int tradeCount;
// JSON map keys must be strings; access with cards[playerIndex.toString()]
 final  Map<String, List<Card>> _cards;
// JSON map keys must be strings; access with cards[playerIndex.toString()]
@override@JsonKey() Map<String, List<Card>> get cards {
  if (_cards is EqualUnmodifiableMapView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_cards);
}

 final  List<Card> _deck;
@override@JsonKey() List<Card> get deck {
  if (_deck is EqualUnmodifiableListView) return _deck;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deck);
}

@override@JsonKey() final  bool conqueredThisTurn;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateCopyWith<_GameState> get copyWith => __$GameStateCopyWithImpl<_GameState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameState&&const DeepCollectionEquality().equals(other._territories, _territories)&&const DeepCollectionEquality().equals(other._players, _players)&&(identical(other.currentPlayerIndex, currentPlayerIndex) || other.currentPlayerIndex == currentPlayerIndex)&&(identical(other.turnNumber, turnNumber) || other.turnNumber == turnNumber)&&(identical(other.turnPhase, turnPhase) || other.turnPhase == turnPhase)&&(identical(other.tradeCount, tradeCount) || other.tradeCount == tradeCount)&&const DeepCollectionEquality().equals(other._cards, _cards)&&const DeepCollectionEquality().equals(other._deck, _deck)&&(identical(other.conqueredThisTurn, conqueredThisTurn) || other.conqueredThisTurn == conqueredThisTurn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_territories),const DeepCollectionEquality().hash(_players),currentPlayerIndex,turnNumber,turnPhase,tradeCount,const DeepCollectionEquality().hash(_cards),const DeepCollectionEquality().hash(_deck),conqueredThisTurn);

@override
String toString() {
  return 'GameState(territories: $territories, players: $players, currentPlayerIndex: $currentPlayerIndex, turnNumber: $turnNumber, turnPhase: $turnPhase, tradeCount: $tradeCount, cards: $cards, deck: $deck, conqueredThisTurn: $conqueredThisTurn)';
}


}

/// @nodoc
abstract mixin class _$GameStateCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory _$GameStateCopyWith(_GameState value, $Res Function(_GameState) _then) = __$GameStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, TerritoryState> territories, List<PlayerState> players, int currentPlayerIndex, int turnNumber, TurnPhase turnPhase, int tradeCount, Map<String, List<Card>> cards, List<Card> deck, bool conqueredThisTurn
});




}
/// @nodoc
class __$GameStateCopyWithImpl<$Res>
    implements _$GameStateCopyWith<$Res> {
  __$GameStateCopyWithImpl(this._self, this._then);

  final _GameState _self;
  final $Res Function(_GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? territories = null,Object? players = null,Object? currentPlayerIndex = null,Object? turnNumber = null,Object? turnPhase = null,Object? tradeCount = null,Object? cards = null,Object? deck = null,Object? conqueredThisTurn = null,}) {
  return _then(_GameState(
territories: null == territories ? _self._territories : territories // ignore: cast_nullable_to_non_nullable
as Map<String, TerritoryState>,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as List<PlayerState>,currentPlayerIndex: null == currentPlayerIndex ? _self.currentPlayerIndex : currentPlayerIndex // ignore: cast_nullable_to_non_nullable
as int,turnNumber: null == turnNumber ? _self.turnNumber : turnNumber // ignore: cast_nullable_to_non_nullable
as int,turnPhase: null == turnPhase ? _self.turnPhase : turnPhase // ignore: cast_nullable_to_non_nullable
as TurnPhase,tradeCount: null == tradeCount ? _self.tradeCount : tradeCount // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as Map<String, List<Card>>,deck: null == deck ? _self._deck : deck // ignore: cast_nullable_to_non_nullable
as List<Card>,conqueredThisTurn: null == conqueredThisTurn ? _self.conqueredThisTurn : conqueredThisTurn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

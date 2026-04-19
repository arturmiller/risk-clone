// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UIState {

 String? get selectedTerritory; String? get selectedTarget; Set<String> get validTargets; Set<String> get validSources; int get pendingArmies; Map<String, int> get proposedPlacements;// Pending advance after conquest
 String? get advanceSource; String? get advanceTarget; int get advanceMin; int get advanceMax; int get diceCount;
/// Create a copy of UIState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UIStateCopyWith<UIState> get copyWith => _$UIStateCopyWithImpl<UIState>(this as UIState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UIState&&(identical(other.selectedTerritory, selectedTerritory) || other.selectedTerritory == selectedTerritory)&&(identical(other.selectedTarget, selectedTarget) || other.selectedTarget == selectedTarget)&&const DeepCollectionEquality().equals(other.validTargets, validTargets)&&const DeepCollectionEquality().equals(other.validSources, validSources)&&(identical(other.pendingArmies, pendingArmies) || other.pendingArmies == pendingArmies)&&const DeepCollectionEquality().equals(other.proposedPlacements, proposedPlacements)&&(identical(other.advanceSource, advanceSource) || other.advanceSource == advanceSource)&&(identical(other.advanceTarget, advanceTarget) || other.advanceTarget == advanceTarget)&&(identical(other.advanceMin, advanceMin) || other.advanceMin == advanceMin)&&(identical(other.advanceMax, advanceMax) || other.advanceMax == advanceMax)&&(identical(other.diceCount, diceCount) || other.diceCount == diceCount));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTerritory,selectedTarget,const DeepCollectionEquality().hash(validTargets),const DeepCollectionEquality().hash(validSources),pendingArmies,const DeepCollectionEquality().hash(proposedPlacements),advanceSource,advanceTarget,advanceMin,advanceMax,diceCount);

@override
String toString() {
  return 'UIState(selectedTerritory: $selectedTerritory, selectedTarget: $selectedTarget, validTargets: $validTargets, validSources: $validSources, pendingArmies: $pendingArmies, proposedPlacements: $proposedPlacements, advanceSource: $advanceSource, advanceTarget: $advanceTarget, advanceMin: $advanceMin, advanceMax: $advanceMax, diceCount: $diceCount)';
}


}

/// @nodoc
abstract mixin class $UIStateCopyWith<$Res>  {
  factory $UIStateCopyWith(UIState value, $Res Function(UIState) _then) = _$UIStateCopyWithImpl;
@useResult
$Res call({
 String? selectedTerritory, String? selectedTarget, Set<String> validTargets, Set<String> validSources, int pendingArmies, Map<String, int> proposedPlacements, String? advanceSource, String? advanceTarget, int advanceMin, int advanceMax, int diceCount
});




}
/// @nodoc
class _$UIStateCopyWithImpl<$Res>
    implements $UIStateCopyWith<$Res> {
  _$UIStateCopyWithImpl(this._self, this._then);

  final UIState _self;
  final $Res Function(UIState) _then;

/// Create a copy of UIState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTerritory = freezed,Object? selectedTarget = freezed,Object? validTargets = null,Object? validSources = null,Object? pendingArmies = null,Object? proposedPlacements = null,Object? advanceSource = freezed,Object? advanceTarget = freezed,Object? advanceMin = null,Object? advanceMax = null,Object? diceCount = null,}) {
  return _then(_self.copyWith(
selectedTerritory: freezed == selectedTerritory ? _self.selectedTerritory : selectedTerritory // ignore: cast_nullable_to_non_nullable
as String?,selectedTarget: freezed == selectedTarget ? _self.selectedTarget : selectedTarget // ignore: cast_nullable_to_non_nullable
as String?,validTargets: null == validTargets ? _self.validTargets : validTargets // ignore: cast_nullable_to_non_nullable
as Set<String>,validSources: null == validSources ? _self.validSources : validSources // ignore: cast_nullable_to_non_nullable
as Set<String>,pendingArmies: null == pendingArmies ? _self.pendingArmies : pendingArmies // ignore: cast_nullable_to_non_nullable
as int,proposedPlacements: null == proposedPlacements ? _self.proposedPlacements : proposedPlacements // ignore: cast_nullable_to_non_nullable
as Map<String, int>,advanceSource: freezed == advanceSource ? _self.advanceSource : advanceSource // ignore: cast_nullable_to_non_nullable
as String?,advanceTarget: freezed == advanceTarget ? _self.advanceTarget : advanceTarget // ignore: cast_nullable_to_non_nullable
as String?,advanceMin: null == advanceMin ? _self.advanceMin : advanceMin // ignore: cast_nullable_to_non_nullable
as int,advanceMax: null == advanceMax ? _self.advanceMax : advanceMax // ignore: cast_nullable_to_non_nullable
as int,diceCount: null == diceCount ? _self.diceCount : diceCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UIState].
extension UIStatePatterns on UIState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UIState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UIState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UIState value)  $default,){
final _that = this;
switch (_that) {
case _UIState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UIState value)?  $default,){
final _that = this;
switch (_that) {
case _UIState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? selectedTerritory,  String? selectedTarget,  Set<String> validTargets,  Set<String> validSources,  int pendingArmies,  Map<String, int> proposedPlacements,  String? advanceSource,  String? advanceTarget,  int advanceMin,  int advanceMax,  int diceCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UIState() when $default != null:
return $default(_that.selectedTerritory,_that.selectedTarget,_that.validTargets,_that.validSources,_that.pendingArmies,_that.proposedPlacements,_that.advanceSource,_that.advanceTarget,_that.advanceMin,_that.advanceMax,_that.diceCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? selectedTerritory,  String? selectedTarget,  Set<String> validTargets,  Set<String> validSources,  int pendingArmies,  Map<String, int> proposedPlacements,  String? advanceSource,  String? advanceTarget,  int advanceMin,  int advanceMax,  int diceCount)  $default,) {final _that = this;
switch (_that) {
case _UIState():
return $default(_that.selectedTerritory,_that.selectedTarget,_that.validTargets,_that.validSources,_that.pendingArmies,_that.proposedPlacements,_that.advanceSource,_that.advanceTarget,_that.advanceMin,_that.advanceMax,_that.diceCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? selectedTerritory,  String? selectedTarget,  Set<String> validTargets,  Set<String> validSources,  int pendingArmies,  Map<String, int> proposedPlacements,  String? advanceSource,  String? advanceTarget,  int advanceMin,  int advanceMax,  int diceCount)?  $default,) {final _that = this;
switch (_that) {
case _UIState() when $default != null:
return $default(_that.selectedTerritory,_that.selectedTarget,_that.validTargets,_that.validSources,_that.pendingArmies,_that.proposedPlacements,_that.advanceSource,_that.advanceTarget,_that.advanceMin,_that.advanceMax,_that.diceCount);case _:
  return null;

}
}

}

/// @nodoc


class _UIState implements UIState {
  const _UIState({this.selectedTerritory, this.selectedTarget, final  Set<String> validTargets = const {}, final  Set<String> validSources = const {}, this.pendingArmies = 0, final  Map<String, int> proposedPlacements = const {}, this.advanceSource, this.advanceTarget, this.advanceMin = 0, this.advanceMax = 0, this.diceCount = 3}): _validTargets = validTargets,_validSources = validSources,_proposedPlacements = proposedPlacements;
  

@override final  String? selectedTerritory;
@override final  String? selectedTarget;
 final  Set<String> _validTargets;
@override@JsonKey() Set<String> get validTargets {
  if (_validTargets is EqualUnmodifiableSetView) return _validTargets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_validTargets);
}

 final  Set<String> _validSources;
@override@JsonKey() Set<String> get validSources {
  if (_validSources is EqualUnmodifiableSetView) return _validSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_validSources);
}

@override@JsonKey() final  int pendingArmies;
 final  Map<String, int> _proposedPlacements;
@override@JsonKey() Map<String, int> get proposedPlacements {
  if (_proposedPlacements is EqualUnmodifiableMapView) return _proposedPlacements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_proposedPlacements);
}

// Pending advance after conquest
@override final  String? advanceSource;
@override final  String? advanceTarget;
@override@JsonKey() final  int advanceMin;
@override@JsonKey() final  int advanceMax;
@override@JsonKey() final  int diceCount;

/// Create a copy of UIState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UIStateCopyWith<_UIState> get copyWith => __$UIStateCopyWithImpl<_UIState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UIState&&(identical(other.selectedTerritory, selectedTerritory) || other.selectedTerritory == selectedTerritory)&&(identical(other.selectedTarget, selectedTarget) || other.selectedTarget == selectedTarget)&&const DeepCollectionEquality().equals(other._validTargets, _validTargets)&&const DeepCollectionEquality().equals(other._validSources, _validSources)&&(identical(other.pendingArmies, pendingArmies) || other.pendingArmies == pendingArmies)&&const DeepCollectionEquality().equals(other._proposedPlacements, _proposedPlacements)&&(identical(other.advanceSource, advanceSource) || other.advanceSource == advanceSource)&&(identical(other.advanceTarget, advanceTarget) || other.advanceTarget == advanceTarget)&&(identical(other.advanceMin, advanceMin) || other.advanceMin == advanceMin)&&(identical(other.advanceMax, advanceMax) || other.advanceMax == advanceMax)&&(identical(other.diceCount, diceCount) || other.diceCount == diceCount));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTerritory,selectedTarget,const DeepCollectionEquality().hash(_validTargets),const DeepCollectionEquality().hash(_validSources),pendingArmies,const DeepCollectionEquality().hash(_proposedPlacements),advanceSource,advanceTarget,advanceMin,advanceMax,diceCount);

@override
String toString() {
  return 'UIState(selectedTerritory: $selectedTerritory, selectedTarget: $selectedTarget, validTargets: $validTargets, validSources: $validSources, pendingArmies: $pendingArmies, proposedPlacements: $proposedPlacements, advanceSource: $advanceSource, advanceTarget: $advanceTarget, advanceMin: $advanceMin, advanceMax: $advanceMax, diceCount: $diceCount)';
}


}

/// @nodoc
abstract mixin class _$UIStateCopyWith<$Res> implements $UIStateCopyWith<$Res> {
  factory _$UIStateCopyWith(_UIState value, $Res Function(_UIState) _then) = __$UIStateCopyWithImpl;
@override @useResult
$Res call({
 String? selectedTerritory, String? selectedTarget, Set<String> validTargets, Set<String> validSources, int pendingArmies, Map<String, int> proposedPlacements, String? advanceSource, String? advanceTarget, int advanceMin, int advanceMax, int diceCount
});




}
/// @nodoc
class __$UIStateCopyWithImpl<$Res>
    implements _$UIStateCopyWith<$Res> {
  __$UIStateCopyWithImpl(this._self, this._then);

  final _UIState _self;
  final $Res Function(_UIState) _then;

/// Create a copy of UIState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTerritory = freezed,Object? selectedTarget = freezed,Object? validTargets = null,Object? validSources = null,Object? pendingArmies = null,Object? proposedPlacements = null,Object? advanceSource = freezed,Object? advanceTarget = freezed,Object? advanceMin = null,Object? advanceMax = null,Object? diceCount = null,}) {
  return _then(_UIState(
selectedTerritory: freezed == selectedTerritory ? _self.selectedTerritory : selectedTerritory // ignore: cast_nullable_to_non_nullable
as String?,selectedTarget: freezed == selectedTarget ? _self.selectedTarget : selectedTarget // ignore: cast_nullable_to_non_nullable
as String?,validTargets: null == validTargets ? _self._validTargets : validTargets // ignore: cast_nullable_to_non_nullable
as Set<String>,validSources: null == validSources ? _self._validSources : validSources // ignore: cast_nullable_to_non_nullable
as Set<String>,pendingArmies: null == pendingArmies ? _self.pendingArmies : pendingArmies // ignore: cast_nullable_to_non_nullable
as int,proposedPlacements: null == proposedPlacements ? _self._proposedPlacements : proposedPlacements // ignore: cast_nullable_to_non_nullable
as Map<String, int>,advanceSource: freezed == advanceSource ? _self.advanceSource : advanceSource // ignore: cast_nullable_to_non_nullable
as String?,advanceTarget: freezed == advanceTarget ? _self.advanceTarget : advanceTarget // ignore: cast_nullable_to_non_nullable
as String?,advanceMin: null == advanceMin ? _self.advanceMin : advanceMin // ignore: cast_nullable_to_non_nullable
as int,advanceMax: null == advanceMax ? _self.advanceMax : advanceMax // ignore: cast_nullable_to_non_nullable
as int,diceCount: null == diceCount ? _self.diceCount : diceCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

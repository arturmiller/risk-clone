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

 String? get selectedTerritory; Set<String> get validTargets; Set<String> get validSources;
/// Create a copy of UIState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UIStateCopyWith<UIState> get copyWith => _$UIStateCopyWithImpl<UIState>(this as UIState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UIState&&(identical(other.selectedTerritory, selectedTerritory) || other.selectedTerritory == selectedTerritory)&&const DeepCollectionEquality().equals(other.validTargets, validTargets)&&const DeepCollectionEquality().equals(other.validSources, validSources));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTerritory,const DeepCollectionEquality().hash(validTargets),const DeepCollectionEquality().hash(validSources));

@override
String toString() {
  return 'UIState(selectedTerritory: $selectedTerritory, validTargets: $validTargets, validSources: $validSources)';
}


}

/// @nodoc
abstract mixin class $UIStateCopyWith<$Res>  {
  factory $UIStateCopyWith(UIState value, $Res Function(UIState) _then) = _$UIStateCopyWithImpl;
@useResult
$Res call({
 String? selectedTerritory, Set<String> validTargets, Set<String> validSources
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
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTerritory = freezed,Object? validTargets = null,Object? validSources = null,}) {
  return _then(_self.copyWith(
selectedTerritory: freezed == selectedTerritory ? _self.selectedTerritory : selectedTerritory // ignore: cast_nullable_to_non_nullable
as String?,validTargets: null == validTargets ? _self.validTargets : validTargets // ignore: cast_nullable_to_non_nullable
as Set<String>,validSources: null == validSources ? _self.validSources : validSources // ignore: cast_nullable_to_non_nullable
as Set<String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? selectedTerritory,  Set<String> validTargets,  Set<String> validSources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UIState() when $default != null:
return $default(_that.selectedTerritory,_that.validTargets,_that.validSources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? selectedTerritory,  Set<String> validTargets,  Set<String> validSources)  $default,) {final _that = this;
switch (_that) {
case _UIState():
return $default(_that.selectedTerritory,_that.validTargets,_that.validSources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? selectedTerritory,  Set<String> validTargets,  Set<String> validSources)?  $default,) {final _that = this;
switch (_that) {
case _UIState() when $default != null:
return $default(_that.selectedTerritory,_that.validTargets,_that.validSources);case _:
  return null;

}
}

}

/// @nodoc


class _UIState implements UIState {
  const _UIState({this.selectedTerritory, final  Set<String> validTargets = const {}, final  Set<String> validSources = const {}}): _validTargets = validTargets,_validSources = validSources;
  

@override final  String? selectedTerritory;
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


/// Create a copy of UIState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UIStateCopyWith<_UIState> get copyWith => __$UIStateCopyWithImpl<_UIState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UIState&&(identical(other.selectedTerritory, selectedTerritory) || other.selectedTerritory == selectedTerritory)&&const DeepCollectionEquality().equals(other._validTargets, _validTargets)&&const DeepCollectionEquality().equals(other._validSources, _validSources));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTerritory,const DeepCollectionEquality().hash(_validTargets),const DeepCollectionEquality().hash(_validSources));

@override
String toString() {
  return 'UIState(selectedTerritory: $selectedTerritory, validTargets: $validTargets, validSources: $validSources)';
}


}

/// @nodoc
abstract mixin class _$UIStateCopyWith<$Res> implements $UIStateCopyWith<$Res> {
  factory _$UIStateCopyWith(_UIState value, $Res Function(_UIState) _then) = __$UIStateCopyWithImpl;
@override @useResult
$Res call({
 String? selectedTerritory, Set<String> validTargets, Set<String> validSources
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
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTerritory = freezed,Object? validTargets = null,Object? validSources = null,}) {
  return _then(_UIState(
selectedTerritory: freezed == selectedTerritory ? _self.selectedTerritory : selectedTerritory // ignore: cast_nullable_to_non_nullable
as String?,validTargets: null == validTargets ? _self._validTargets : validTargets // ignore: cast_nullable_to_non_nullable
as Set<String>,validSources: null == validSources ? _self._validSources : validSources // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContinentData {

 String get name; List<String> get territories; int get bonus;
/// Create a copy of ContinentData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContinentDataCopyWith<ContinentData> get copyWith => _$ContinentDataCopyWithImpl<ContinentData>(this as ContinentData, _$identity);

  /// Serializes this ContinentData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContinentData&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.territories, territories)&&(identical(other.bonus, bonus) || other.bonus == bonus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(territories),bonus);

@override
String toString() {
  return 'ContinentData(name: $name, territories: $territories, bonus: $bonus)';
}


}

/// @nodoc
abstract mixin class $ContinentDataCopyWith<$Res>  {
  factory $ContinentDataCopyWith(ContinentData value, $Res Function(ContinentData) _then) = _$ContinentDataCopyWithImpl;
@useResult
$Res call({
 String name, List<String> territories, int bonus
});




}
/// @nodoc
class _$ContinentDataCopyWithImpl<$Res>
    implements $ContinentDataCopyWith<$Res> {
  _$ContinentDataCopyWithImpl(this._self, this._then);

  final ContinentData _self;
  final $Res Function(ContinentData) _then;

/// Create a copy of ContinentData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? territories = null,Object? bonus = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,territories: null == territories ? _self.territories : territories // ignore: cast_nullable_to_non_nullable
as List<String>,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ContinentData].
extension ContinentDataPatterns on ContinentData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContinentData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContinentData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContinentData value)  $default,){
final _that = this;
switch (_that) {
case _ContinentData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContinentData value)?  $default,){
final _that = this;
switch (_that) {
case _ContinentData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<String> territories,  int bonus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContinentData() when $default != null:
return $default(_that.name,_that.territories,_that.bonus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<String> territories,  int bonus)  $default,) {final _that = this;
switch (_that) {
case _ContinentData():
return $default(_that.name,_that.territories,_that.bonus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<String> territories,  int bonus)?  $default,) {final _that = this;
switch (_that) {
case _ContinentData() when $default != null:
return $default(_that.name,_that.territories,_that.bonus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContinentData implements ContinentData {
  const _ContinentData({required this.name, required final  List<String> territories, required this.bonus}): _territories = territories;
  factory _ContinentData.fromJson(Map<String, dynamic> json) => _$ContinentDataFromJson(json);

@override final  String name;
 final  List<String> _territories;
@override List<String> get territories {
  if (_territories is EqualUnmodifiableListView) return _territories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_territories);
}

@override final  int bonus;

/// Create a copy of ContinentData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContinentDataCopyWith<_ContinentData> get copyWith => __$ContinentDataCopyWithImpl<_ContinentData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContinentDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContinentData&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._territories, _territories)&&(identical(other.bonus, bonus) || other.bonus == bonus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_territories),bonus);

@override
String toString() {
  return 'ContinentData(name: $name, territories: $territories, bonus: $bonus)';
}


}

/// @nodoc
abstract mixin class _$ContinentDataCopyWith<$Res> implements $ContinentDataCopyWith<$Res> {
  factory _$ContinentDataCopyWith(_ContinentData value, $Res Function(_ContinentData) _then) = __$ContinentDataCopyWithImpl;
@override @useResult
$Res call({
 String name, List<String> territories, int bonus
});




}
/// @nodoc
class __$ContinentDataCopyWithImpl<$Res>
    implements _$ContinentDataCopyWith<$Res> {
  __$ContinentDataCopyWithImpl(this._self, this._then);

  final _ContinentData _self;
  final $Res Function(_ContinentData) _then;

/// Create a copy of ContinentData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? territories = null,Object? bonus = null,}) {
  return _then(_ContinentData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,territories: null == territories ? _self._territories : territories // ignore: cast_nullable_to_non_nullable
as List<String>,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MapData {

 String get name; List<String> get territories; List<ContinentData> get continents; List<List<String>> get adjacencies;
/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapDataCopyWith<MapData> get copyWith => _$MapDataCopyWithImpl<MapData>(this as MapData, _$identity);

  /// Serializes this MapData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapData&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.territories, territories)&&const DeepCollectionEquality().equals(other.continents, continents)&&const DeepCollectionEquality().equals(other.adjacencies, adjacencies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(territories),const DeepCollectionEquality().hash(continents),const DeepCollectionEquality().hash(adjacencies));

@override
String toString() {
  return 'MapData(name: $name, territories: $territories, continents: $continents, adjacencies: $adjacencies)';
}


}

/// @nodoc
abstract mixin class $MapDataCopyWith<$Res>  {
  factory $MapDataCopyWith(MapData value, $Res Function(MapData) _then) = _$MapDataCopyWithImpl;
@useResult
$Res call({
 String name, List<String> territories, List<ContinentData> continents, List<List<String>> adjacencies
});




}
/// @nodoc
class _$MapDataCopyWithImpl<$Res>
    implements $MapDataCopyWith<$Res> {
  _$MapDataCopyWithImpl(this._self, this._then);

  final MapData _self;
  final $Res Function(MapData) _then;

/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? territories = null,Object? continents = null,Object? adjacencies = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,territories: null == territories ? _self.territories : territories // ignore: cast_nullable_to_non_nullable
as List<String>,continents: null == continents ? _self.continents : continents // ignore: cast_nullable_to_non_nullable
as List<ContinentData>,adjacencies: null == adjacencies ? _self.adjacencies : adjacencies // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [MapData].
extension MapDataPatterns on MapData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapData value)  $default,){
final _that = this;
switch (_that) {
case _MapData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapData value)?  $default,){
final _that = this;
switch (_that) {
case _MapData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<String> territories,  List<ContinentData> continents,  List<List<String>> adjacencies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapData() when $default != null:
return $default(_that.name,_that.territories,_that.continents,_that.adjacencies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<String> territories,  List<ContinentData> continents,  List<List<String>> adjacencies)  $default,) {final _that = this;
switch (_that) {
case _MapData():
return $default(_that.name,_that.territories,_that.continents,_that.adjacencies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<String> territories,  List<ContinentData> continents,  List<List<String>> adjacencies)?  $default,) {final _that = this;
switch (_that) {
case _MapData() when $default != null:
return $default(_that.name,_that.territories,_that.continents,_that.adjacencies);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MapData implements MapData {
  const _MapData({required this.name, required final  List<String> territories, required final  List<ContinentData> continents, required final  List<List<String>> adjacencies}): _territories = territories,_continents = continents,_adjacencies = adjacencies;
  factory _MapData.fromJson(Map<String, dynamic> json) => _$MapDataFromJson(json);

@override final  String name;
 final  List<String> _territories;
@override List<String> get territories {
  if (_territories is EqualUnmodifiableListView) return _territories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_territories);
}

 final  List<ContinentData> _continents;
@override List<ContinentData> get continents {
  if (_continents is EqualUnmodifiableListView) return _continents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_continents);
}

 final  List<List<String>> _adjacencies;
@override List<List<String>> get adjacencies {
  if (_adjacencies is EqualUnmodifiableListView) return _adjacencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_adjacencies);
}


/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapDataCopyWith<_MapData> get copyWith => __$MapDataCopyWithImpl<_MapData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapData&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._territories, _territories)&&const DeepCollectionEquality().equals(other._continents, _continents)&&const DeepCollectionEquality().equals(other._adjacencies, _adjacencies));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_territories),const DeepCollectionEquality().hash(_continents),const DeepCollectionEquality().hash(_adjacencies));

@override
String toString() {
  return 'MapData(name: $name, territories: $territories, continents: $continents, adjacencies: $adjacencies)';
}


}

/// @nodoc
abstract mixin class _$MapDataCopyWith<$Res> implements $MapDataCopyWith<$Res> {
  factory _$MapDataCopyWith(_MapData value, $Res Function(_MapData) _then) = __$MapDataCopyWithImpl;
@override @useResult
$Res call({
 String name, List<String> territories, List<ContinentData> continents, List<List<String>> adjacencies
});




}
/// @nodoc
class __$MapDataCopyWithImpl<$Res>
    implements _$MapDataCopyWith<$Res> {
  __$MapDataCopyWithImpl(this._self, this._then);

  final _MapData _self;
  final $Res Function(_MapData) _then;

/// Create a copy of MapData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? territories = null,Object? continents = null,Object? adjacencies = null,}) {
  return _then(_MapData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,territories: null == territories ? _self._territories : territories // ignore: cast_nullable_to_non_nullable
as List<String>,continents: null == continents ? _self._continents : continents // ignore: cast_nullable_to_non_nullable
as List<ContinentData>,adjacencies: null == adjacencies ? _self._adjacencies : adjacencies // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}


}

// dart format on

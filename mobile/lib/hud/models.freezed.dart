// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HudConfig {

 int get version; HudTheme get theme; Map<String, HudLayout> get layouts;
/// Create a copy of HudConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HudConfigCopyWith<HudConfig> get copyWith => _$HudConfigCopyWithImpl<HudConfig>(this as HudConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HudConfig&&(identical(other.version, version) || other.version == version)&&(identical(other.theme, theme) || other.theme == theme)&&const DeepCollectionEquality().equals(other.layouts, layouts));
}


@override
int get hashCode => Object.hash(runtimeType,version,theme,const DeepCollectionEquality().hash(layouts));

@override
String toString() {
  return 'HudConfig(version: $version, theme: $theme, layouts: $layouts)';
}


}

/// @nodoc
abstract mixin class $HudConfigCopyWith<$Res>  {
  factory $HudConfigCopyWith(HudConfig value, $Res Function(HudConfig) _then) = _$HudConfigCopyWithImpl;
@useResult
$Res call({
 int version, HudTheme theme, Map<String, HudLayout> layouts
});


$HudThemeCopyWith<$Res> get theme;

}
/// @nodoc
class _$HudConfigCopyWithImpl<$Res>
    implements $HudConfigCopyWith<$Res> {
  _$HudConfigCopyWithImpl(this._self, this._then);

  final HudConfig _self;
  final $Res Function(HudConfig) _then;

/// Create a copy of HudConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? theme = null,Object? layouts = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as HudTheme,layouts: null == layouts ? _self.layouts : layouts // ignore: cast_nullable_to_non_nullable
as Map<String, HudLayout>,
  ));
}
/// Create a copy of HudConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HudThemeCopyWith<$Res> get theme {
  
  return $HudThemeCopyWith<$Res>(_self.theme, (value) {
    return _then(_self.copyWith(theme: value));
  });
}
}


/// Adds pattern-matching-related methods to [HudConfig].
extension HudConfigPatterns on HudConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HudConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HudConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HudConfig value)  $default,){
final _that = this;
switch (_that) {
case _HudConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HudConfig value)?  $default,){
final _that = this;
switch (_that) {
case _HudConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  HudTheme theme,  Map<String, HudLayout> layouts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HudConfig() when $default != null:
return $default(_that.version,_that.theme,_that.layouts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  HudTheme theme,  Map<String, HudLayout> layouts)  $default,) {final _that = this;
switch (_that) {
case _HudConfig():
return $default(_that.version,_that.theme,_that.layouts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  HudTheme theme,  Map<String, HudLayout> layouts)?  $default,) {final _that = this;
switch (_that) {
case _HudConfig() when $default != null:
return $default(_that.version,_that.theme,_that.layouts);case _:
  return null;

}
}

}

/// @nodoc


class _HudConfig implements HudConfig {
  const _HudConfig({required this.version, required this.theme, required final  Map<String, HudLayout> layouts}): _layouts = layouts;
  

@override final  int version;
@override final  HudTheme theme;
 final  Map<String, HudLayout> _layouts;
@override Map<String, HudLayout> get layouts {
  if (_layouts is EqualUnmodifiableMapView) return _layouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_layouts);
}


/// Create a copy of HudConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HudConfigCopyWith<_HudConfig> get copyWith => __$HudConfigCopyWithImpl<_HudConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HudConfig&&(identical(other.version, version) || other.version == version)&&(identical(other.theme, theme) || other.theme == theme)&&const DeepCollectionEquality().equals(other._layouts, _layouts));
}


@override
int get hashCode => Object.hash(runtimeType,version,theme,const DeepCollectionEquality().hash(_layouts));

@override
String toString() {
  return 'HudConfig(version: $version, theme: $theme, layouts: $layouts)';
}


}

/// @nodoc
abstract mixin class _$HudConfigCopyWith<$Res> implements $HudConfigCopyWith<$Res> {
  factory _$HudConfigCopyWith(_HudConfig value, $Res Function(_HudConfig) _then) = __$HudConfigCopyWithImpl;
@override @useResult
$Res call({
 int version, HudTheme theme, Map<String, HudLayout> layouts
});


@override $HudThemeCopyWith<$Res> get theme;

}
/// @nodoc
class __$HudConfigCopyWithImpl<$Res>
    implements _$HudConfigCopyWith<$Res> {
  __$HudConfigCopyWithImpl(this._self, this._then);

  final _HudConfig _self;
  final $Res Function(_HudConfig) _then;

/// Create a copy of HudConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? theme = null,Object? layouts = null,}) {
  return _then(_HudConfig(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as HudTheme,layouts: null == layouts ? _self._layouts : layouts // ignore: cast_nullable_to_non_nullable
as Map<String, HudLayout>,
  ));
}

/// Create a copy of HudConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HudThemeCopyWith<$Res> get theme {
  
  return $HudThemeCopyWith<$Res>(_self.theme, (value) {
    return _then(_self.copyWith(theme: value));
  });
}
}

/// @nodoc
mixin _$HudTheme {

 String get background; String get border; String get text; num get borderRadius;
/// Create a copy of HudTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HudThemeCopyWith<HudTheme> get copyWith => _$HudThemeCopyWithImpl<HudTheme>(this as HudTheme, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HudTheme&&(identical(other.background, background) || other.background == background)&&(identical(other.border, border) || other.border == border)&&(identical(other.text, text) || other.text == text)&&(identical(other.borderRadius, borderRadius) || other.borderRadius == borderRadius));
}


@override
int get hashCode => Object.hash(runtimeType,background,border,text,borderRadius);

@override
String toString() {
  return 'HudTheme(background: $background, border: $border, text: $text, borderRadius: $borderRadius)';
}


}

/// @nodoc
abstract mixin class $HudThemeCopyWith<$Res>  {
  factory $HudThemeCopyWith(HudTheme value, $Res Function(HudTheme) _then) = _$HudThemeCopyWithImpl;
@useResult
$Res call({
 String background, String border, String text, num borderRadius
});




}
/// @nodoc
class _$HudThemeCopyWithImpl<$Res>
    implements $HudThemeCopyWith<$Res> {
  _$HudThemeCopyWithImpl(this._self, this._then);

  final HudTheme _self;
  final $Res Function(HudTheme) _then;

/// Create a copy of HudTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? background = null,Object? border = null,Object? text = null,Object? borderRadius = null,}) {
  return _then(_self.copyWith(
background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,borderRadius: null == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [HudTheme].
extension HudThemePatterns on HudTheme {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HudTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HudTheme() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HudTheme value)  $default,){
final _that = this;
switch (_that) {
case _HudTheme():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HudTheme value)?  $default,){
final _that = this;
switch (_that) {
case _HudTheme() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String background,  String border,  String text,  num borderRadius)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HudTheme() when $default != null:
return $default(_that.background,_that.border,_that.text,_that.borderRadius);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String background,  String border,  String text,  num borderRadius)  $default,) {final _that = this;
switch (_that) {
case _HudTheme():
return $default(_that.background,_that.border,_that.text,_that.borderRadius);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String background,  String border,  String text,  num borderRadius)?  $default,) {final _that = this;
switch (_that) {
case _HudTheme() when $default != null:
return $default(_that.background,_that.border,_that.text,_that.borderRadius);case _:
  return null;

}
}

}

/// @nodoc


class _HudTheme implements HudTheme {
  const _HudTheme({required this.background, required this.border, required this.text, required this.borderRadius});
  

@override final  String background;
@override final  String border;
@override final  String text;
@override final  num borderRadius;

/// Create a copy of HudTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HudThemeCopyWith<_HudTheme> get copyWith => __$HudThemeCopyWithImpl<_HudTheme>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HudTheme&&(identical(other.background, background) || other.background == background)&&(identical(other.border, border) || other.border == border)&&(identical(other.text, text) || other.text == text)&&(identical(other.borderRadius, borderRadius) || other.borderRadius == borderRadius));
}


@override
int get hashCode => Object.hash(runtimeType,background,border,text,borderRadius);

@override
String toString() {
  return 'HudTheme(background: $background, border: $border, text: $text, borderRadius: $borderRadius)';
}


}

/// @nodoc
abstract mixin class _$HudThemeCopyWith<$Res> implements $HudThemeCopyWith<$Res> {
  factory _$HudThemeCopyWith(_HudTheme value, $Res Function(_HudTheme) _then) = __$HudThemeCopyWithImpl;
@override @useResult
$Res call({
 String background, String border, String text, num borderRadius
});




}
/// @nodoc
class __$HudThemeCopyWithImpl<$Res>
    implements _$HudThemeCopyWith<$Res> {
  __$HudThemeCopyWithImpl(this._self, this._then);

  final _HudTheme _self;
  final $Res Function(_HudTheme) _then;

/// Create a copy of HudTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? background = null,Object? border = null,Object? text = null,Object? borderRadius = null,}) {
  return _then(_HudTheme(
background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,borderRadius: null == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

/// @nodoc
mixin _$HudLayout {

 List<num> get canvasSize; HudElement get root;
/// Create a copy of HudLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HudLayoutCopyWith<HudLayout> get copyWith => _$HudLayoutCopyWithImpl<HudLayout>(this as HudLayout, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HudLayout&&const DeepCollectionEquality().equals(other.canvasSize, canvasSize)&&(identical(other.root, root) || other.root == root));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(canvasSize),root);

@override
String toString() {
  return 'HudLayout(canvasSize: $canvasSize, root: $root)';
}


}

/// @nodoc
abstract mixin class $HudLayoutCopyWith<$Res>  {
  factory $HudLayoutCopyWith(HudLayout value, $Res Function(HudLayout) _then) = _$HudLayoutCopyWithImpl;
@useResult
$Res call({
 List<num> canvasSize, HudElement root
});




}
/// @nodoc
class _$HudLayoutCopyWithImpl<$Res>
    implements $HudLayoutCopyWith<$Res> {
  _$HudLayoutCopyWithImpl(this._self, this._then);

  final HudLayout _self;
  final $Res Function(HudLayout) _then;

/// Create a copy of HudLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canvasSize = null,Object? root = null,}) {
  return _then(_self.copyWith(
canvasSize: null == canvasSize ? _self.canvasSize : canvasSize // ignore: cast_nullable_to_non_nullable
as List<num>,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as HudElement,
  ));
}

}


/// Adds pattern-matching-related methods to [HudLayout].
extension HudLayoutPatterns on HudLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HudLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HudLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HudLayout value)  $default,){
final _that = this;
switch (_that) {
case _HudLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HudLayout value)?  $default,){
final _that = this;
switch (_that) {
case _HudLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<num> canvasSize,  HudElement root)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HudLayout() when $default != null:
return $default(_that.canvasSize,_that.root);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<num> canvasSize,  HudElement root)  $default,) {final _that = this;
switch (_that) {
case _HudLayout():
return $default(_that.canvasSize,_that.root);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<num> canvasSize,  HudElement root)?  $default,) {final _that = this;
switch (_that) {
case _HudLayout() when $default != null:
return $default(_that.canvasSize,_that.root);case _:
  return null;

}
}

}

/// @nodoc


class _HudLayout implements HudLayout {
  const _HudLayout({required final  List<num> canvasSize, required this.root}): _canvasSize = canvasSize;
  

 final  List<num> _canvasSize;
@override List<num> get canvasSize {
  if (_canvasSize is EqualUnmodifiableListView) return _canvasSize;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_canvasSize);
}

@override final  HudElement root;

/// Create a copy of HudLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HudLayoutCopyWith<_HudLayout> get copyWith => __$HudLayoutCopyWithImpl<_HudLayout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HudLayout&&const DeepCollectionEquality().equals(other._canvasSize, _canvasSize)&&(identical(other.root, root) || other.root == root));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_canvasSize),root);

@override
String toString() {
  return 'HudLayout(canvasSize: $canvasSize, root: $root)';
}


}

/// @nodoc
abstract mixin class _$HudLayoutCopyWith<$Res> implements $HudLayoutCopyWith<$Res> {
  factory _$HudLayoutCopyWith(_HudLayout value, $Res Function(_HudLayout) _then) = __$HudLayoutCopyWithImpl;
@override @useResult
$Res call({
 List<num> canvasSize, HudElement root
});




}
/// @nodoc
class __$HudLayoutCopyWithImpl<$Res>
    implements _$HudLayoutCopyWith<$Res> {
  __$HudLayoutCopyWithImpl(this._self, this._then);

  final _HudLayout _self;
  final $Res Function(_HudLayout) _then;

/// Create a copy of HudLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canvasSize = null,Object? root = null,}) {
  return _then(_HudLayout(
canvasSize: null == canvasSize ? _self._canvasSize : canvasSize // ignore: cast_nullable_to_non_nullable
as List<num>,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as HudElement,
  ));
}


}

// dart format on

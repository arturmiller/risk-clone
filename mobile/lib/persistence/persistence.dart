/// Platform-conditional persistence facade.
/// On native: delegates to ObjectBox via app_store_native.dart.
/// On web: delegates to no-op stubs via app_store_web.dart.
///
/// This file uses conditional imports so ObjectBox FFI code is never
/// compiled when targeting web.
export 'app_store_native.dart'
    if (dart.library.js_interop) 'app_store_web.dart';

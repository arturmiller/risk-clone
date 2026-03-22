import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that holds the persistence store.
/// On native: ObjectBox Store. On web: no-op WebStore.
/// Override with actual store in main.dart via ProviderScope.overrides.
final storeProvider = Provider<Object>(
  (ref) => throw UnimplementedError('storeProvider must be overridden at startup'),
);

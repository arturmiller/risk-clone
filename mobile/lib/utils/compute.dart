import 'package:flutter/foundation.dart' show kIsWeb, compute;

/// Run a computation in an isolate on native, or inline on web.
/// Drop-in replacement for Isolate.run() that works on all platforms.
Future<R> runCompute<R>(R Function() callback) async {
  if (kIsWeb) {
    return callback();
  }
  // On native, use Flutter's compute() which handles isolate spawning.
  return compute((_) => callback(), null);
}

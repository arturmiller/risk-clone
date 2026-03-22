import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'persistence/app_store.dart';
import 'persistence/persistence.dart' as persistence;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    debugPrint('Stack: $stack');
    return true;
  };

  try {
    debugPrint('[main] opening store...');
    final store = await persistence.openRiskStore();
    debugPrint('[main] store opened: $store');
    runApp(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
        ],
        child: const RiskApp(),
      ),
    );
    debugPrint('[main] runApp called');
  } catch (e, s) {
    debugPrint('[main] FATAL: $e');
    debugPrint('[main] stack: $s');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

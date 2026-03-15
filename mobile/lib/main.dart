import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'persistence/app_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openRiskStore();
  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
      ],
      child: const RiskApp(),
    ),
  );
}

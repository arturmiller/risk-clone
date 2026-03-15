import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class RiskApp extends StatelessWidget {
  const RiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Risk',
      theme: ThemeData(colorSchemeSeed: Colors.red),
      home: const HomeScreen(),
    );
  }
}

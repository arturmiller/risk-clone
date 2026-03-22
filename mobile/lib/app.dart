import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class RiskApp extends StatelessWidget {
  const RiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Risk',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomeScreen(),
    );
  }
}

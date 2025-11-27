import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(const DraughtsApp());
}

class DraughtsApp extends StatelessWidget {
  const DraughtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draughts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F3460),
          brightness: Brightness.dark,
        ),
      ),
      home: const MenuScreen(),
    );
  }
}

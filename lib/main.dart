import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const DarkHoursApp());
}

class DarkHoursApp extends StatelessWidget {
  const DarkHoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Темные часы',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 10, 10, 10),
        fontFamily: 'RobotoMono',
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}
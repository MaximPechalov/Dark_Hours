import 'package:flutter/material.dart';
import 'package:dark_hours/screens/main/splash_screen.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.init();
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
      home: const SplashScreen(),
    );
  }
}
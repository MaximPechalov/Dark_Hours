import 'package:flutter/material.dart';
import 'package:dark_hours/screens/main/splash_screen.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/services/items/item_icon_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация аудио.
  await AudioService.init();

  // Инициализация загрузчика иконок предметов.
  await ItemIconLoader.init();

  // === ВРЕМЕННАЯ ДИАГНОСТИКА ===
  // УДАЛИТЬ ПОСЛЕ РЕШЕНИЯ ПРОБЛЕМЫ С ИКОНКАМИ
  debugPrint('═══════════════════════════════════════');
  debugPrint('🖼️ ItemIconLoader');
  debugPrint('   Загружено иконок: ${ItemIconLoader.loadedCount}');
  debugPrint('   Доступные ID: ${ItemIconLoader.availableIds}');
  debugPrint('   Пути:');
  for (final path in ItemIconLoader.allPaths) {
    debugPrint('     $path');
  }
  debugPrint('═══════════════════════════════════════');

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
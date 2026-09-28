import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/save_data.dart';

class SaveManager {
  static const String _saveKey = 'dark_hours_save';

  /// Сохранить прогресс
  static Future<bool> save(SaveData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      return await prefs.setString(_saveKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Загрузить прогресс
  static Future<SaveData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_saveKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return SaveData.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Есть ли сохранение?
  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  /// Удалить сохранение
  static Future<bool> delete() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_saveKey);
  }

  /// Дата последнего сохранения в читаемом виде
  static String formatSaveDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';

    return '${date.day}.${date.month}.${date.year}';
  }
}
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Настройки звука — хранятся в SharedPreferences
class AudioSettings {
  static const String _keyMaster = 'audio_master_volume';
  static const String _keyMusic = 'audio_music_volume';
  static const String _keySfx = 'audio_sfx_volume';
  static const String _keyMuted = 'audio_muted';

  // Значения по умолчанию
  static const double defaultMaster = 0.8;
  static const double defaultMusic = 0.5;
  static const double defaultSfx = 0.7;
  static const bool defaultMuted = false;

  /// Загрузить все настройки
  static Future<AudioSettingsData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AudioSettingsData(
        masterVolume: prefs.getDouble(_keyMaster) ?? defaultMaster,
        musicVolume: prefs.getDouble(_keyMusic) ?? defaultMusic,
        sfxVolume: prefs.getDouble(_keySfx) ?? defaultSfx,
        muted: prefs.getBool(_keyMuted) ?? defaultMuted,
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки настроек звука: $e');
      return const AudioSettingsData(
        masterVolume: defaultMaster,
        musicVolume: defaultMusic,
        sfxVolume: defaultSfx,
        muted: defaultMuted,
      );
    }
  }

  /// Сохранить все настройки
  static Future<void> save(AudioSettingsData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyMaster, data.masterVolume);
      await prefs.setDouble(_keyMusic, data.musicVolume);
      await prefs.setDouble(_keySfx, data.sfxVolume);
      await prefs.setBool(_keyMuted, data.muted);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения настроек звука: $e');
    }
  }

  /// Сбросить к значениям по умолчанию
  static Future<void> reset() async {
    await save(const AudioSettingsData(
      masterVolume: defaultMaster,
      musicVolume: defaultMusic,
      sfxVolume: defaultSfx,
      muted: defaultMuted,
    ));
  }
}

/// Данные настроек звука
class AudioSettingsData {
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final bool muted;

  const AudioSettingsData({
    required this.masterVolume,
    required this.musicVolume,
    required this.sfxVolume,
    required this.muted,
  });

  AudioSettingsData copyWith({
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    bool? muted,
  }) {
    return AudioSettingsData(
      masterVolume: masterVolume ?? this.masterVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      muted: muted ?? this.muted,
    );
  }
}
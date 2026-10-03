import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:dark_hours/services/audio/audio_settings.dart';

/// Центральный сервис для воспроизведения звуков
class AudioService {
  // ===== ФЛАГ ДЛЯ ТЕСТОВ =====

  /// Отключить звук — используется в widget-тестах.
  ///
  /// По умолчанию `true` — звук работает как обычно.
  /// В тестах выставляется в `false`, чтобы избежать
  /// обращения к platform channels `audioplayers`.
  static bool enabled = true;

  // ===== КАНАЛЫ =====

  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final AudioPlayer _ambiencePlayer = AudioPlayer();

  static final List<AudioPlayer> _sfxPool = [
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
  ];
  static int _sfxIndex = 0;

  // ===== ГРОМКОСТИ =====

  static double _masterVolume = AudioSettings.defaultMaster;
  static double _musicVolume = AudioSettings.defaultMusic;
  static double _sfxVolume = AudioSettings.defaultSfx;
  static bool _isMuted = AudioSettings.defaultMuted;

  static double get masterVolume => _masterVolume;
  static double get musicVolume => _musicVolume;
  static double get sfxVolume => _sfxVolume;
  static bool get isMuted => _isMuted;

  // ===== ФЛАГИ =====

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static String? _currentAmbience;
  static String? get currentAmbience => _currentAmbience;

  static String? _currentMusic;
  static String? get currentMusic => _currentMusic;

  // ===== ИНИЦИАЛИЗАЦИЯ =====

  static Future<void> init() async {
    if (!enabled) return;
    if (_isInitialized) return;

    final settings = await AudioSettings.load();
    _masterVolume = settings.masterVolume;
    _musicVolume = settings.musicVolume;
    _sfxVolume = settings.sfxVolume;
    _isMuted = settings.muted;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);

    for (final player in _sfxPool) {
      await player.setReleaseMode(ReleaseMode.stop);
    }

    await _applyVolumes();

    _isInitialized = true;
    debugPrint('🔊 AudioService инициализирован '
        '(master=$_masterVolume, music=$_musicVolume, '
        'sfx=$_sfxVolume, muted=$_isMuted)');
  }

  // ===== ВНУТРЕННИЙ ХЕЛПЕР =====

  static double _effectiveVolume(double base) {
    if (_isMuted) return 0.0;
    return base;
  }

  // ===== SFX =====

  static Future<void> playSfx(
    String path, {
    double volume = 1.0,
  }) async {
    if (!enabled) return;
    if (!_isInitialized) await init();
    if (_isMuted) return;

    try {
      final player = _sfxPool[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;

      await player.stop();
      await player.setVolume(_sfxVolume * _masterVolume * volume);
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('❌ Ошибка воспроизведения SFX: $path — $e');
    }
  }

  static Future<void> playClick() async {
    if (!enabled) return;
    await playSfx('audio/ui/click.ogg');
  }

  static Future<void> playTap() async {
    if (!enabled) return;
    await playSfx('audio/ui/tap.ogg');
  }

  static Future<void> playHover() async {
    if (!enabled) return;
    await playSfx('audio/ui/hover.ogg', volume: 0.5);
  }

  static Future<void> playSwitch() async {
    if (!enabled) return;
    await playSfx('audio/ui/switch.ogg');
  }

  static Future<void> playSuccess() async {
    if (!enabled) return;
    await playSfx('audio/ui/success.ogg');
  }

  static Future<void> playError() async {
    if (!enabled) return;
    await playSfx('audio/ui/error.ogg');
  }

  static Future<void> playNotification() async {
    if (!enabled) return;
    await playSfx('audio/ui/notification.ogg');
  }

  // ===== МУЗЫКА =====

  /// Играть музыку, но не перезапускать если этот же трек играет
  static Future<void> playMusic(String path, {double volume = 1.0}) async {
    if (!enabled) return;
    if (!_isInitialized) await init();

    if (_currentMusic == path) {
      await _applyVolumes();
      return;
    }

    await _playMusicInternal(path, volume: volume);
  }

  /// Играть музыку — принудительно, даже если уже играет этот же трек
  /// Полезно при возврате в меню из другого экрана
  static Future<void> forcePlayMusic(String path, {double volume = 1.0}) async {
    if (!enabled) return;
    if (!_isInitialized) await init();

    // Если играет тот же трек — не перезапускаем (звук не должен дёргаться)
    // Но громкость обновляем
    if (_currentMusic == path) {
      await _applyVolumes();
      return;
    }

    await _playMusicInternal(path, volume: volume);
  }

  static Future<void> _playMusicInternal(String path, {double volume = 1.0}) async {
    if (!enabled) return;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setVolume(
        _effectiveVolume(_musicVolume * _masterVolume * volume),
      );
      await _musicPlayer.play(AssetSource(path));
      _currentMusic = path;
    } catch (e) {
      debugPrint('❌ Ошибка воспроизведения музыки: $path — $e');
    }
  }

  static Future<void> stopMusic() async {
    if (!enabled) return;
    await _musicPlayer.stop();
    _currentMusic = null;
  }

  // ===== АТМОСФЕРА =====

  static Future<void> playAmbience(String path, {double volume = 1.0}) async {
    if (!enabled) return;
    if (!_isInitialized) await init();

    if (_currentAmbience == path) {
      await _applyVolumes();
      return;
    }

    try {
      await _ambiencePlayer.stop();
      await _ambiencePlayer.setVolume(
        _effectiveVolume(_sfxVolume * _masterVolume * 0.6 * volume),
      );
      await _ambiencePlayer.play(AssetSource(path));
      _currentAmbience = path;
    } catch (e) {
      debugPrint('❌ Ошибка воспроизведения атмосферы: $path — $e');
    }
  }

  static Future<void> stopAmbience() async {
    if (!enabled) return;
    await _ambiencePlayer.stop();
    _currentAmbience = null;
  }

  static String? ambienceForLocation({
    required String locationId,
    required String type,
    required String region,
    required int dangerLevel,
  }) {
    // Чистая функция — не трогает плагины. Не требует проверки enabled.
    switch (locationId) {
      case 'street_south':
        return 'audio/ambience/street_south.ogg';
      case 'street_center':
        return 'audio/ambience/street_center.ogg';
      case 'supermarket':
      case 'supermarket_basement':
      case 'warehouse':
      case 'rooftop_warehouse':
        return 'audio/ambience/supermarket.ogg';
      case 'hospital':
      case 'hospital_morgue':
        return 'audio/ambience/hospital.ogg';
      case 'forest_hut':
      case 'forest_path':
      case 'forest_cache':
        return 'audio/ambience/forest.ogg';
      case 'tunnel_entrance':
      case 'tunnel_dead_end':
        return 'audio/ambience/tunnel.ogg';
      case 'home_boris':
        return 'audio/ambience/safe_house.ogg';
    }

    switch (type) {
      case 'safe_house':
        return 'audio/ambience/safe_house.ogg';
      case 'forest':
        return 'audio/ambience/forest.ogg';
      case 'tunnel':
        return 'audio/ambience/tunnel.ogg';
      case 'medical':
        return 'audio/ambience/hospital.ogg';
      case 'street':
        return dangerLevel >= 6
            ? 'audio/ambience/street_center.ogg'
            : 'audio/ambience/street_south.ogg';
    }

    switch (region) {
      case 'forest':
        return 'audio/ambience/forest.ogg';
      case 'underground':
        return 'audio/ambience/tunnel.ogg';
      case 'city_center':
        return 'audio/ambience/street_center.ogg';
      case 'city_south':
        return 'audio/ambience/street_south.ogg';
    }

    return null;
  }

  // ===== УПРАВЛЕНИЕ ГРОМКОСТЬЮ =====

  static Future<void> setMasterVolume(double value) async {
    _masterVolume = value.clamp(0.0, 1.0);
    if (!enabled) return;
    await _applyVolumes();
    await _saveSettings();
  }

  static Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0.0, 1.0);
    if (!enabled) return;
    await _applyVolumes();
    await _saveSettings();
  }

  static Future<void> setSfxVolume(double value) async {
    _sfxVolume = value.clamp(0.0, 1.0);
    if (!enabled) return;
    await _applyVolumes();
    await _saveSettings();
  }

  static Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (!enabled) return;
    await _applyVolumes();
    await _saveSettings();
  }

  static Future<void> toggleMute() async {
    await setMuted(!_isMuted);
  }

  static Future<void> resetToDefaults() async {
    _masterVolume = AudioSettings.defaultMaster;
    _musicVolume = AudioSettings.defaultMusic;
    _sfxVolume = AudioSettings.defaultSfx;
    _isMuted = AudioSettings.defaultMuted;
    if (!enabled) return;
    await _applyVolumes();
    await _saveSettings();
  }

  static Future<void> _applyVolumes() async {
    if (!enabled) return;
    await _musicPlayer.setVolume(
      _effectiveVolume(_musicVolume * _masterVolume),
    );
    await _ambiencePlayer.setVolume(
      _effectiveVolume(_sfxVolume * _masterVolume * 0.6),
    );
  }

  static Future<void> _saveSettings() async {
    if (!enabled) return;
    await AudioSettings.save(AudioSettingsData(
      masterVolume: _masterVolume,
      musicVolume: _musicVolume,
      sfxVolume: _sfxVolume,
      muted: _isMuted,
    ));
  }

  // ===== ОСТАНОВКА =====

  static Future<void> stopAll() async {
    if (!enabled) return;
    await _musicPlayer.stop();
    await _ambiencePlayer.stop();
    for (final player in _sfxPool) {
      await player.stop();
    }
    _currentMusic = null;
    _currentAmbience = null;
  }
}
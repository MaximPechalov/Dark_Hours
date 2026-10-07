import 'package:flutter/material.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _masterVolume = AudioService.masterVolume;
  double _musicVolume = AudioService.musicVolume;
  double _sfxVolume = AudioService.sfxVolume;
  bool _muted = AudioService.isMuted;

  @override
  void initState() {
    super.initState();
    // Настройки загружены при инициализации AudioService
    _masterVolume = AudioService.masterVolume;
    _musicVolume = AudioService.musicVolume;
    _sfxVolume = AudioService.sfxVolume;
    _muted = AudioService.isMuted;
  }

  Future<void> _onMasterChanged(double value) async {
    setState(() => _masterVolume = value);
    await AudioService.setMasterVolume(value);
  }

  Future<void> _onMusicChanged(double value) async {
    setState(() => _musicVolume = value);
    await AudioService.setMusicVolume(value);
  }

  Future<void> _onSfxChanged(double value) async {
    setState(() => _sfxVolume = value);
    await AudioService.setSfxVolume(value);
  }

  Future<void> _toggleMute() async {
    AudioService.playTap();
    setState(() => _muted = !_muted);
    await AudioService.setMuted(_muted);
  }

  Future<void> _resetToDefaults() async {
    AudioService.playClick();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        title: const Text(
          'Сбросить настройки?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все настройки звука вернутся к значениям по умолчанию.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context, false);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context, true);
            },
            child: const Text(
              'Сбросить',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AudioService.resetToDefaults();

    if (!mounted) return;
    setState(() {
      _masterVolume = AudioService.masterVolume;
      _musicVolume = AudioService.musicVolume;
      _sfxVolume = AudioService.sfxVolume;
      _muted = AudioService.isMuted;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сброшены'),
          duration: Duration(seconds: 2),
          backgroundColor: Color.fromARGB(255, 200, 180, 100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.playClick();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'НАСТРОЙКИ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== СЕКЦИЯ: ЗВУК =====
            _sectionTitle('🔊 ЗВУК'),
            const SizedBox(height: 16),

            // Mute toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 20, 20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _muted
                      ? Colors.red.withValues(alpha: 0.5)
                      : const Color.fromARGB(255, 200, 180, 100)
                          .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    color: _muted
                        ? Colors.red
                        : const Color.fromARGB(255, 200, 180, 100),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _muted ? 'Звук выключен' : 'Звук включён',
                          style: TextStyle(
                            color: _muted ? Colors.red : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _muted
                              ? 'Нажми, чтобы включить'
                              : 'Нажми, чтобы выключить всё',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !_muted,
                    onChanged: (_) => _toggleMute(),
                    activeThumbColor: const Color.fromARGB(255, 200, 180, 100),
                    inactiveThumbColor: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== СЛАЙДЕРЫ =====
            _volumeSlider(
              icon: '🎚️',
              label: 'ОБЩАЯ ГРОМКОСТЬ',
              value: _masterVolume,
              onChanged: _onMasterChanged,
              enabled: !_muted,
            ),

            const SizedBox(height: 20),

            _volumeSlider(
              icon: '🎵',
              label: 'МУЗЫКА',
              value: _musicVolume,
              onChanged: _onMusicChanged,
              enabled: !_muted,
            ),

            const SizedBox(height: 20),

            _volumeSlider(
              icon: '🔔',
              label: 'ЭФФЕКТЫ',
              value: _sfxVolume,
              onChanged: _onSfxChanged,
              enabled: !_muted,
            ),

            const SizedBox(height: 32),

            // ===== КНОПКА СБРОСА =====
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text(
                  'СБРОСИТЬ НАСТРОЙКИ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[300],
                  side: BorderSide(
                    color: Colors.orange[300]!.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ===== ИНФО =====
            Center(
              child: Column(
                children: [
                  Text(
                    'Настройки сохраняются автоматически',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Тёмные часы · v 0.6.0',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color.fromARGB(255, 200, 180, 100),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 3.0,
      ),
    );
  }

  Widget _volumeSlider({
    required String icon,
    required String label,
    required double value,
    required Function(double) onChanged,
    bool enabled = true,
  }) {
    final effectiveValue = enabled ? value : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок + значение
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? const Color.fromARGB(255, 200, 180, 100)
                        .withValues(alpha: 0.15)
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: enabled
                      ? const Color.fromARGB(255, 200, 180, 100)
                          .withValues(alpha: 0.4)
                      : Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: enabled
                      ? const Color.fromARGB(255, 200, 180, 100)
                      : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Слайдер
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: enabled
                ? const Color.fromARGB(255, 200, 180, 100)
                : Colors.grey[700],
            inactiveTrackColor: Colors.grey[850],
            thumbColor: enabled
                ? const Color.fromARGB(255, 200, 180, 100)
                : Colors.grey[600],
            overlayColor: const Color.fromARGB(255, 200, 180, 100)
                .withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: effectiveValue.clamp(0.0, 1.0),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
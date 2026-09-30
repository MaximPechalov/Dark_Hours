import 'package:flutter/material.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/screens/main/start_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);

    // Первый клик — разблокирует аудио в браузере
    // и запускает menu_theme
    await AudioService.playMusic('audio/music/menu_theme.mp3');

    if (!mounted) return;

    // Небольшая задержка, чтобы звук успел начаться
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const StartScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _continue,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 5, 5, 5),
        body: SafeArea(
          child: Stack(
            children: [
              // ===== ФОН: лёгкий градиент =====
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Color.fromARGB(255, 25, 22, 15),
                      Color.fromARGB(255, 5, 5, 5),
                    ],
                  ),
                ),
              ),

              // ===== ЦЕНТР: лого =====
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Иконка
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 200, 180, 100)
                                  .withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.battery_unknown_outlined,
                            size: 80,
                            color: Color.fromARGB(255, 200, 180, 100),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Название
                        const Text(
                          'ТЁМНЫЕ ЧАСЫ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 200, 180, 100),
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Подзаголовок
                        Text(
                          'ВЫЖИВИ В БЛЕКАУТ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            letterSpacing: 6.0,
                          ),
                        ),
                        const SizedBox(height: 60),

                        // Подсказка «Тап»
                        AnimatedOpacity(
                          opacity: _isContinuing ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: _buildTapHint(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== СНИЗУ: версия =====
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'v 0.6.0',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return _PulsingText(
      text: 'НАЖМИ, ЧТОБЫ НАЧАТЬ',
      style: TextStyle(
        color: const Color.fromARGB(255, 200, 180, 100).withOpacity(0.7),
        fontSize: 13,
        letterSpacing: 3.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Пульсирующий текст — плавно меняет прозрачность
class _PulsingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _PulsingText({
    required this.text,
    required this.style,
  });

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementPopup extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onClose;

  const AchievementPopup({
    super.key,
    required this.achievement,
    this.onClose,
  });

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.pop(context);
        widget.onClose?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacityAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.achievement.categoryColor.withOpacity(0.15),
                    const Color.fromARGB(255, 20, 20, 20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.achievement.categoryColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.achievement.categoryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок
                  Text(
                    '🏆 ДОСТИЖЕНИЕ',
                    style: TextStyle(
                      color: widget.achievement.categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Иконка
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.achievement.categoryColor.withOpacity(0.15),
                      border: Border.all(
                        color: widget.achievement.categoryColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.achievement.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Название
                  Text(
                    widget.achievement.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Описание
                  Text(
                    widget.achievement.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Очки
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.achievement.categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${widget.achievement.points} очков',
                      style: TextStyle(
                        color: widget.achievement.categoryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Кнопка
                  Text(
                    'Нажми, чтобы закрыть',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
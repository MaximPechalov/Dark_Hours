import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/map_position.dart';

/// Маркер игрока — пульсирующий золотой кружок.
///
/// При анимации может принимать `rotation` — маркер
/// поворачивается в сторону движения.
class MapPlayerMarker extends StatefulWidget {
  final double size;

  /// Угол поворота в радианах (0 = вправо).
  final double rotation;

  const MapPlayerMarker({
    super.key,
    this.size = 24.0,
    this.rotation = 0.0,
  });

  @override
  State<MapPlayerMarker> createState() => _MapPlayerMarkerState();
}

class _MapPlayerMarkerState extends State<MapPlayerMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + _controller.value * 0.25;
        final glowOpacity = 0.6 + _controller.value * 0.4;

        return Transform.rotate(
          angle: widget.rotation,
          child: SizedBox(
            width: widget.size * 2.5,
            height: widget.size * 2.5,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Внешнее свечение (пульсирует)
                  Container(
                    width: widget.size * 2.0 * scale,
                    height: widget.size * 2.0 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC8B464)
                              .withValues(alpha: glowOpacity * 0.35),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  // Золотое кольцо
                  Container(
                    width: widget.size * 1.7,
                    height: widget.size * 1.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC8B464).withValues(
                          alpha: 0.5,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Основной кружок
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFE8D480),
                          Color(0xFFC8B464),
                        ],
                      ),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC8B464)
                              .withValues(alpha: glowOpacity),
                          blurRadius: 14,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Хелпер: позиция в пикселях.
Offset mapPositionToPixel(MapPosition pos, Size size) {
  return Offset(pos.x * size.width, pos.y * size.height);
}
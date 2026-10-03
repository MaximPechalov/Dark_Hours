import 'dart:math' as math;

/// Позиция локации на карте.
///
/// Координаты **логические** — в диапазоне 0.0..1.0.
/// Рендер умножает их на реальные размеры экрана.
///
/// (0, 0) — верхний левый угол.
/// (1, 1) — нижний правый угол.
/// (0.5, 0.5) — центр.
class MapPosition {
  final double x;
  final double y;

  const MapPosition({required this.x, required this.y});

  /// Парсинг из JSON: `{ "x": 0.15, "y": 0.6 }`
  factory MapPosition.fromJson(Map<String, dynamic> json) {
    return MapPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }

  /// Линейная интерполяция между двумя позициями.
  ///
  /// `t = 0.0` — эта позиция, `t = 1.0` — другая.
  MapPosition lerp(MapPosition other, double t) {
    return MapPosition(
      x: x + (other.x - x) * t,
      y: y + (other.y - y) * t,
    );
  }

  /// Расстояние до другой позиции (евклидово, в логических координатах).
  double distanceTo(MapPosition other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() =>
      'MapPosition(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
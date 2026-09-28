import 'condition.dart';

class ActiveCondition {
  final Condition condition;
  int daysRemaining;

  ActiveCondition({
    required this.condition,
    required this.daysRemaining,
  });

  /// Прогресс лечения (0.0 - 1.0)
  double get progress {
    if (condition.durationDays == 0) return 1.0;
    final elapsed = condition.durationDays - daysRemaining;
    return (elapsed / condition.durationDays).clamp(0.0, 1.0);
  }
}
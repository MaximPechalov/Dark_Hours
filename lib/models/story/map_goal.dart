/// Цель карты — что игрок должен сделать между двумя актами.
///
/// Типы:
/// - `reach_location` — дойти до локации.
/// - `find_item` — найти предмет в любой локации.
/// - `survive_night` — переждать ночь (лечь спать).
/// - `custom_flag` — установить произвольный флаг.
class MapGoal {
  final String type;
  final String? target;
  final String? hint;
  final String? onCompleteMessage;
  final int? timeLimitMinutes;
  final String? onTimeoutFlag;
  final String? onTimeoutMessage;

  const MapGoal({
    required this.type,
    this.target,
    this.hint,
    this.onCompleteMessage,
    this.timeLimitMinutes,
    this.onTimeoutFlag,
    this.onTimeoutMessage,
  });

  factory MapGoal.fromJson(Map<String, dynamic> json) {
    final onComplete = json['on_complete'] as Map<String, dynamic>?;
    final onTimeout = json['on_timeout'] as Map<String, dynamic>?;

    return MapGoal(
      type: json['type'] as String,
      target: json['target'] as String?,
      hint: json['hint'] as String?,
      onCompleteMessage: onComplete?['message'] as String?,
      timeLimitMinutes: json['time_limit_minutes'] as int?,
      onTimeoutFlag: onTimeout?['flag_set'] as String?,
      onTimeoutMessage: onTimeout?['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'target': target,
      'hint': hint,
      'on_complete_message': onCompleteMessage,
      'time_limit_minutes': timeLimitMinutes,
      'on_timeout_flag': onTimeoutFlag,
      'on_timeout_message': onTimeoutMessage,
    };
  }

  bool get hasTimeLimit => timeLimitMinutes != null && timeLimitMinutes! > 0;
}
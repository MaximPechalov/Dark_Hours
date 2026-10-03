/// Соединение между двумя локациями.
///
/// Заменяет старый `List<String> connections`.
class Connection {
  final String targetId;
  final int minutes;

  const Connection({
    required this.targetId,
    required this.minutes,
  });

  /// Парсинг из JSON.
  ///
  /// Поддерживает три формата:
  /// 1. `{ "id": "street_south", "minutes": 10 }` — полный объект.
  /// 2. `"street_south"` — просто строка (старый формат).
  /// 3. `{ "id": "street_south" }` — объект без minutes.
  factory Connection.fromJson(dynamic json) {
    if (json is String) {
      return Connection(targetId: json, minutes: 20);
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return Connection(
        targetId: map['id'] as String,
        minutes: (map['minutes'] as num?)?.toInt() ?? 20,
      );
    }

    throw ArgumentError(
      'Connection.fromJson: ожидается String или Map, получено: ${json.runtimeType}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': targetId,
      'minutes': minutes,
    };
  }

  /// Форматированное время — «15 мин», «1ч 30м».
  String get formattedTime {
    if (minutes < 60) return '$minutes мин';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }

  @override
  String toString() => 'Connection($targetId, $minutes мин)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          other.targetId == targetId &&
          other.minutes == minutes;

  @override
  int get hashCode => Object.hash(targetId, minutes);
}
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/connection.dart';

class WorldMap {
  final List<Location> locations;
  String currentLocationId;
  final Set<String> visitedLocations;

  WorldMap({
    required this.locations,
    required this.currentLocationId,
    Set<String>? visitedLocations,
  }) : visitedLocations = visitedLocations ?? {};

  Location get current {
    return locations.firstWhere((l) => l.id == currentLocationId);
  }

  Location? getById(String id) {
    try {
      return locations.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Локации, доступные для перехода из текущей.
  ///
  /// Теперь работает через `connectionIds`, потому что
  /// `connections` — это `List<Connection>`.
  List<Location> get availableConnections {
    return current.connectionIds
        .map((id) => getById(id))
        .whereType<Location>()
        .toList();
  }

  /// Получить Connection из текущей локации в указанную.
  Connection? getConnection(String targetId) {
    return current.connections.cast<Connection?>().firstWhere(
          (c) => c?.targetId == targetId,
          orElse: () => null,
        );
  }

  /// Получить время перехода между двумя локациями.
  ///
  /// Если локации не соседние — возвращает null.
  int? getTravelMinutes(String fromId, String toId) {
    final from = getById(fromId);
    if (from == null) return null;
    return from.connectionMinutesTo(toId);
  }

  /// Перейти в локацию (без валидации).
  void moveTo(String locationId) {
    currentLocationId = locationId;
    visitedLocations.add(locationId);
  }

  /// Случайный лут из пула текущей локации.
  String? rollLoot() {
    if (current.lootPool.isEmpty) return null;
    return current.lootPool[
        DateTime.now().millisecond % current.lootPool.length];
  }

  /// Случайный враг из текущей локации.
  String? rollEnemy() {
    if (current.enemies.isEmpty) return null;
    return current.enemies[
        DateTime.now().millisecond % current.enemies.length];
  }
}
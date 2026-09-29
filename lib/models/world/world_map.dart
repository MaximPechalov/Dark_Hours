import 'package:dark_hours/models/world/location.dart';

class WorldMap {
  final List<Location> locations;
  String currentLocationId; // ← убрали final
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

  List<Location> get availableConnections {
    return current.connections
        .map((id) => getById(id))
        .whereType<Location>()
        .toList();
  }

  void moveTo(String locationId) {
    currentLocationId = locationId;
    visitedLocations.add(locationId);
  }

  /// Поиск лута в локации — возвращает случайный предмет из пула
  String? rollLoot() {
    if (current.lootPool.isEmpty) return null;
    return current.lootPool[
        DateTime.now().millisecond % current.lootPool.length];
  }

  /// Случайный враг из локации
  String? rollEnemy() {
    if (current.enemies.isEmpty) return null;
    return current.enemies[
        DateTime.now().millisecond % current.enemies.length];
  }
}
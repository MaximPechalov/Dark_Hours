import 'package:dark_hours/models/world/search_event.dart';

class SearchEventLoader {
  static List<SearchEvent> _commonEvents = [];
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;
    _commonEvents = await SearchEvent.loadAll();
    _loaded = true;
  }

  /// Все общие события
  static List<SearchEvent> get commonEvents => _commonEvents;

  /// Собрать полный пул событий для локации:
  /// общие + уникальные события локации
  static List<SearchEvent> getPoolFor({
    required List<SearchEvent> locationEvents,
  }) {
    return [..._commonEvents, ...locationEvents];
  }

  /// Карта скрытых локаций: { unlockedBy: hiddenLocationId }
  /// Например: { "supermarket": "supermarket_basement" }
  static Map<String, String> buildHiddenMap(List<dynamic> allLocations) {
    final map = <String, String>{};
    for (final loc in allLocations) {
      if (loc.hidden == true && loc.unlockedBy != null) {
        map[loc.unlockedBy] = loc.id;
      }
    }
    return map;
  }
}
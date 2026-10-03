import 'package:dark_hours/models/world/connection.dart';

/// Хелпер для тестов: быстрое создание Connection.
Connection conn(String targetId, [int minutes = 10]) {
  return Connection(targetId: targetId, minutes: minutes);
}

/// Хелпер для тестов: список Connection.
List<Connection> conns(List<String> ids, {int minutes = 10}) {
  return ids.map((id) => Connection(targetId: id, minutes: minutes)).toList();
}
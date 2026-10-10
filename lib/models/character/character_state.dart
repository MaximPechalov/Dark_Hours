/// Состояние персонажа для отображения портрета.
///
/// Соответствует именам файлов:
/// `assets/images/characters/{id}_{state}.png`
enum CharacterState {
  /// Нормальное состояние — `normal`.
  normal,

  /// Устал — `tired`.
  tired,

  /// Голоден — `hungry`.
  hungry,

  /// Ранен — `wounded`.
  wounded,

  /// При смерти — `critical`.
  critical;

  /// Имя файла без расширения для этого состояния.
  ///
  /// Например, для `CharacterState.critical` вернёт `"critical"`.
  String get fileName => name;
}
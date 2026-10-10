import 'package:flutter/material.dart';

import 'package:dark_hours/models/character/character.dart';
import 'package:dark_hours/models/character/character_state.dart';

/// Портрет персонажа с учётом состояния.
///
/// **Логика:**
/// 1. Пытается загрузить `assets/images/characters/{id}_{state}.png`.
/// 2. Если файла нет — fallback на `{id}_normal.png`.
/// 3. Если и его нет — fallback на букву в кружке.
///
/// **Фокус картинки:**
/// У каждого персонажа портрет сгенерирован по-своему — у кого-то
/// лицо выше, у кого-то ниже. Поэтому для каждого свой
/// `focusAlignment` в карте [_focusByCharacter].
///
/// Параметр `focusAlignment` позволяет **переопределить** значение
/// (например, для конкретного экрана).
class CharacterPortrait extends StatelessWidget {
  final String characterId;
  final CharacterState state;
  final double size;
  final BoxFit fit;

  /// Куда «смотрит» картинка при `BoxFit.cover`.
  ///
  /// Если `null` — берётся из [_focusByCharacter] по `characterId`.
  /// Если задан — используется как есть (переопределяет карту).
  final Alignment? focusAlignment;

  const CharacterPortrait({
    super.key,
    required this.characterId,
    this.state = CharacterState.normal,
    this.size = 64,
    this.fit = BoxFit.cover,
    this.focusAlignment,
  });

  /// Индивидуальный фокус для каждого персонажа.
  ///
  /// Чем **более отрицательное** значение по Y — тем выше фокус.
  ///
  /// - `-0.4` — верхняя треть
  /// - `-0.5` — выше
  /// - `-0.6` — почти голова
  /// - `-0.7` — голова
  static const Map<String, Alignment> _focusByCharacter = {
    'boris': Alignment(0.0, -0.7),   // подняли
    'alina': Alignment(0.0, -0.6),   // подняли
    'ivan': Alignment(0.0, -0.6),    // подняли
    'andrey': Alignment(0.0, -0.4),  // оставили
    'darya': Alignment(0.0, -0.4),   // оставили
  };

  /// Дефолт, если персонажа нет в карте.
  static const Alignment _defaultFocus = Alignment(0.0, -0.4);

  Alignment get _effectiveFocus {
    if (focusAlignment != null) return focusAlignment!;
    return _focusByCharacter[characterId] ?? _defaultFocus;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: _buildPortrait(),
      ),
    );
  }

  Widget _buildPortrait() {
    final statePath =
        'assets/images/characters/${characterId}_${state.fileName}.png';
    final normalPath = 'assets/images/characters/${characterId}_normal.png';
    final focus = _effectiveFocus;

    return Image.asset(
      statePath,
      width: size,
      height: size,
      fit: fit,
      alignment: focus,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        // Первый fallback — normal.png.
        return Image.asset(
          normalPath,
          width: size,
          height: size,
          fit: fit,
          alignment: focus,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error2, stack2) {
            // Второй fallback — буква.
            return _buildLetterFallback();
          },
        );
      },
    );
  }

  Widget _buildLetterFallback() {
    final character = Character.getById(characterId);
    final letter = character?.name.isNotEmpty == true
        ? character!.name[0]
        : '?';

    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: const Color(0xFFC8B464),
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
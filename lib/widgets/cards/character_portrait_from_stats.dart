import 'package:flutter/material.dart';

import 'package:dark_hours/models/character/character_state_calculator.dart';
import 'package:dark_hours/widgets/cards/character_portrait.dart';

/// Портрет персонажа с автоматическим определением состояния
/// по текущим статам.
///
/// Внутри использует [CharacterStateCalculator.compute].
///
/// **Использование:**
/// ```dart
/// CharacterPortraitFromStats(
///   characterId: 'boris',
///   health: 30,   // → wounded
///   hunger: 50,
///   fatigue: 20,
///   size: 48,
/// )
/// ```
class CharacterPortraitFromStats extends StatelessWidget {
  final String characterId;
  final int health;
  final int hunger;
  final int fatigue;
  final double size;
  final BoxFit fit;

  const CharacterPortraitFromStats({
    super.key,
    required this.characterId,
    required this.health,
    required this.hunger,
    required this.fatigue,
    this.size = 48,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final state = CharacterStateCalculator.compute(
      health: health,
      hunger: hunger,
      fatigue: fatigue,
    );

    return CharacterPortrait(
      characterId: characterId,
      state: state,
      size: size,
      fit: fit,
    );
  }
}
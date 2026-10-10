// lib/screens/gameplay/combat_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/models/combat/combat.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/constants/game_constants.dart';
import 'package:dark_hours/widgets/cards/character_portrait_from_stats.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';
import 'package:dark_hours/widgets/effects/shake_widget.dart';

class CombatScreen extends StatefulWidget {
  final Combatant player;
  final Combatant enemy;

  /// ID персонажа игрока — для отображения портрета.
  ///
  /// Если `null` — портрет не показывается (fallback на эмодзи).
  final String? characterId;

  /// Голод игрока — для определения состояния портрета.
  final int playerHunger;

  /// Усталость игрока — для определения состояния портрета.
  final int playerFatigue;

  /// Хитрость игрока — влияет на уклонение и побег.
  ///
  /// Значения 0-10. Базовая точка — 5.
  /// При cunning 5 → без изменений.
  /// При cunning 8 → +9% уклонения, +12% побега.
  final int playerCunning;

  /// Выносливость игрока — влияет на побег.
  ///
  /// Значения 0-10. Базовая точка — 5.
  /// При endurance 8 → +12% побега.
  final int playerEndurance;

  const CombatScreen({
    super.key,
    required this.player,
    required this.enemy,
    this.characterId,
    this.playerHunger = 100,
    this.playerFatigue = 0,
    this.playerCunning = GameConstants.defaultCunning,
    this.playerEndurance = GameConstants.defaultEndurance,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  final List<String> _log = [];
  bool _isPlayerTurn = true;
  bool _combatEnded = false;
  bool _isProcessing = false;
  bool _enemyShaking = false;
  bool _playerShaking = false;
  final Random _rng = Random();

  // Что случилось с игроком
  bool playerWasBleeding = false;
  bool playerWasPoisoned = false;
  bool playerWasInfected = false;

  // Результат боя
  String? battleResult;

  @override
  void initState() {
    super.initState();
    _playCombatMusic();
    _addLog('⚔️ Бой начался: ${widget.enemy.name}');
    _addLog(
      '⚔️ Ты: ${widget.player.damage} урона (${_damageTypeName(widget.player.damageType)})',
    );
    if (widget.playerCunning > GameConstants.baseStat) {
      _addLog(
        '💨 Уклонение: +${(GameConstants.cunningDodgeBonus(widget.playerCunning) * 100).round()}%',
      );
    }
  }

  Future<void> _playCombatMusic() async {
    await AudioService.playMusic('audio/music/combat_theme.ogg');
  }

  @override
  void dispose() {
    // Возвращаем музыку сюжета — но если игрок из MapScreen,
    // MapScreen перезапишет её своим вызовом playMusic в initState
    AudioService.playMusic('audio/music/story_theme.ogg');
    super.dispose();
  }

  String _damageTypeName(String type) {
    switch (type) {
      case 'cutting':
        return 'режущий';
      case 'blunt':
        return 'дробящий';
      case 'piercing':
        return 'колющий';
      case 'firearm':
        return 'огнестрел';
      default:
        return type;
    }
  }

  void _addLog(String message) {
    setState(() {
      _log.insert(0, message);
      if (_log.length > 25) _log.removeLast();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // УКЛОНЕНИЕ (от cunning)
  // ═══════════════════════════════════════════════════════════

  /// Проверить, уклонился ли игрок от атаки врага.
  ///
  /// Базируется на cunning: при cunning 8 → 9% шанс уклонения.
  /// Клампится через `GameConstants.cunningDodgeBonus`.
  bool _rollPlayerDodge() {
    final dodgeChance = GameConstants.cunningDodgeBonus(widget.playerCunning);
    if (dodgeChance <= 0) return false;
    return _rng.nextDouble() < dodgeChance;
  }

  // ═══════════════════════════════════════════════════════════
  // ИГРОК
  // ═══════════════════════════════════════════════════════════

  void _playerAttack() {
    if (_combatEnded || !_isPlayerTurn || _isProcessing) return;
    if (widget.player.isStunned) {
      _addLog('⚠️ Ты оглушён и не можешь двигаться!');
      _skipPlayerTurn();
      return;
    }

    setState(() => _isProcessing = true);

    final isCrit = widget.player.rollCrit();
    final dmg = widget.player.calculateDamage(widget.enemy, isCrit: isCrit);
    widget.enemy.takeDamage(dmg);

    final critText = isCrit ? ' 💥 КРИТ!' : '';
    _addLog('⚔️ Ты наносишь $dmg урона$critText');

    setState(() => _enemyShaking = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _enemyShaking = false);
    });

    FloatingEffectOverlay.show(
      context,
      isCrit ? 'КРИТ -$dmg' : '-$dmg',
      color: isCrit ? Colors.orange : Colors.red,
      icon: isCrit ? Icons.flash_on : Icons.bolt,
    );

    if (widget.enemy.isDead) {
      _endCombat('victory');
      return;
    }

    _isPlayerTurn = false;
    Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
  }

  /// Прицельный удар — 60% попасть, ×1.8 урон
  void _playerAim() {
    if (_combatEnded || !_isPlayerTurn || _isProcessing) return;
    if (widget.player.isStunned) {
      _addLog('⚠️ Ты оглушён и не можешь двигаться!');
      _skipPlayerTurn();
      return;
    }

    setState(() => _isProcessing = true);

    final hit = _rng.nextDouble() < 0.6;
    if (hit) {
      final dmg = (widget.player.calculateDamage(widget.enemy) * 1.8).round();
      widget.enemy.takeDamage(dmg);
      _addLog('🎯 Прицельный удар: $dmg урона!');

      setState(() => _enemyShaking = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _enemyShaking = false);
      });

      FloatingEffectOverlay.show(
        context,
        '🎯 -$dmg',
        color: Colors.orange,
        icon: Icons.gps_fixed,
      );
    } else {
      _addLog('❌ Прицельный удар промахнулся!');
      FloatingEffectOverlay.show(
        context,
        'ПРОМАХ',
        color: Colors.grey,
        icon: Icons.close,
      );
    }

    if (widget.enemy.isDead) {
      _endCombat('victory');
      return;
    }

    _isPlayerTurn = false;
    Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
  }

  /// Оглушающий удар — 70% урона, 40% шанс оглушить
  void _playerStun() {
    if (_combatEnded || !_isPlayerTurn || _isProcessing) return;
    if (widget.player.isStunned) {
      _addLog('⚠️ Ты оглушён и не можешь двигаться!');
      _skipPlayerTurn();
      return;
    }

    setState(() => _isProcessing = true);

    final dmg = (widget.player.calculateDamage(widget.enemy) * 0.7).round();
    widget.enemy.takeDamage(dmg);
    _addLog('🔨 Оглушающий удар: $dmg урона');

    FloatingEffectOverlay.show(
      context,
      '-$dmg',
      color: Colors.yellow[700]!,
      icon: Icons.flash_on,
    );

    // Шанс оглушить
    if (_rng.nextDouble() < 0.4) {
      widget.enemy.stunTurns = 1;
      _addLog('💫 ${widget.enemy.name} оглушён!');
      FloatingEffectOverlay.show(
        context,
        'ОГЛУШЁН!',
        color: Colors.yellow,
        icon: Icons.star,
      );
    }

    if (widget.enemy.isDead) {
      _endCombat('victory');
      return;
    }

    _isPlayerTurn = false;
    Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
  }

  void _playerDefend() {
    if (_combatEnded || !_isPlayerTurn || _isProcessing) return;
    if (widget.player.isStunned) {
      _addLog('⚠️ Ты оглушён!');
      _skipPlayerTurn();
      return;
    }

    setState(() => _isProcessing = true);

    final heal = (widget.player.maxHealth * 0.15).round();
    widget.player.heal(heal);
    _addLog('🛡️ Ты защищаешься и восстанавливаешь $heal HP');

    FloatingEffectOverlay.show(
      context,
      '+$heal HP',
      color: Colors.green,
      icon: Icons.favorite,
    );

    _isPlayerTurn = false;
    Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
  }

  /// Побег из боя.
  ///
  /// Шанс побега рассчитывается из 3 характеристик:
  /// - strength: базовый бонус (уже был)
  /// - cunning: хитрость помогает запутать следы
  /// - endurance: выносливость помогает дольше бежать
  ///
  /// Базовая формула:
  /// ```
  /// 0.5 + (strength - 5) * 0.05 + cunningFleeBonus + enduranceFleeBonus
  /// ```
  /// Клампится в [0.2, 0.9].
  void _playerFlee() {
    if (_combatEnded || _isProcessing) return;
    if (widget.player.isStunned) {
      _addLog('⚠️ Ты оглушён и не можешь бежать!');
      _skipPlayerTurn();
      return;
    }

    setState(() => _isProcessing = true);

    // База + бонус от силы (уже было) + бонусы от cunning и endurance
    final strengthBonus = (widget.player.strength - GameConstants.baseStat) * 0.05;
    final cunningBonus = GameConstants.cunningFleeBonus(widget.playerCunning);
    final enduranceBonus =
        GameConstants.enduranceFleeBonus(widget.playerEndurance);

    double fleeChance =
        0.5 + strengthBonus + cunningBonus + enduranceBonus;
    fleeChance = fleeChance.clamp(0.2, 0.9);

    if (_rng.nextDouble() < fleeChance) {
      _addLog(
        '🏃 Ты сбежал! (шанс ${(fleeChance * 100).round()}%)',
      );
      _endCombat('fled');
    } else {
      _addLog(
        '❌ Не удалось сбежать! (шанс ${(fleeChance * 100).round()}%)',
      );
      _isPlayerTurn = false;
      Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
    }
  }

  void _skipPlayerTurn() {
    setState(() {
      widget.player.decrementStun();
      _isPlayerTurn = false;
    });
    Future.delayed(const Duration(milliseconds: 800), _enemyTurn);
  }

  // ═══════════════════════════════════════════════════════════
  // ВРАГ
  // ═══════════════════════════════════════════════════════════

  void _enemyTurn() {
    if (_combatEnded || widget.enemy.isDead || !mounted) return;

    // Проверка оглушения врага
    if (widget.enemy.isStunned) {
      _addLog('💫 ${widget.enemy.name} пропускает ход (оглушён)');
      widget.enemy.decrementStun();
      setState(() {
        _isPlayerTurn = true;
        _isProcessing = false;
      });
      return;
    }

    // Тик статусов врага
    final enemyStatusDmg = widget.enemy.tickStatusEffects();
    if (enemyStatusDmg > 0) {
      _addLog('🩸 ${widget.enemy.name} теряет $enemyStatusDmg HP от статуса');
      if (widget.enemy.isDead) {
        _endCombat('victory');
        return;
      }
    }

    // ⚡ ПРОВЕРКА УКЛОНЕНИЯ ОТ CUNNING
    // Если игрок уклонился — враг атакует, но промахивается.
    // Способности врага всё ещё применяются (их нельзя «уклонить»
    // физически), но обычные атаки — можно.
    final enemyAbility = widget.enemy.rollAbility();
    final dodged = enemyAbility == null && _rollPlayerDodge();

    if (dodged) {
      _addLog('💨 Ты уклоняешься от атаки ${widget.enemy.name}!');
      FloatingEffectOverlay.show(
        context,
        'УКЛОНЕНИЕ!',
        color: Colors.cyan,
        icon: Icons.air,
      );
    } else if (enemyAbility != null) {
      // Способность врага (без уклонения — это спецатака)
      _applyEnemyAbility(enemyAbility);
    } else {
      // Обычная атака
      final dmg = widget.enemy.calculateDamage(widget.player);
      widget.player.takeDamage(dmg);
      _addLog('💥 ${widget.enemy.name} наносит $dmg урона');

      setState(() => _playerShaking = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _playerShaking = false);
      });

      FloatingEffectOverlay.show(
        context,
        '-$dmg HP',
        color: Colors.red[700]!,
        icon: Icons.warning,
      );
    }

    if (widget.player.isDead) {
      _endCombat('defeat');
      return;
    }

    // Тик статусов игрока
    final playerStatusDmg = widget.player.tickStatusEffects();
    if (playerStatusDmg > 0) {
      _addLog('🩸 Ты теряешь $playerStatusDmg HP от статуса');
      if (widget.player.isDead) {
        _endCombat('defeat');
        return;
      }
    }

    setState(() {
      _isPlayerTurn = true;
      _isProcessing = false;
    });
  }

  void _applyEnemyAbility(CombatAbility ability) {
    _addLog('⚡ ${widget.enemy.name} использует: ${ability.name}');

    switch (ability.effect) {
      case 'skip_turn':
        widget.player.stunTurns = 1;
        _addLog('💫 Ты оглушён!');
        FloatingEffectOverlay.show(
          context,
          'ОГЛУШЁН!',
          color: Colors.yellow,
          icon: Icons.star,
        );
        final dmg = (widget.enemy.calculateDamage(widget.player) * 0.5).round();
        widget.player.takeDamage(dmg);
        _addLog('💥 +$dmg урона');
        break;

      case 'poison':
        widget.player.poisonTurns = 3;
        playerWasPoisoned = true;
        _addLog('☠️ Ты отравлен! (3 хода)');
        FloatingEffectOverlay.show(
          context,
          'ОТРАВЛЕН!',
          color: Colors.green,
          icon: Icons.science,
        );
        break;

      case 'infection':
        widget.player.isInfected = true;
        playerWasInfected = true;
        _addLog('🦠 В рану попала инфекция!');
        FloatingEffectOverlay.show(
          context,
          'ИНФЕКЦИЯ!',
          color: Colors.purple,
          icon: Icons.coronavirus,
        );
        final dmg = widget.enemy.calculateDamage(widget.player);
        widget.player.takeDamage(dmg);
        break;

      case 'bleeding':
        widget.player.bleedTurns = 5;
        playerWasBleeding = true;
        _addLog('🩸 Ты истекаешь кровью! (5 ходов)');
        FloatingEffectOverlay.show(
          context,
          'КРОВОТЕЧЕНИЕ!',
          color: Colors.red,
          icon: Icons.water_drop,
        );
        break;
    }
  }

  void _endCombat(String result) {
    setState(() {
      _combatEnded = true;
      _isProcessing = true;
      battleResult = result;
    });

    if (result == 'victory') {
      AudioService.playSuccess();
      FloatingEffectOverlay.show(
        context,
        'ПОБЕДА!',
        color: Colors.green,
        icon: Icons.emoji_events,
      );
    } else if (result == 'defeat') {
      AudioService.playError();
      FloatingEffectOverlay.show(
        context,
        'ПОРАЖЕНИЕ',
        color: Colors.red,
        icon: Icons.dangerous,
      );
    } else {
      AudioService.playNotification();
      FloatingEffectOverlay.show(
        context,
        'ПОБЕГ',
        color: Colors.blue,
        icon: Icons.directions_run,
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, {
          'result': result,
          'playerHealth': widget.player.health,
          'wasBleeding': playerWasBleeding || widget.player.bleedTurns > 0,
          'wasPoisoned': playerWasPoisoned || widget.player.poisonTurns > 0,
          'wasInfected': playerWasInfected || widget.player.isInfected,
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'БОЙ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          ShakeWidget(
            shake: _enemyShaking,
            child: _buildCombatant(widget.enemy, isEnemy: true),
          ),

          const SizedBox(height: 16),

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _combatEnded
                    ? (widget.player.isDead
                        ? '💀 ТЫ ПРОИГРАЛ'
                        : (battleResult == 'fled'
                            ? '🏃 ТЫ СБЕЖАЛ'
                            : '🏆 ТЫ ПОБЕДИЛ'))
                    : 'VS',
                key: ValueKey(_combatEnded),
                style: TextStyle(
                  color: _combatEnded
                      ? (widget.player.isDead
                          ? Colors.red
                          : (battleResult == 'fled'
                              ? Colors.blue
                              : Colors.green))
                      : const Color.fromARGB(255, 200, 180, 100),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          ShakeWidget(
            shake: _playerShaking,
            child: _buildCombatant(widget.player),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 20, 20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromARGB(255, 200, 180, 100)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final isRecent = index == 0;
                  return AnimatedOpacity(
                    opacity:
                        isRecent ? 1.0 : (1.0 - index * 0.05).clamp(0.3, 1.0),
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        _log[index],
                        style: TextStyle(
                          color: isRecent ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight:
                              isRecent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (!_combatEnded && _isPlayerTurn && !_isProcessing)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _playerAttack();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '⚔️ АТАКА',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _playerStun();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '🔨 ОГЛУШИТЬ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _playerAim();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '🎯 ПРИЦЕЛ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _playerDefend();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '🛡️ ЗАЩИТА',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _playerFlee();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '🏃 ПОБЕГ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (_isProcessing && !_combatEnded)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '...',
                style: TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCombatant(Combatant c, {bool isEnemy = false}) {
    final hpPercent = c.health / c.maxHealth;
    final baseColor = isEnemy ? Colors.red : Colors.green;
    final isLow = hpPercent < 0.3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ⚡ Портрет для игрока, эмодзи для врага.
              if (!isEnemy && widget.characterId != null)
                CharacterPortraitFromStats(
                  characterId: widget.characterId!,
                  health: c.health,
                  hunger: widget.playerHunger,
                  fatigue: widget.playerFatigue,
                  size: 32,
                )
              else
                Text(
                  isEnemy ? '👹' : '🧑',
                  style: const TextStyle(fontSize: 20),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                '⚔️ ${c.damage}  🛡️ ${c.protection}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${c.health} / ${c.maxHealth}',
                style: TextStyle(
                  color: isLow ? Colors.red : baseColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: hpPercent.clamp(0, 1),
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[900],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLow ? Colors.red : baseColor,
                        ),
                        minHeight: 6,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (c.isStunned || c.isBleeding || c.isPoisoned) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (c.isStunned) _statusChip('💫 Оглушён', Colors.yellow),
                if (c.isBleeding)
                  _statusChip('🩸 Кровь (${c.bleedTurns})', Colors.red),
                if (c.isPoisoned)
                  _statusChip('☠️ Яд (${c.poisonTurns})', Colors.green),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
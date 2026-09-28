import 'package:flutter/material.dart';
import 'dart:math';
import '../models/combat.dart';
import '../widgets/floating_effect.dart';
import '../widgets/shake_widget.dart';

class CombatScreen extends StatefulWidget {
  final Combatant player;
  final Combatant enemy;

  const CombatScreen({
    super.key,
    required this.player,
    required this.enemy,
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

  void _addLog(String message) {
    setState(() {
      _log.insert(0, message);
      if (_log.length > 20) _log.removeLast();
    });
  }

  void _playerAttack() {
    if (_combatEnded || !_isPlayerTurn || _isProcessing) return;

    setState(() => _isProcessing = true);

    final dmg = widget.player.calculateDamage(widget.enemy);
    widget.enemy.takeDamage(dmg);
    _addLog('⚔️ Ты наносишь $dmg урона ${widget.enemy.name}');

    // Shake эффект для врага
    setState(() => _enemyShaking = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _enemyShaking = false);
    });

    // Всплывающий эффект
    FloatingEffectOverlay.show(
      context,
      '-$dmg',
      color: Colors.red,
      icon: Icons.flash_on,
    );

    if (widget.enemy.isDead) {
      _endCombat(true);
      return;
    }

    _isPlayerTurn = false;
    Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
  }

  void _playerDefend() {
    if (_combatEnded || !_isPlayerTurn || _isProcessing) return;

    setState(() => _isProcessing = true);

    final heal = (widget.player.maxHealth * 0.15).round();
    widget.player.health =
        (widget.player.health + heal).clamp(0, widget.player.maxHealth);
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

  void _playerFlee() {
    if (_combatEnded || _isProcessing) return;

    setState(() => _isProcessing = true);

    if (_rng.nextBool()) {
      _addLog('🏃 Ты сбежал!');
      setState(() => _combatEnded = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, 'fled');
      });
    } else {
      _addLog('❌ Не удалось сбежать!');
      _isPlayerTurn = false;
      Future.delayed(const Duration(milliseconds: 600), _enemyTurn);
    }
  }

  void _enemyTurn() {
    if (_combatEnded || widget.enemy.isDead || !mounted) return;

    final action = _rng.nextInt(10);
    if (action < 8) {
      final dmg = widget.enemy.calculateDamage(widget.player);
      widget.player.takeDamage(dmg);
      _addLog('💥 ${widget.enemy.name} наносит $dmg урона');

      // Shake для игрока
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
    } else {
      _addLog('🤐 ${widget.enemy.name} медлит...');
    }

    if (widget.player.isDead) {
      _endCombat(false);
      return;
    }

    setState(() {
      _isPlayerTurn = true;
      _isProcessing = false;
    });
  }

  void _endCombat(bool playerWon) {
    setState(() {
      _combatEnded = true;
      _isProcessing = true;
    });

    if (playerWon) {
      FloatingEffectOverlay.show(
        context,
        'ПОБЕДА!',
        color: Colors.green,
        icon: Icons.emoji_events,
      );
    } else {
      FloatingEffectOverlay.show(
        context,
        'ПОРАЖЕНИЕ',
        color: Colors.red,
        icon: Icons.dangerous,
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, playerWon ? 'victory' : 'defeat');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
          const SizedBox(height: 16),

          ShakeWidget(
            shake: _enemyShaking,
            child: _buildCombatant(widget.enemy, isEnemy: true),
          ),

          const SizedBox(height: 20),

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _combatEnded
                    ? (widget.player.isDead ? '💀 ТЫ ПРОИГРАЛ' : '🏆 ТЫ ПОБЕДИЛ')
                    : 'VS',
                key: ValueKey(_combatEnded),
                style: TextStyle(
                  color: _combatEnded
                      ? (widget.player.isDead ? Colors.red : Colors.green)
                      : const Color.fromARGB(255, 200, 180, 100),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          ShakeWidget(
            shake: _playerShaking,
            child: _buildCombatant(widget.player),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 20, 20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromARGB(255, 200, 180, 100)
                      .withOpacity(0.2),
                ),
              ),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final isRecent = index == 0;
                  return AnimatedOpacity(
                    opacity: isRecent ? 1.0 : (1.0 - index * 0.05).clamp(0.3, 1.0),
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
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

          const SizedBox(height: 16),

          if (!_combatEnded && _isPlayerTurn && !_isProcessing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playerAttack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '⚔️ АТАКА',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playerDefend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '🛡️ ЗАЩИТА',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playerFlee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '🏃 ПОБЕГ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
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
    final color = isEnemy ? Colors.red : Colors.green;
    final isLow = hpPercent < 0.3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEnemy ? '👹' : '🧑',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Text(
                c.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '⚔️ ${c.damage}  🛡️ ${c.protection}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${c.health} / ${c.maxHealth}',
                style: TextStyle(
                  color: isLow ? Colors.red : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: hpPercent.clamp(0, 1)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[900],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLow ? Colors.red : color,
                        ),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
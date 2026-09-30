import 'package:flutter/material.dart';
import 'package:dark_hours/models/progress/chapter_summary.dart';
import 'package:dark_hours/models/progress/player_stats.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class CreditsScreen extends StatefulWidget {
  final ChapterSummary summary;

  const CreditsScreen({
    super.key,
    required this.summary,
  });

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;
  PlayerStats? _stats;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _controller = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _controller.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _controller.value * maxScroll;
        _scrollController.jumpTo(currentScroll);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _showEndDialog();
      }
    });

    _loadStats();
    _controller.forward();
  }

  Future<void> _loadStats() async {
    final stats = await AchievementManager.loadStats();
    final points = await AchievementManager.getTotalPoints();
    if (mounted) {
      setState(() {
        _stats = stats;
        _totalPoints = points;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 15, 15, 15),
        title: const Text(
          'ГЛАВА ЗАВЕРШЕНА',
          style: TextStyle(
            color: Color.fromARGB(255, 200, 180, 100),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
        ),
        content: Text(
          'Продолжение — во второй главе.\n\n'
          'А пока — исследуй город, находи союзников, '
          'и готовься к долгой дороге на север.',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'В МЕНЮ',
              style: TextStyle(
                color: Color.fromARGB(255, 200, 180, 100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_controller.isAnimating) {
            _controller.stop();
          } else {
            _controller.forward();
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 800),
                  _buildCreditsContent(),
                  const SizedBox(height: 200),
                ],
              ),
            ),

            // Кнопка «Пропустить»
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: () {
                  AudioService.playClick();
                  _controller.stop();
                  _showEndDialog();
                },
                child: Text(
                  'ПРОПУСТИТЬ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ===== ТИТУЛ =====
          const Text(
            'ТЁМНЫЕ ЧАСЫ',
            style: TextStyle(
              color: Color.fromARGB(255, 200, 180, 100),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 8.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'ГЛАВА ${widget.summary.chapter} ЗАВЕРШЕНА',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              letterSpacing: 4.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),

          // ===== СТАТИСТИКА =====
          _buildSection('СТАТИСТИКА ПРОХОЖДЕНИЯ'),

          _buildStatRow(
            '👤 Персонаж',
            widget.summary.characterName,
          ),
          _buildStatRow(
            '📅 Дней прожито',
            '${widget.summary.daysSurvived}',
          ),
          _buildStatRow(
            '🛤️ Финальная сцена',
            widget.summary.finalTitle,
          ),
          const SizedBox(height: 30),

          _buildSection('ЧТО ТЫ СДЕЛАЛ'),

          if (widget.summary.hasCombat)
            _buildStatRow(
              '⚔️ Побед в бою',
              '${widget.summary.kills}',
            ),
          if (widget.summary.wasWounded)
            _buildStatRow(
              '💀 Поражений',
              '${widget.summary.defeats}',
            ),
          if (widget.summary.wasLucky)
            _buildStatRow(
              '🎁 Предметов найдено',
              '${widget.summary.itemsLooted}',
            ),
          if (widget.summary.wasCrafty)
            _buildStatRow(
              '🔨 Предметов создано',
              '${widget.summary.itemsCrafted}',
            ),
          if (widget.summary.wasSick)
            _buildStatRow(
              '🦠 Заражений',
              '${widget.summary.infections}',
            ),
          if (widget.summary.wasUnstable)
            _buildStatRow(
              '🧠 Дней в стрессе',
              '${widget.summary.sanityDaysLow}',
            ),

          const SizedBox(height: 80),

          // ===== БЛАГОДАРНОСТИ =====
          _buildSection('БЛАГОДАРНОСТИ'),

          _buildCreditLine('Идея и разработка', 'Maxim Pechalov'),
          _buildCreditLine('Сценарий', 'Dark Hours Team'),
          _buildCreditLine('Дизайн персонажей', 'Dark Hours Team'),
          _buildCreditLine('Тестирование', 'Первые игроки'),
          const SizedBox(height: 20),
          Text(
            'Особая благодарность всем,\nкто выжил в этом мире.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 80),

          // ===== ДОСТИЖЕНИЯ =====
          if (_stats != null && _stats!.unlockedAchievements.isNotEmpty) ...[
            _buildSection('ТВОИ ДОСТИЖЕНИЯ'),

            _buildStatRow(
              '🏆 Разблокировано',
              '${_stats!.unlockedAchievements.length} из 25',
            ),
            _buildStatRow(
              '📊 Всего очков',
              '$_totalPoints',
            ),
            const SizedBox(height: 80),
          ],

          // ===== АНОНС ГЛАВЫ 2 =====
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(255, 200, 180, 100)
                    .withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  '◉ ГЛАВА 2 ◉',
                  style: TextStyle(
                    color: Color.fromARGB(255, 200, 180, 100),
                    fontSize: 14,
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ПУТЬ НА СЕВЕР',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Город позади. Впереди — 200 километров\n'
                  'через пустоши и руины.\n\n'
                  'Три фракции борются за выживание.\n'
                  'У каждой — своя правда.\n\n'
                  'И только ты решишь,\n'
                  'кому доверять.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'ПРОДОЛЖЕНИЕ СЛЕДУЕТ...',
                  style: TextStyle(
                    color: Color.fromARGB(255, 200, 180, 100),
                    fontSize: 11,
                    letterSpacing: 3.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),

          // ===== КОНЕЦ =====
          const Text(
            'ТЁМНЫЕ ЧАСЫ',
            style: TextStyle(
              color: Color.fromARGB(255, 200, 180, 100),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 6.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v 0.6.0',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        '◆ $title ◆',
        style: const TextStyle(
          color: Color.fromARGB(255, 200, 180, 100),
          fontSize: 11,
          letterSpacing: 4.0,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditLine(String role, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
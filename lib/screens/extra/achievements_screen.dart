import 'package:flutter/material.dart';
import 'package:dark_hours/models/progress/achievement.dart';
import 'package:dark_hours/models/progress/player_stats.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  PlayerStats? _stats;
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final achievements = await AchievementManager.loadAll();
    final stats = await AchievementManager.loadStats();
    setState(() {
      _achievements = achievements;
      _stats = stats;
      _isLoading = false;
    });
  }

  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'all') return _achievements;
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  static const List<String> _categories = [
    'all',
    'combat',
    'survival',
    'story',
    'crafting',
    'loot',
    'medicine',
  ];

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'all':
        return '📦 Все';
      case 'combat':
        return '⚔️ Бой';
      case 'survival':
        return '🌅 Выживание';
      case 'story':
        return '📖 Сюжет';
      case 'crafting':
        return '🔨 Крафт';
      case 'loot':
        return '🎁 Добыча';
      case 'medicine':
        return '💊 Медицина';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 10, 10, 10),
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 200, 180, 100),
          ),
        ),
      );
    }

    if (_stats == null) return const SizedBox.shrink();

    final unlockedCount = _stats!.unlockedAchievements.length;
    final totalCount = _achievements.length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ДОСТИЖЕНИЯ',
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
          // Статистика сверху
          _buildStatsHeader(unlockedCount, totalCount),

          // Категории
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 200, 180, 100)
                              .withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 200, 180, 100)
                            : Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _categoryLabel(cat),
                      style: TextStyle(
                        color: isSelected
                            ? const Color.fromARGB(255, 200, 180, 100)
                            : Colors.grey[500],
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Список достижений
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredAchievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(_filteredAchievements[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int unlockedCount, int totalCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 200, 180, 100).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Прогресс достижений
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Прогресс: $unlockedCount / $totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${((unlockedCount / totalCount) * 100).round()}%',
                style: const TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: unlockedCount / totalCount,
              backgroundColor: Colors.grey[900],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 200, 180, 100),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color.fromARGB(255, 40, 40, 40), height: 1),
          const SizedBox(height: 12),

          // Общая статистика
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '🎮',
                  '${_stats!.totalGamesPlayed}',
                  'Игр',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '💀',
                  '${_stats!.totalDeaths}',
                  'Смертей',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '📅',
                  '${_stats!.bestRunDays}',
                  'Лучший',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '⚔️',
                  '${_stats!.totalKills}',
                  'Убийств',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '🔨',
                  '${_stats!.totalItemsCrafted}',
                  'Крафтов',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '🎁',
                  '${_stats!.totalItemsLooted}',
                  'Найдено',
                ),
              ),
            ],
          ),
          if (_stats!.bestRunCharacter.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Лучший забег: ${_stats!.bestRunCharacter} — ${_stats!.bestRunDays} дн.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final unlocked =
        _stats!.unlockedAchievements.contains(achievement.id);
    final hidden = achievement.secret && !unlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? achievement.categoryColor.withOpacity(0.05)
            : const Color.fromARGB(255, 18, 18, 18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked
              ? achievement.categoryColor.withOpacity(0.5)
              : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? achievement.categoryColor.withOpacity(0.15)
                  : Colors.grey[900],
              border: Border.all(
                color: unlocked
                    ? achievement.categoryColor
                    : Colors.grey[700]!,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                hidden ? '❓' : achievement.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hidden ? 'Скрытое достижение' : achievement.name,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hidden ? 'Выполни особое условие' : achievement.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: achievement.categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        achievement.categoryName,
                        style: TextStyle(
                          color: achievement.categoryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${achievement.points} оч.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Статус
          if (unlocked)
            Icon(
              Icons.check_circle,
              color: achievement.categoryColor,
              size: 22,
            )
          else
            Icon(
              Icons.lock_outline,
              color: Colors.grey[700],
              size: 20,
            ),
        ],
      ),
    );
  }
}
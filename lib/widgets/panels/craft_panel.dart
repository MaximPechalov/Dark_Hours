import 'package:flutter/material.dart';
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/services/items/item_icon_loader.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class CraftPanel extends StatefulWidget {
  final Inventory inventory;
  final int intelligence;
  final int strength;
  final int stamina;
  final List<Recipe> recipes;
  final Function(Recipe) onCraft;

  const CraftPanel({
    super.key,
    required this.inventory,
    required this.intelligence,
    required this.strength,
    required this.stamina,
    required this.recipes,
    required this.onCraft,
  });

  @override
  State<CraftPanel> createState() => _CraftPanelState();
}

class _CraftPanelState extends State<CraftPanel> {
  String _selectedCategory = 'all';

  /// Карта: itemId → количество
  Map<String, int> get _inventoryCounts {
    final map = <String, int>{};
    for (final item in widget.inventory.items) {
      map[item.id] = (map[item.id] ?? 0) + item.count;
    }
    return map;
  }

  List<Recipe> get _filteredRecipes {
    if (_selectedCategory == 'all') return widget.recipes;
    return widget.recipes
        .where((r) => r.category == _selectedCategory)
        .toList();
  }

  static const List<String> _categories = [
    'all',
    'weapon',
    'tool',
    'medicine',
    'armor',
    'ammo',
  ];

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'all':
        return '📦 Всё';
      case 'weapon':
        return '🗡️ Оружие';
      case 'tool':
        return '🔧 Инстр.';
      case 'medicine':
        return '💊 Мед.';
      case 'armor':
        return '🦺 Броня';
      case 'ammo':
        return '🏹 Патроны';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 15, 15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Icon(
                Icons.build_circle_outlined,
                color: Color.fromARGB(255, 200, 180, 100),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'КРАФТ',
                style: TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              // Статы игрока
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 25, 25, 25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color.fromARGB(255, 200, 180, 100)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.intelligence}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('💪', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.strength}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('⚡', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.stamina}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Категории
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    AudioService.playTap();
                    setState(() => _selectedCategory = cat);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 200, 180, 100)
                              .withValues(alpha: 0.2)
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

          // Список рецептов
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: _filteredRecipes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Нет рецептов в этой категории',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _filteredRecipes[index];
                      return _buildRecipeCard(recipe);
                    },
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final counts = _inventoryCounts;
    final canCraft = recipe.canCraft(
      inventoryCounts: counts,
      intelligence: widget.intelligence,
      strength: widget.strength,
    );
    final blockReason = recipe.getCraftBlockReason(
      inventoryCounts: counts,
      intelligence: widget.intelligence,
      strength: widget.strength,
    );

    final rarityColor = recipe.rarityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 22, 22, 22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: canCraft
              ? rarityColor.withValues(alpha: 0.5)
              : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              // ⚡ ИКОНКА РЕЗУЛЬТАТА: PNG или эмодзи.
              ItemIconLoader.buildIcon(
                itemId: recipe.resultId,
                fallbackEmoji: recipe.resultIcon,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipe.categoryName,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (canCraft)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: const Text(
                    '✔ ДОСТУПНО',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🔒',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recipe.description,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Ингредиенты
          const Text(
            'Ингредиенты:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: recipe.ingredients.map((ing) {
              final have = counts[ing.id] ?? 0;
              final enough = have >= ing.count;
              final item = ItemLoader.findById(ing.id);
              final label = item != null
                  ? '${item.icon} ${have}/${ing.count}'
                  : '${ing.id} $have/${ing.count}';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: enough
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: enough
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: enough ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Требования и время
          Row(
            children: [
              _buildReqChip(
                '⏱️ ${recipe.timeMinutes} мин',
                Colors.blue[400]!,
              ),
              const SizedBox(width: 6),
              if (recipe.requiredIntelligence > 0)
                _buildReqChip(
                  '🧠 ${recipe.requiredIntelligence}',
                  widget.intelligence >= recipe.requiredIntelligence
                      ? Colors.green
                      : Colors.red,
                ),
              const SizedBox(width: 6),
              if (recipe.requiredStrength > 0)
                _buildReqChip(
                  '💪 ${recipe.requiredStrength}',
                  widget.strength >= recipe.requiredStrength
                      ? Colors.green
                      : Colors.red,
                ),
            ],
          ),

          // Причина блокировки
          if (!canCraft && blockReason != null) ...[
            const SizedBox(height: 6),
            Text(
              '🔒 $blockReason',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Кнопка "Создать"
          if (canCraft) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  AudioService.playClick();
                  widget.onCraft(recipe);
                },
                icon: const Icon(Icons.build, size: 14),
                label: const Text(
                  'СОЗДАТЬ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rarityColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReqChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class InventoryPanel extends StatelessWidget {
  final Inventory inventory;
  final Function(InventoryItem)? onUse;
  final Function(InventoryItem)? onEquip;
  final Function(InventoryItem)? onDrop;

  const InventoryPanel({
    super.key,
    required this.inventory,
    this.onUse,
    this.onEquip,
    this.onDrop,
  });

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color.fromARGB(255, 150, 150, 150);
      case 'uncommon':
        return const Color.fromARGB(255, 100, 200, 100);
      case 'rare':
        return const Color.fromARGB(255, 100, 150, 255);
      case 'epic':
        return const Color.fromARGB(255, 200, 100, 255);
      case 'legendary':
        return const Color.fromARGB(255, 255, 200, 50);
      default:
        return Colors.white;
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
          Row(
            children: [
              const Icon(
                Icons.backpack,
                color: Color.fromARGB(255, 200, 180, 100),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'ИНВЕНТАРЬ',
                style: TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Text(
                '${inventory.currentWeight.toStringAsFixed(1)} / ${inventory.maxWeight.toStringAsFixed(0)} кг',
                style: TextStyle(
                  color: inventory.isOverloaded
                      ? Colors.red
                      : Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (inventory.currentWeight / inventory.maxWeight).clamp(0, 1),
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation<Color>(
                inventory.isOverloaded
                    ? Colors.red
                    : const Color.fromARGB(255, 200, 180, 100),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          if (inventory.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'Инвентарь пуст',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: inventory.items.length,
                itemBuilder: (context, index) {
                  final item = inventory.items[index];
                  final rarityColor = _rarityColor(item.rarity);

                  return GestureDetector(
                    onTap: () {
                      AudioService.playTap();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        isDismissible: true,
                        enableDrag: true,
                        builder: (_) => ItemDetailsSheet(
                          item: item,
                          rarityColor: rarityColor,
                          onUse: onUse,
                          onEquip: onEquip,
                          onDrop: onDrop,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 25, 25, 25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rarityColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                item.icon,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _buildItemSubtitle(item),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.count > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rarityColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: rarityColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '×${item.count}',
                                    style: TextStyle(
                                      color: rarityColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (item.isConsumable && onUse != null)
                                _buildActionButton(
                                  'Использовать',
                                  Icons.restaurant,
                                  Colors.green,
                                  () {
                                    AudioService.playClick();
                                    onUse!(item);
                                  },
                                ),
                              if (item.isEquippable && onEquip != null)
                                _buildActionButton(
                                  'Надеть',
                                  Icons.shield_outlined,
                                  Colors.blue,
                                  () {
                                    AudioService.playClick();
                                    onEquip!(item);
                                  },
                                ),
                              if (onDrop != null)
                                _buildActionButton(
                                  'Выбросить',
                                  Icons.delete_outline,
                                  Colors.red,
                                  () {
                                    AudioService.playClick();
                                    onDrop!(item);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _buildItemSubtitle(InventoryItem item) {
    final parts = <String>[];
    parts.add('${item.totalWeight.toStringAsFixed(1)} кг');

    if (item.damage > 0) parts.add('⚔️ ${item.damage}');
    if (item.protection > 0) parts.add('🛡️ ${item.protection}');
    if (item.warmth > 0) parts.add('🔥 ${item.warmth}');
    if (item.hungerRestore > 0) parts.add('🍞 +${item.hungerRestore}');
    if (item.thirstRestore > 0) parts.add('💧 +${item.thirstRestore}');
    if (item.healthRestore > 0) parts.add('❤️ +${item.healthRestore}');
    if (item.sanityRestore > 0) parts.add('🧠 +${item.sanityRestore}');

    return parts.join(' · ');
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 11),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ============================================================
// ДЕТАЛЬНАЯ МОДАЛКА ПРЕДМЕТА
// ============================================================

class ItemDetailsSheet extends StatelessWidget {
  final InventoryItem item;
  final Color rarityColor;
  final Function(InventoryItem)? onUse;
  final Function(InventoryItem)? onEquip;
  final Function(InventoryItem)? onDrop;
  final VoidCallback? onUnequip;

  const ItemDetailsSheet({
    super.key,
    required this.item,
    required this.rarityColor,
    this.onUse,
    this.onEquip,
    this.onDrop,
    this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 15, 15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Большая иконка
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rarityColor.withOpacity(0.1),
                border: Border.all(color: rarityColor, width: 2),
              ),
              child: Center(
                child: Text(
                  item.icon,
                  style: const TextStyle(fontSize: 46),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Название
            Text(
              item.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Редкость + количество
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rarityColor, width: 1),
                  ),
                  child: Text(
                    _rarityName(item.rarity),
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item.count > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${item.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Описание
            if (item.description.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 20, 20, 20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[850]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Характеристики
            if (_hasCharacteristics) ...[
              _sectionTitle('ХАРАКТЕРИСТИКИ'),
              const SizedBox(height: 10),
              _buildCharacteristics(),
              const SizedBox(height: 20),
            ],

            // Эффекты
            if (_hasEffects) ...[
              _sectionTitle('ЭФФЕКТЫ'),
              const SizedBox(height: 10),
              _buildEffects(),
              const SizedBox(height: 20),
            ],

            // Вес
            _sectionTitle('ВЕС'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.totalWeight.toStringAsFixed(2)} кг',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Кнопки действий
            if (onUse != null && item.isConsumable)
              _buildActionRow(
                context,
                label: 'ИСПОЛЬЗОВАТЬ',
                icon: Icons.restaurant,
                color: Colors.green,
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                  onUse!(item);
                },
              ),
            if (onEquip != null && item.isEquippable)
              _buildActionRow(
                context,
                label: 'НАДЕТЬ',
                icon: Icons.shield_outlined,
                color: Colors.blue,
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                  onEquip!(item);
                },
              ),
            if (onUnequip != null)
              _buildActionRow(
                context,
                label: 'СНЯТЬ',
                icon: Icons.remove_circle_outline,
                color: Colors.orange,
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                  onUnequip!();
                },
              ),
            if (onDrop != null)
              _buildActionRow(
                context,
                label: 'ВЫБРОСИТЬ',
                icon: Icons.delete_outline,
                color: Colors.red,
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                  onDrop!(item);
                },
              ),

            const SizedBox(height: 12),

            // Кнопка закрыть
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                },
                child: const Text(
                  'ЗАКРЫТЬ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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

  bool get _hasCharacteristics {
    return item.damage > 0 ||
        item.protection > 0 ||
        item.warmth > 0 ||
        item.extraSlots > 0 ||
        item.resistances.isNotEmpty ||
        item.requiredStrength > 0 ||
        item.armorSlot != null;
  }

  bool get _hasEffects {
    return item.hungerRestore != 0 ||
        item.thirstRestore != 0 ||
        item.healthRestore != 0 ||
        item.sanityRestore != 0;
  }

  Widget _buildCharacteristics() {
    final rows = <Widget>[];

    if (item.damage > 0) {
      rows.add(_characteristicRow(
        '⚔️ Урон',
        '${item.damage} (${_damageTypeName(item.damageType)})',
        Colors.red,
      ));
    }
    if (item.protection > 0) {
      rows.add(_characteristicRow(
        '🛡️ Защита',
        '${item.protection}',
        Colors.blue,
      ));
    }
    if (item.warmth > 0) {
      rows.add(_characteristicRow(
        '🔥 Тепло',
        '${item.warmth}',
        Colors.orange,
      ));
    }
    if (item.armorSlot != null) {
      rows.add(_characteristicRow(
        '📍 Слот',
        _slotName(item.armorSlot!),
        Colors.purple,
      ));
    }
    if (item.extraSlots > 0) {
      rows.add(_characteristicRow(
        '🎒 Доп. слоты',
        '+${item.extraSlots}',
        Colors.teal,
      ));
    }
    if (item.requiredStrength > 0) {
      rows.add(_characteristicRow(
        '💪 Требуемая сила',
        '${item.requiredStrength}',
        Colors.deepOrange,
      ));
    }

    // Сопротивления
    if (item.resistances.isNotEmpty) {
      final res = item.resistances;
      final nonZero = res.entries.where((e) => e.value > 0).toList();
      if (nonZero.isNotEmpty) {
        rows.add(const SizedBox(height: 4));
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Сопротивления:',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
        rows.add(const SizedBox(height: 4));
        for (final entry in nonZero) {
          rows.add(_characteristicRow(
            '  ${_resistanceName(entry.key)}',
            '${entry.value}',
            Colors.green[400]!,
          ));
        }
      }
    }

    return Column(children: rows);
  }

  Widget _buildEffects() {
    final rows = <Widget>[];

    if (item.hungerRestore != 0) {
      rows.add(_effectRow(
        '🍞 Голод',
        item.hungerRestore,
        Colors.orange,
      ));
    }
    if (item.thirstRestore != 0) {
      rows.add(_effectRow(
        '💧 Жажда',
        item.thirstRestore,
        Colors.blue,
      ));
    }
    if (item.healthRestore != 0) {
      rows.add(_effectRow(
        '❤️ Здоровье',
        item.healthRestore,
        Colors.red,
      ));
    }
    if (item.sanityRestore != 0) {
      rows.add(_effectRow(
        '🧠 Психика',
        item.sanityRestore,
        Colors.purple,
      ));
    }

    return Column(children: rows);
  }

  Widget _effectRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${value > 0 ? '+' : ''}$value',
            style: TextStyle(
              color: value > 0 ? color : Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _characteristicRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 1,
          width: 30,
          color: Colors.grey[800],
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Color.fromARGB(255, 200, 180, 100),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 1,
          width: 30,
          color: Colors.grey[800],
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  String _rarityName(String rarity) {
    switch (rarity) {
      case 'common':
        return 'Обычное';
      case 'uncommon':
        return 'Необычное';
      case 'rare':
        return 'Редкое';
      case 'epic':
        return 'Эпическое';
      case 'legendary':
        return 'Легендарное';
      default:
        return rarity;
    }
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
        return 'огнестрельный';
      default:
        return type;
    }
  }

  String _slotName(String slot) {
    switch (slot) {
      case 'head':
        return 'Голова';
      case 'body':
        return 'Тело';
      case 'hands':
        return 'Руки';
      case 'feet':
        return 'Ноги';
      case 'backpack':
        return 'Рюкзак';
      default:
        return slot;
    }
  }

  String _resistanceName(String key) {
    switch (key) {
      case 'cutting':
        return 'Режущий';
      case 'blunt':
        return 'Дробящий';
      case 'piercing':
        return 'Колющий';
      case 'firearm':
        return 'Огнестрельный';
      default:
        return key;
    }
  }
}
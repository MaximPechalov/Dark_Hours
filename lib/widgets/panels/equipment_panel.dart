import 'package:flutter/material.dart';
import 'package:dark_hours/models/inventory/equipment.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/services/items/item_icon_loader.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/widgets/panels/inventory_panel.dart'
    show ItemDetailsSheet;

class EquipmentPanel extends StatelessWidget {
  final Equipment equipment;
  final Function(String slot)? onUnequip;

  const EquipmentPanel({
    super.key,
    required this.equipment,
    this.onUnequip,
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
          // Заголовок
          Row(
            children: const [
              Icon(
                Icons.shield_outlined,
                color: Color.fromARGB(255, 200, 180, 100),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'ЭКИПИРОВКА',
                style: TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Итоговые характеристики
          _buildSummaryCard(),
          const SizedBox(height: 16),

          // Слоты экипировки
          _buildSlot(context, 'weapon', 'Оружие', Icons.gavel, equipment.weapon),
          _buildSlot(context, 'head', 'Голова', Icons.face, equipment.head),
          _buildSlot(context, 'body', 'Тело', Icons.checkroom, equipment.body),
          _buildSlot(
              context, 'hands', 'Руки', Icons.back_hand, equipment.hands),
          _buildSlot(
              context, 'feet', 'Ноги', Icons.directions_walk, equipment.feet),
          _buildSlot(context, 'backpack', 'Рюкзак', Icons.backpack,
              equipment.backpack),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ИТОГОВЫЕ ХАРАКТЕРИСТИКИ
  // ═══════════════════════════════════════════════════════════

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 25, 25, 25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 200, 180, 100)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatSummary(
            '⚔️',
            '${equipment.totalDamage}',
            'Урон',
            Colors.red[400]!,
          ),
          _buildStatSummary(
            '🛡️',
            '${equipment.totalProtection}',
            'Защита',
            Colors.blue[400]!,
          ),
          _buildStatSummary(
            '🔥',
            '${equipment.totalWarmth}',
            'Тепло',
            Colors.orange[400]!,
          ),
          _buildStatSummary(
            '🎒',
            '+${equipment.extraSlots}',
            'Слоты',
            Colors.teal[300]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatSummary(
    String icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // СЛОТЫ ЭКИПИРОВКИ
  // ═══════════════════════════════════════════════════════════

  Widget _buildSlot(
    BuildContext context,
    String slotKey,
    String label,
    IconData icon,
    InventoryItem? item,
  ) {
    final isEmpty = item == null;
    final rarityColor =
        isEmpty ? Colors.grey[700]! : _rarityColor(item.rarity);

    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 25, 25, 25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rarityColor.withValues(alpha: isEmpty ? 0.2 : 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEmpty ? Colors.grey[700] : rarityColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                if (isEmpty)
                  Text(
                    '— пусто —',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Row(
                    children: [
                      // ⚡ ИКОНКА ПРЕДМЕТА: PNG или эмодзи.
                      ItemIconLoader.buildIcon(
                        itemId: item.id,
                        fallbackEmoji: item.icon,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!isEmpty && onUnequip != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              tooltip: 'Снять',
              onPressed: () {
                AudioService.playClick();
                onUnequip!(slotKey);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );

    // Пустой слот — не кликабелен.
    if (isEmpty) return content;

    // Надетый предмет — тап открывает детали.
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
            onUnequip: () {
              onUnequip?.call(slotKey);
            },
          ),
        );
      },
      child: content,
    );
  }
}
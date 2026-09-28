import 'package:flutter/material.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';

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
                  return Container(
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
                        // Кнопки действий
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (item.isConsumable && onUse != null)
                              _buildActionButton(
                                'Использовать',
                                Icons.restaurant,
                                Colors.green,
                                () => onUse!(item),
                              ),
                            if (item.isEquippable && onEquip != null)
                              _buildActionButton(
                                'Надеть',
                                Icons.shield_outlined,
                                Colors.blue,
                                () => onEquip!(item),
                              ),
                            if (onDrop != null)
                              _buildActionButton(
                                'Выбросить',
                                Icons.delete_outline,
                                Colors.red,
                                () => onDrop!(item),
                              ),
                          ],
                        ),
                      ],
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
import '../models/weapon.dart';
import '../models/tool.dart';
import '../models/consumable.dart';
import '../models/armor.dart';
import '../models/resource.dart';
import '../models/inventory_item.dart';

class ItemLoader {
  static List<Weapon> _weapons = [];
  static List<Tool> _tools = [];
  static List<Consumable> _consumables = [];
  static List<Armor> _armor = [];
  static List<GameResource> _resources = [];
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;
    _weapons = await Weapon.loadAll();
    _tools = await Tool.loadAll();
    _consumables = await Consumable.loadAll();
    _armor = await Armor.loadAll();
    _resources = await GameResource.loadAll();
    _loaded = true;
  }

  static InventoryItem? findById(String id) {
    // Оружие
    for (final w in _weapons) {
      if (w.id == id) {
        return InventoryItem(
          id: w.id,
          name: w.name,
          icon: w.icon,
          rarity: w.rarity,
          weight: w.weight,
          count: 1,
          sourceType: 'weapon',
          damage: w.damage,
          requiredStrength: w.requiredStrength,
        );
      }
    }

    // Инструменты
    for (final t in _tools) {
      if (t.id == id) {
        return InventoryItem(
          id: t.id,
          name: t.name,
          icon: t.icon,
          rarity: t.rarity,
          weight: t.weight,
          count: 1,
          sourceType: 'tool',
        );
      }
    }

    // Расходники
    for (final c in _consumables) {
      if (c.id == id) {
        return InventoryItem(
          id: c.id,
          name: c.name,
          icon: c.icon,
          rarity: c.rarity,
          weight: c.weight,
          count: 1,
          sourceType: 'consumable',
          hungerRestore: c.hungerRestore,
          thirstRestore: c.thirstRestore,
          healthRestore: c.healthRestore,
          sanityRestore: c.sanityRestore,
        );
      }
    }

    // Броня
    for (final a in _armor) {
      if (a.id == id) {
        final item = InventoryItem(
          id: a.id,
          name: a.name,
          icon: a.icon,
          rarity: a.rarity,
          weight: a.weight,
          count: 1,
          sourceType: 'armor',
          protection: a.protection,
          warmth: a.warmth,
          extraSlots: a.extraSlots ?? 0,
        );
        item.setArmorSlot(a.slot);
        return item;
      }
    }

    // Ресурсы
    for (final r in _resources) {
      if (r.id == id) {
        return InventoryItem(
          id: r.id,
          name: r.name,
          icon: r.icon,
          rarity: r.rarity,
          weight: r.weight,
          count: 1,
          sourceType: 'resource',
        );
      }
    }

    return null;
  }
}
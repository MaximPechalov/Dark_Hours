import 'inventory_item.dart';

class Equipment {
  InventoryItem? weapon;
  InventoryItem? head;
  InventoryItem? body;
  InventoryItem? hands;
  InventoryItem? feet;
  InventoryItem? backpack;

  Equipment();

  InventoryItem? getBySlot(String slot) {
    switch (slot) {
      case 'weapon':
        return weapon;
      case 'head':
        return head;
      case 'body':
        return body;
      case 'hands':
        return hands;
      case 'feet':
        return feet;
      case 'backpack':
        return backpack;
      default:
        return null;
    }
  }

  void equip(InventoryItem item, String slot) {
    switch (slot) {
      case 'weapon':
        weapon = item;
        break;
      case 'head':
        head = item;
        break;
      case 'body':
        body = item;
        break;
      case 'hands':
        hands = item;
        break;
      case 'feet':
        feet = item;
        break;
      case 'backpack':
        backpack = item;
        break;
    }
  }

  InventoryItem? unequip(String slot) {
    InventoryItem? item;
    switch (slot) {
      case 'weapon':
        item = weapon;
        weapon = null;
        break;
      case 'head':
        item = head;
        head = null;
        break;
      case 'body':
        item = body;
        body = null;
        break;
      case 'hands':
        item = hands;
        hands = null;
        break;
      case 'feet':
        item = feet;
        feet = null;
        break;
      case 'backpack':
        item = backpack;
        backpack = null;
        break;
    }
    return item;
  }

  int get totalProtection {
    int sum = 0;
    if (head != null) sum += head!.protection;
    if (body != null) sum += body!.protection;
    if (hands != null) sum += hands!.protection;
    if (feet != null) sum += feet!.protection;
    return sum;
  }

  int get totalWarmth {
    int sum = 0;
    if (head != null) sum += head!.warmth;
    if (body != null) sum += body!.warmth;
    if (hands != null) sum += hands!.warmth;
    if (feet != null) sum += feet!.warmth;
    return sum;
  }

  int get extraSlots {
    if (backpack != null) return backpack!.extraSlots;
    return 0;
  }

  int get totalDamage {
    if (weapon != null) return weapon!.damage;
    return 0;
  }

  /// Сериализация
  Map<String, dynamic> toJson() {
    return {
      'weapon': weapon?.toJson(),
      'head': head?.toJson(),
      'body': body?.toJson(),
      'hands': hands?.toJson(),
      'feet': feet?.toJson(),
      'backpack': backpack?.toJson(),
    };
  }

  /// Загрузка из JSON
  static Equipment fromJson(Map<String, dynamic> json) {
    final eq = Equipment();
    if (json['weapon'] != null) {
      eq.weapon = InventoryItem.fromJson(Map<String, dynamic>.from(json['weapon']));
    }
    if (json['head'] != null) {
      eq.head = InventoryItem.fromJson(Map<String, dynamic>.from(json['head']));
    }
    if (json['body'] != null) {
      eq.body = InventoryItem.fromJson(Map<String, dynamic>.from(json['body']));
    }
    if (json['hands'] != null) {
      eq.hands = InventoryItem.fromJson(Map<String, dynamic>.from(json['hands']));
    }
    if (json['feet'] != null) {
      eq.feet = InventoryItem.fromJson(Map<String, dynamic>.from(json['feet']));
    }
    if (json['backpack'] != null) {
      eq.backpack = InventoryItem.fromJson(Map<String, dynamic>.from(json['backpack']));
    }
    return eq;
  }
}
class InventoryItem {
  final String id;
  final String name;
  final String icon;
  final String rarity;
  final double weight;
  final int count;
  final String sourceType;

  // Бонусные характеристики (для брони)
  final int protection;
  final int warmth;
  final int extraSlots;

  // Характеристики оружия
  final int damage;
  final int requiredStrength;

  // Характеристики расходников
  final int hungerRestore;
  final int thirstRestore;
  final int healthRestore;
  final int sanityRestore;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.rarity,
    required this.weight,
    required this.count,
    required this.sourceType,
    this.protection = 0,
    this.warmth = 0,
    this.extraSlots = 0,
    this.damage = 0,
    this.requiredStrength = 0,
    this.hungerRestore = 0,
    this.thirstRestore = 0,
    this.healthRestore = 0,
    this.sanityRestore = 0,
  });

  InventoryItem copyWith({int? count}) {
    return InventoryItem(
      id: id,
      name: name,
      icon: icon,
      rarity: rarity,
      weight: weight,
      count: count ?? this.count,
      sourceType: sourceType,
      protection: protection,
      warmth: warmth,
      extraSlots: extraSlots,
      damage: damage,
      requiredStrength: requiredStrength,
      hungerRestore: hungerRestore,
      thirstRestore: thirstRestore,
      healthRestore: healthRestore,
      sanityRestore: sanityRestore,
    );
  }

  double get totalWeight => weight * count;

  /// Определить, в какой слот надевается предмет
  String? get equippableSlot {
    if (sourceType == 'weapon') return 'weapon';
    if (sourceType == 'armor') {
      // Слот уточняется при загрузке (см. item_loader)
      return _armorSlot;
    }
    return null;
  }

  String? _armorSlot;

  /// Проверка, можно ли использовать предмет (расходник)
  bool get isConsumable => sourceType == 'consumable';

  /// Проверка, можно ли надеть
  bool get isEquippable =>
      sourceType == 'weapon' || sourceType == 'armor';

  void setArmorSlot(String slot) {
    _armorSlot = slot;
  }

  String? get armorSlot => _armorSlot;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'rarity': rarity,
      'weight': weight,
      'count': count,
      'sourceType': sourceType,
      'protection': protection,
      'warmth': warmth,
      'extraSlots': extraSlots,
      'damage': damage,
      'requiredStrength': requiredStrength,
      'hungerRestore': hungerRestore,
      'thirstRestore': thirstRestore,
      'healthRestore': healthRestore,
      'sanityRestore': sanityRestore,
      'armorSlot': _armorSlot,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final item = InventoryItem(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      rarity: json['rarity'],
      weight: (json['weight'] as num).toDouble(),
      count: json['count'] ?? 1,
      sourceType: json['sourceType'],
      protection: json['protection'] ?? 0,
      warmth: json['warmth'] ?? 0,
      extraSlots: json['extraSlots'] ?? 0,
      damage: json['damage'] ?? 0,
      requiredStrength: json['requiredStrength'] ?? 0,
      hungerRestore: json['hungerRestore'] ?? 0,
      thirstRestore: json['thirstRestore'] ?? 0,
      healthRestore: json['healthRestore'] ?? 0,
      sanityRestore: json['sanityRestore'] ?? 0,
    );
    if (json['armorSlot'] != null) {
      item.setArmorSlot(json['armorSlot']);
    }
    return item;
  }
}
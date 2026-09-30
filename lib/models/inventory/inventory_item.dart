class InventoryItem {
  final String id;
  final String name;
  final String description;  // ← НОВОЕ ПОЛЕ
  final String icon;
  final String rarity;
  final double weight;
  final int count;
  final String sourceType;

  // Броня
  final int protection;
  final int warmth;
  final int extraSlots;
  final Map<String, int> resistances;
  final String? armorSlot;

  // Оружие
  final int damage;
  final int requiredStrength;
  final String damageType;

  // Расходники
  final int hungerRestore;
  final int thirstRestore;
  final int healthRestore;
  final int sanityRestore;

  const InventoryItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.icon,
    required this.rarity,
    required this.weight,
    required this.count,
    required this.sourceType,
    this.protection = 0,
    this.warmth = 0,
    this.extraSlots = 0,
    this.resistances = const {},
    this.armorSlot,
    this.damage = 0,
    this.requiredStrength = 0,
    this.damageType = 'blunt',
    this.hungerRestore = 0,
    this.thirstRestore = 0,
    this.healthRestore = 0,
    this.sanityRestore = 0,
  });

  InventoryItem copyWith({int? count}) {
    return InventoryItem(
      id: id,
      name: name,
      description: description,
      icon: icon,
      rarity: rarity,
      weight: weight,
      count: count ?? this.count,
      sourceType: sourceType,
      protection: protection,
      warmth: warmth,
      extraSlots: extraSlots,
      resistances: resistances,
      armorSlot: armorSlot,
      damage: damage,
      requiredStrength: requiredStrength,
      damageType: damageType,
      hungerRestore: hungerRestore,
      thirstRestore: thirstRestore,
      healthRestore: healthRestore,
      sanityRestore: sanityRestore,
    );
  }

  double get totalWeight => weight * count;

  String? get equippableSlot {
    if (sourceType == 'weapon') return 'weapon';
    if (sourceType == 'armor') return armorSlot;
    return null;
  }

  bool get isConsumable => sourceType == 'consumable';
  bool get isEquippable => sourceType == 'weapon' || sourceType == 'armor';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity,
      'weight': weight,
      'count': count,
      'sourceType': sourceType,
      'protection': protection,
      'warmth': warmth,
      'extraSlots': extraSlots,
      'resistances': resistances,
      'armorSlot': armorSlot,
      'damage': damage,
      'requiredStrength': requiredStrength,
      'damageType': damageType,
      'hungerRestore': hungerRestore,
      'thirstRestore': thirstRestore,
      'healthRestore': healthRestore,
      'sanityRestore': sanityRestore,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'],
      rarity: json['rarity'],
      weight: (json['weight'] as num).toDouble(),
      count: json['count'] ?? 1,
      sourceType: json['sourceType'],
      protection: json['protection'] ?? 0,
      warmth: json['warmth'] ?? 0,
      extraSlots: json['extraSlots'] ?? 0,
      resistances: json['resistances'] != null
          ? Map<String, int>.from(json['resistances'])
          : const {},
      armorSlot: json['armorSlot'],
      damage: json['damage'] ?? 0,
      requiredStrength: json['requiredStrength'] ?? 0,
      damageType: json['damageType'] ?? 'blunt',
      hungerRestore: json['hungerRestore'] ?? 0,
      thirstRestore: json['thirstRestore'] ?? 0,
      healthRestore: json['healthRestore'] ?? 0,
      sanityRestore: json['sanityRestore'] ?? 0,
    );
  }
}
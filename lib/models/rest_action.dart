class RestAction {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int timeMinutes;
  final int staminaRestore;
  final int healthRestore;
  final int sanityRestore;
  final int fatigueReduce;
  final int hungerCost;
  final int thirstCost;
  final String riskLevel; // safe, low, medium, high

  const RestAction({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.timeMinutes,
    required this.staminaRestore,
    required this.healthRestore,
    required this.sanityRestore,
    required this.fatigueReduce,
    required this.hungerCost,
    required this.thirstCost,
    required this.riskLevel,
  });

  static const List<RestAction> all = [
    RestAction(
      id: 'short_rest',
      name: 'Короткий привал',
      description: 'Присесть на 30 минут. Немного восстановить силы.',
      icon: '🪑',
      timeMinutes: 30,
      staminaRestore: 20,
      healthRestore: 0,
      sanityRestore: 5,
      fatigueReduce: 15,
      hungerCost: 5,
      thirstCost: 5,
      riskLevel: 'low',
    ),
    RestAction(
      id: 'nap',
      name: 'Дневной сон',
      description: 'Поспать 4 часа. Восстановить силы, но потерять время.',
      icon: '😴',
      timeMinutes: 240,
      staminaRestore: 50,
      healthRestore: 10,
      sanityRestore: 15,
      fatigueReduce: 45,
      hungerCost: 10,
      thirstCost: 10,
      riskLevel: 'medium',
    ),
    RestAction(
      id: 'full_sleep',
      name: 'Полноценный сон',
      description: 'Спать 8 часов. Полное восстановление.',
      icon: '🛏️',
      timeMinutes: 480,
      staminaRestore: 80,
      healthRestore: 25,
      sanityRestore: 30,
      fatigueReduce: 80,
      hungerCost: 15,
      thirstCost: 15,
      riskLevel: 'high',
    ),
    RestAction(
      id: 'deep_sleep',
      name: 'Глубокий сон',
      description: 'Спать 12 часов. Максимальное восстановление.',
      icon: '💤',
      timeMinutes: 720,
      staminaRestore: 100,
      healthRestore: 40,
      sanityRestore: 50,
      fatigueReduce: 100,
      hungerCost: 20,
      thirstCost: 20,
      riskLevel: 'high',
    ),
  ];
}
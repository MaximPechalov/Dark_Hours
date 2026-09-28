class Combatant {
  final String name;
  int health;
  int maxHealth;
  int damage;
  int protection;
  int strength;

  Combatant({
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.damage,
    required this.protection,
    required this.strength,
  });

  bool get isDead => health <= 0;

  /// Рассчитать урон с учётом защиты
  int calculateDamage(Combatant target) {
    int raw = damage;
    // Бонус от силы
    raw += (strength - 5) * 2;
    // Минимум 1
    if (raw < 1) raw = 1;
    // Вычитаем защиту
    int finalDamage = raw - target.protection;
    if (finalDamage < 1) finalDamage = 1;
    return finalDamage;
  }

  void takeDamage(int dmg) {
    health = (health - dmg).clamp(0, maxHealth);
  }
}
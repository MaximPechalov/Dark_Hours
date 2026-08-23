class Character {
  final String id;
  final String name;
  final String age;
  final String profession;
  final String startLocation;
  final String description;
  final String habitBonus;
  final String inventory;
  final String startingLine;
  final int strength;
  final int intelligence;
  final int cunning;
  final int endurance;

  const Character({
    required this.id,
    required this.name,
    required this.age,
    required this.profession,
    required this.startLocation,
    required this.description,
    required this.habitBonus,
    required this.inventory,
    required this.startingLine,
    required this.strength,
    required this.intelligence,
    required this.cunning,
    required this.endurance,
  });

  // Статический список всех персонажей
  static const List<Character> all = [
    Character(
      id: 'boris',
      name: 'Борис',
      age: '42 года',
      profession: 'Слесарь ЖЭКа',
      startLocation: 'Подвал на окраине',
      description: 'Знает город снизу. Курит "Беломор" и не любит врать.',
      habitBonus: 'Заядлый курильщик: +сигареты, +шум при движении',
      inventory: 'Ключ, фонарик, зажигалка, 2 сигареты, рюкзак',
      startingLine: '"Я каждый люк в этом городе наизусть знаю."',
      strength: 7,
      intelligence: 5,
      cunning: 4,
      endurance: 6,
    ),
    Character(
      id: 'alina',
      name: 'Алина',
      age: '27 лет',
      profession: 'Тренер по легкой атлетике',
      startLocation: '9-й этаж, рядом с "Магнитом"',
      description: 'Привыкла к дистанциям. Вода — её слабость и её сила.',
      habitBonus: 'Спортсменка: +2 слота, +расход воды',
      inventory: 'Сумка (8 слотов), вода (1 л), свисток, повязка',
      startingLine: '"Когда ты бегаешь, пули летят мимо."',
      strength: 3,
      intelligence: 4,
      cunning: 6,
      endurance: 9,
    ),
    Character(
      id: 'ivan',
      name: 'Иван Ильич',
      age: '67 лет',
      profession: 'Отставной майор',
      startLocation: 'Частный дом у леса',
      description: 'Всю жизнь копил консервы и ждал "этого дня".',
      habitBonus: 'Параноик: -20% к ограблению, +20% времени на действия',
      inventory: 'Топор, бинокль, спички, фляга, компас, 3 банки тушенки',
      startingLine: '"Старость — это не слабость, а хитрость."',
      strength: 4,
      intelligence: 8,
      cunning: 8,
      endurance: 3,
    ),
    Character(
      id: 'andrey',
      name: 'Андрей',
      age: '24 года',
      profession: 'Айтишник-фрилансер',
      startLocation: 'Центр, 15-й этаж ЖК',
      description: 'Умеет найти схему в открытых сетях. Боится темноты.',
      habitBonus: 'Кофеман: +интеллект после кофе, -20% без кофе',
      inventory: 'Ноутбук, пауэрбанк (20%), ключ-карта, термос с кофе, шоколад',
      startingLine: '"Я знаю, как оживить любой аккумулятор."',
      strength: 2,
      intelligence: 9,
      cunning: 4,
      endurance: 4,
    ),
    Character(
      id: 'darya',
      name: 'Дарья',
      age: '35 лет',
      profession: 'Медсестра',
      startLocation: 'Рядом с больницей',
      description: 'Знает, чем пахнет смерть. Умеет убеждать, но не драться.',
      habitBonus: 'Чистюля: -30% к болезни, +10% времени на действия',
      inventory: 'Медсумка, антибиотики (2), халат, фонарик, шоколад',
      startingLine: '"В этом мире нельзя помочь всем. Придётся выбирать."',
      strength: 4,
      intelligence: 7,
      cunning: 6,
      endurance: 6,
    ),
  ];

  // Получить персонажа по ID
  static Character? getById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
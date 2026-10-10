// tool/validate.dart
//
// Валидатор JSON-файлов проекта «Тёмные часы».
// Запуск: dart run tool/validate.dart

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  print('');
  print('🔍 Валидатор JSON — Тёмные часы');
  print('═' * 60);

  final validator = Validator();

  print('');
  print('📚 Загрузка справочников...');
  print('─' * 60);

  validator.loadItemIds();
  validator.loadLocationIds();
  validator.loadConditionIds();

  print('  ✅ Предметов: ${validator.itemIds.length}');
  print('  ✅ Локаций: ${validator.locationIds.length}');
  print('  ✅ Состояний: ${validator.conditionIds.length}');

  print('');
  print('📖 Сюжет');
  print('─' * 60);
  validator.validateAllStories();

  print('');
  print('🗺️  Локации');
  print('─' * 60);
  validator.validateLocations();

  print('');
  print('🔨 Рецепты');
  print('─' * 60);
  validator.validateRecipes();

  print('');
  print('🦠 Состояния');
  print('─' * 60);
  validator.validateConditions();

  print('');
  print('🎲 События поиска');
  print('─' * 60);
  validator.validateSearchEvents();

  print('');
  print('🏆 Достижения');
  print('─' * 60);
  validator.validateAchievements();

  print('');
  print('═' * 60);
  print('🎯 Итог');
  print('─' * 60);
  print('  📄 Файлов проверено: ${validator.filesChecked}');
  print('  ${validator.errorCount == 0 ? "✅" : "❌"} Ошибок: ${validator.errorCount}');
  print('  ${validator.warningCount == 0 ? "✅" : "⚠️ "} Предупреждений: ${validator.warningCount}');
  print('');

  if (validator.errorCount > 0) {
    print('❌ Валидация провалена. Исправь ошибки выше.');
    exit(1);
  } else {
    print('🎉 Валидация успешна! Все ссылки корректны.');
    exit(0);
  }
}

class Validator {
  final Set<String> itemIds = {};
  final Set<String> locationIds = {};
  final Set<String> conditionIds = {};

  int filesChecked = 0;
  int errorCount = 0;
  int warningCount = 0;

  // ═══════════════════════════════════════════════════════════
  // ЗАГРУЗКА СПРАВОЧНИКОВ
  // ═══════════════════════════════════════════════════════════

  void loadItemIds() {
    _loadIdsFromFile('assets/data/weapons.json', 'weapons', itemIds);
    _loadIdsFromFile('assets/data/tools.json', 'tools', itemIds);
    _loadIdsFromFile('assets/data/consumables.json', 'consumables', itemIds);
    _loadIdsFromFile('assets/data/armor.json', 'armor', itemIds);
    _loadIdsFromFile('assets/data/resources.json', 'resources', itemIds);

    itemIds.addAll([
      'molotov', 'torch', 'spear', 'fishing_rod', 'trap_snare',
      'water_filter', 'key', 'note', 'photo', 'binoculars',
      'ammo_box', '9mm', '357', 'shotgun_shell', '762',
      'pipe_bullet', 'arrow', 'bolt', 'flare', 'ammo',
      'lock_pick_crafted',
    ]);
  }

  void loadLocationIds() {
    final dir = Directory('assets/data/locations');
    if (!dir.existsSync()) {
      _error('Папка assets/data/locations не найдена');
      return;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (files.isEmpty) {
      _error('assets/data/locations: нет JSON-файлов');
      return;
    }

    for (final file in files) {
      _loadIdsFromFile(file.path, 'locations', locationIds);
    }
  }

  void loadConditionIds() {
    _loadIdsFromFile('assets/data/conditions.json', 'conditions', conditionIds);
  }

  void _loadIdsFromFile(String path, String key, Set<String> target) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        _error('Файл не найден: $path');
        return;
      }
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final list = json[key] as List?;
      if (list == null) {
        _error('Ключ "$key" не найден в $path');
        return;
      }
      for (final item in list) {
        final id = (item as Map)['id'] as String?;
        if (id != null) target.add(id);
      }
    } catch (e) {
      _error('Ошибка загрузки $path: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВАЛИДАЦИЯ СЮЖЕТА
  // ═══════════════════════════════════════════════════════════

  void validateAllStories() {
    const characters = ['boris', 'alina', 'ivan', 'andrey', 'darya'];

    for (final character in characters) {
      final storyDir = Directory('assets/data/story/$character/chapter_1');
      if (!storyDir.existsSync()) {
        _warn('Нет папки сюжета: assets/data/story/$character/chapter_1');
        continue;
      }

      // Проверяем, есть ли meta.json в новом формате
      final metaFile = File('${storyDir.path}/meta.json');
      if (!metaFile.existsSync()) {
        _warn('$character: нет meta.json — пропускаем');
        continue;
      }

      Map<String, dynamic> meta;
      try {
        meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      } catch (e) {
        _error('$character: ошибка парсинга meta.json — $e');
        continue;
      }

      // Если нет sequence — старый формат, пропускаем
      final sequence = meta['sequence'] as List?;
      if (sequence == null || sequence.isEmpty) {
        _warn('$character: старый формат (нет sequence) — пропускаем');
        continue;
      }

      _validateChapter(character, storyDir);
    }
  }

  void _validateChapter(String character, Directory dir) {
    print('  📖 $character');

    // === 1. Загружаем meta.json ===
    final metaFile = File('${dir.path}/meta.json');
    if (!metaFile.existsSync()) {
      _error('  Нет meta.json в ${dir.path}');
      return;
    }

    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('  Ошибка парсинга meta.json: $e');
      return;
    }

    // === 2. Читаем sequence ===
    final sequence = (meta['sequence'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    if (sequence.isEmpty) {
      _error('  meta.json: sequence пустой');
      return;
    }

    // === 3. Загружаем все акты и собираем ноды ===
    final Map<String, Map<String, dynamic>> allNodes = {};
    final Map<String, String> nodeToAct = {};
    final List<String> declaredActs = [];

    for (final step in sequence) {
      if (step['type'] != 'act') continue;

      final actId = step['id'] as String?;
      final fileName = step['file'] as String?;

      if (actId == null || fileName == null) {
        _error('  meta.json: act без id или file');
        continue;
      }

      declaredActs.add(actId);

      final actFile = File('${dir.path}/$fileName');
      if (!actFile.existsSync()) {
        _error('  $character/$actId: файл $fileName не найден');
        continue;
      }

      Map<String, dynamic> actJson;
      try {
        actJson = jsonDecode(actFile.readAsStringSync()) as Map<String, dynamic>;
        filesChecked++;
      } catch (e) {
        _error('  Ошибка парсинга $fileName: $e');
        continue;
      }

      // Проверка on_exit
      final onExit = actJson['on_exit'] as String?;
      if (onExit != null) {
        _validateOnExit(character, actId, onExit);
      }

      // Проверка start_node
      final startNode = actJson['start_node'] as String?;
      if (startNode == null) {
        _error('  $actId: нет "start_node"');
      }

      final nodes =
          (actJson['nodes'] as List? ?? []).cast<Map<String, dynamic>>();

      for (final node in nodes) {
        final id = node['id'] as String?;
        if (id == null) {
          _error('  $fileName: нода без "id"');
          continue;
        }
        if (allNodes.containsKey(id)) {
          _error(
            '  $fileName: дубликат id "$id" '
            '(уже в ${nodeToAct[id]})',
          );
          continue;
        }
        allNodes[id] = node;
        nodeToAct[id] = actId;
      }

      // Проверяем start_node после загрузки всех нод этого акта
      if (startNode != null && !allNodes.containsKey(startNode)) {
        _error('  $actId: start_node "$startNode" не найден');
      }
    }

    // === 4. Проверяем связи внутри актов ===
    for (final entry in allNodes.entries) {
      final id = entry.key;
      final node = entry.value;

      if (node['title'] == null) _error('  $id: нет "title"');
      if (node['text'] == null) _error('  $id: нет "text"');

      final choices =
          (node['choices'] as List? ?? []).cast<Map<String, dynamic>>();

      // auto_next
      final autoNext = node['auto_next'] as Map<String, dynamic>?;
      if (autoNext != null) {
        _validateAutoNext(id, autoNext, allNodes);
      }

      // choices
      for (int i = 0; i < choices.length; i++) {
        final choice = choices[i];

        final next = choice['next'] as String?;
        if (next == null) {
          _error('  $id: choice[$i] без "next"');
        } else if (!allNodes.containsKey(next)) {
          _error('  $id: choice[$i].next = "$next" → нода не найдена');
        }

        final effects = choice['effects'] as Map<String, dynamic>?;
        if (effects != null) {
          _validateEffects(id, i, effects, allNodes);
        }

        final requires = choice['requires'] as Map<String, dynamic>?;
        if (requires != null) {
          _validateRequires(id, i, requires);
        }
      }

      // Пустые choices
      if (choices.isEmpty && autoNext == null) {
        final isEnd = id.startsWith('END_');
        final isActEnd = id.endsWith('_end') || id.contains('_end_');
        if (!isEnd && !isActEnd) {
          _warn('  $id: нет choices и нет auto_next');
        }
      }
    }

    // === 5. Проверяем карты ===
    final mapsDir = Directory('${dir.path}/maps');
    final List<String> mapIds = [];

    for (final step in sequence) {
      if (step['type'] != 'map') continue;

      final mapId = step['id'] as String?;
      if (mapId == null) {
        _error('  meta.json: map без id');
        continue;
      }

      mapIds.add(mapId);

      final mapFile = File('${mapsDir.path}/$mapId.json');
      if (!mapFile.existsSync()) {
        _error('  $character/$mapId: файл maps/$mapId.json не найден');
        continue;
      }

      Map<String, dynamic> mapJson;
      try {
        mapJson = jsonDecode(mapFile.readAsStringSync()) as Map<String, dynamic>;
        filesChecked++;
      } catch (e) {
        _error('  Ошибка парсинга maps/$mapId.json: $e');
        continue;
      }

      _validateMap(mapId, mapJson);
    }

    // === 6. Проверяем side_quests ===
    final sideQuestsDir = Directory('${dir.path}/side_quests');
    final Set<String> sideQuestIds = {};

    for (final step in sequence) {
      final sqs = (step['side_quests'] as List? ?? []).cast<String>();
      sideQuestIds.addAll(sqs);
    }

    // Также из глобального списка
    final globalSQs = (meta['side_quests'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    for (final sq in globalSQs) {
      final id = sq['id'] as String?;
      if (id != null) sideQuestIds.add(id);
    }

    for (final sqId in sideQuestIds) {
      final sqFile = File('${sideQuestsDir.path}/$sqId.json');
      if (!sqFile.existsSync()) {
        _error('  $character: side_quests/$sqId.json не найден');
        continue;
      }

      try {
        final sqJson =
            jsonDecode(sqFile.readAsStringSync()) as Map<String, dynamic>;
        filesChecked++;
        _validateSideQuest(sqId, sqJson);
      } catch (e) {
        _error('  Ошибка парсинга side_quests/$sqId.json: $e');
      }
    }

    // === 7. Проверка: все END_* из meta.endings существуют ===
    final endings = (meta['endings'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    for (final ending in endings) {
      final id = ending['id'] as String?;
      if (id == null) continue;
      if (!allNodes.containsKey(id)) {
        _error('  meta.json: ending "$id" не найден среди нод');
      }
    }

    // === 8. Проверка: entry_location в шагах существуют ===
    for (final step in sequence) {
      if (step['type'] != 'act') continue;
      final entryLoc = step['entry_location'] as String?;
      if (entryLoc != null && !locationIds.contains(entryLoc)) {
        _error(
          '  meta.json: act "${step['id']}" entry_location = "$entryLoc" '
          '→ локация не найдена',
        );
      }
    }

    // === Итог по персонажу ===
    final errorsBefore = errorCount;

    if (errorCount == errorsBefore) {
      print('     ✅ ${allNodes.length} нод, '
          '${declaredActs.length} актов, '
          '${mapIds.length} карт, '
          '${sideQuestIds.length} квестов');
    } else {
      print('     ❌ ошибки выше');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА on_exit
  // ═══════════════════════════════════════════════════════════

  void _validateOnExit(String character, String actId, String onExit) {
    const validValues = {
      'return_to_map',
      'return_to_story',
      'chapter_end',
    };

    if (!validValues.contains(onExit)) {
      _error(
        '  $actId: on_exit = "$onExit" — недопустимо. '
        'Разрешено: $validValues',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА auto_next
  // ═══════════════════════════════════════════════════════════

  void _validateAutoNext(
    String nodeId,
    Map<String, dynamic> autoNext,
    Map<String, dynamic> allNodes,
  ) {
    final conditions =
        (autoNext['conditions'] as List? ?? []).cast<Map<String, dynamic>>();

    if (conditions.isEmpty) {
      _error('  $nodeId: auto_next без conditions');
      return;
    }

    bool hasDefault = false;

    for (int i = 0; i < conditions.length; i++) {
      final cond = conditions[i];

      final next = cond['next'] as String?;
      if (next == null) {
        _error('  $nodeId: auto_next[$i] без "next"');
        continue;
      }
      if (!allNodes.containsKey(next)) {
        _error('  $nodeId: auto_next[$i].next = "$next" → нода не найдена');
      }

      if (cond['default'] == true) {
        hasDefault = true;
        continue;
      }

      final ifCond = cond['if'] as Map<String, dynamic>?;
      if (ifCond == null) {
        _error('  $nodeId: auto_next[$i] без "if" или "default"');
      }
    }

    if (!hasDefault) {
      _warn('  $nodeId: auto_next без default-условия');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА effects
  // ═══════════════════════════════════════════════════════════

  void _validateEffects(
    String nodeId,
    int choiceIndex,
    Map<String, dynamic> effects,
    Map<String, dynamic> allNodes,
  ) {
    for (final key in ['combat_victory', 'combat_defeat', 'combat_flee']) {
      final target = effects[key] as String?;
      if (target != null && !allNodes.containsKey(target)) {
        _error(
          '  $nodeId: choice[$choiceIndex].effects.$key = "$target" '
          '→ нода не найдена',
        );
      }
    }

    final addIds = effects['inventory_add'] as List?;
    if (addIds != null) {
      for (final itemId in addIds.cast<String>()) {
        if (!itemIds.contains(itemId)) {
          _error(
            '  $nodeId: choice[$choiceIndex].inventory_add "$itemId" '
            '→ предмет не найден',
          );
        }
      }
    }

    final removeIds = effects['inventory_remove'] as List?;
    if (removeIds != null) {
      for (final itemId in removeIds.cast<String>()) {
        if (!itemIds.contains(itemId)) {
          _error(
            '  $nodeId: choice[$choiceIndex].inventory_remove "$itemId" '
            '→ предмет не найден',
          );
        }
      }
    }

    final infect = effects['infect'] as Map<String, dynamic>?;
    if (infect != null) {
      final source = infect['source'] as String?;
      if (source == null) {
        _error('  $nodeId: choice[$choiceIndex].infect без source');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА requires
  // ═══════════════════════════════════════════════════════════

  void _validateRequires(
    String nodeId,
    int choiceIndex,
    Map<String, dynamic> requires,
  ) {
    final hasItem = requires['has_item'] as String?;
    if (hasItem != null && !itemIds.contains(hasItem)) {
      _error(
        '  $nodeId: choice[$choiceIndex].requires.has_item = "$hasItem" '
        '→ предмет не найден',
      );
    }

    final notItem = requires['not_item'] as String?;
    if (notItem != null && !itemIds.contains(notItem)) {
      _error(
        '  $nodeId: choice[$choiceIndex].requires.not_item = "$notItem" '
        '→ предмет не найден',
      );
    }

    final stats = requires['stats'] as Map<String, dynamic>?;
    if (stats != null) {
      const validStats = {
        'hunger', 'thirst', 'health', 'sanity', 'stamina', 'fatigue',
        'intelligence', 'strength', 'cunning', 'endurance',
      };
      for (final key in stats.keys) {
        if (!validStats.contains(key)) {
          _error(
            '  $nodeId: choice[$choiceIndex].requires.stats.$key '
            '→ неизвестный стат',
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА карты
  // ═══════════════════════════════════════════════════════════

  void _validateMap(String mapId, Map<String, dynamic> mapJson) {
    // goal
    final goal = mapJson['goal'] as Map<String, dynamic>?;
    if (goal == null) {
      _error('  maps/$mapId.json: нет "goal"');
      return;
    }

    final type = goal['type'] as String?;
    if (type == null) {
      _error('  maps/$mapId.json: goal без "type"');
      return;
    }

    const validTypes = {
      'reach_location',
      'find_item',
      'survive_night',
      'custom_flag',
    };
    if (!validTypes.contains(type)) {
      _error('  maps/$mapId.json: goal.type = "$type" — неизвестный тип');
      return;
    }

    if (type == 'reach_location') {
      final target = goal['target'] as String?;
      if (target == null) {
        _error('  maps/$mapId.json: goal reach_location без target');
      } else if (!locationIds.contains(target)) {
        _error(
          '  maps/$mapId.json: goal.target = "$target" → локация не найдена',
        );
      }
    }

    if (type == 'find_item') {
      final target = goal['target'] as String?;
      if (target == null) {
        _error('  maps/$mapId.json: goal find_item без target');
      } else if (!itemIds.contains(target)) {
        _error(
          '  maps/$mapId.json: goal.target = "$target" → предмет не найден',
        );
      }
    }

    // on_complete живёт в meta.json (sequence), а не в файле карты.
    // entry_from_act / next_act — опциональны.
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА side_quest
  // ═══════════════════════════════════════════════════════════

  void _validateSideQuest(String sqId, Map<String, dynamic> sqJson) {
    // trigger
    final trigger = sqJson['trigger'] as Map<String, dynamic>?;
    if (trigger == null) {
      _error('  $sqId: нет "trigger"');
    } else {
      final locId = trigger['location_id'] as String?;
      if (locId == null) {
        _error('  $sqId: trigger без "location_id"');
      } else if (!locationIds.contains(locId)) {
        _error('  $sqId: trigger.location_id = "$locId" → локация не найдена');
      }
    }

    // steps
    final steps = (sqJson['steps'] as List? ?? []).cast<Map<String, dynamic>>();
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final stepType = step['type'] as String?;
      final target = step['target'] as String?;

      if (stepType == null) {
        _error('  $sqId: steps[$i] без "type"');
        continue;
      }

      if (target != null) {
        switch (stepType) {
          case 'reach_location':
            if (!locationIds.contains(target)) {
              _error(
                '  $sqId: steps[$i].target = "$target" → локация не найдена',
              );
            }
            break;
          case 'use_item':
          case 'give_item':
            if (!itemIds.contains(target)) {
              _error(
                '  $sqId: steps[$i].target = "$target" → предмет не найден',
              );
            }
            break;
        }
      }

      // requires в шаге
      final req = step['requires'] as Map<String, dynamic>?;
      if (req != null) {
        final hasItemOr =
            (req['has_item_or'] as List? ?? []).cast<String>();
        for (final itemId in hasItemOr) {
          if (!itemIds.contains(itemId)) {
            _error(
              '  $sqId: steps[$i].requires.has_item_or "$itemId" '
              '→ предмет не найден',
            );
          }
        }
      }
    }

    // outcomes
    final outcomes =
        (sqJson['outcomes'] as List? ?? []).cast<Map<String, dynamic>>();
    for (int i = 0; i < outcomes.length; i++) {
      final outcome = outcomes[i];
      final reward = outcome['reward'] as Map<String, dynamic>?;
      if (reward != null) {
        final items = (reward['items'] as List? ?? []).cast<String>();
        for (final itemId in items) {
          if (!itemIds.contains(itemId)) {
            _error(
              '  $sqId: outcomes[$i].reward.items "$itemId" '
              '→ предмет не найден',
            );
          }
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВАЛИДАЦИЯ ЛОКАЦИЙ
  // ═══════════════════════════════════════════════════════════

  void validateLocations() {
    final dir = Directory('assets/data/locations');
    if (!dir.existsSync()) {
      _error('Папка assets/data/locations не найдена');
      return;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    int totalLocations = 0;
    int totalErrors = 0;

    for (final file in files) {
      try {
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final locations =
            (json['locations'] as List).cast<Map<String, dynamic>>();

        filesChecked++;
        final fileName = file.path.split('/').last;

        for (final loc in locations) {
          totalLocations++;
          final id = loc['id'] as String? ?? '<без id>';

          // connections
          final connections = (loc['connections'] as List? ?? []);
          for (final conn in connections) {
            String? target;
            if (conn is String) {
              target = conn;
            } else if (conn is Map) {
              target = conn['id'] as String?;
            }

            if (target != null && !locationIds.contains(target)) {
              _error('$fileName/$id: connections → "$target" не найдена');
              totalErrors++;
            }
          }

          // loot_pool
          final lootPool = (loc['loot_pool'] as List? ?? []).cast<String>();
          for (final item in lootPool) {
            if (!itemIds.contains(item)) {
              _error('$fileName/$id: loot_pool → "$item" не найден');
              totalErrors++;
            }
          }

          // unlocked_by
          final unlockedBy = loc['unlocked_by'] as String?;
          if (unlockedBy != null && !locationIds.contains(unlockedBy)) {
            _error('$fileName/$id: unlocked_by → "$unlockedBy" не найдена');
            totalErrors++;
          }

          // mapPosition
          if (loc['mapPosition'] == null) {
            _warn('$fileName/$id: нет mapPosition');
          }

          // search_events
          final events = (loc['search_events'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          for (int i = 0; i < events.length; i++) {
            final effect = events[i]['effect'] as Map<String, dynamic>?;
            if (effect == null) continue;

            final unlock = effect['unlock_location'] as String?;
            if (unlock != null &&
                unlock != 'auto' &&
                !locationIds.contains(unlock)) {
              _error(
                '$fileName/$id: search_events[$i].unlock_location '
                '= "$unlock" не найдена',
              );
              totalErrors++;
            }

            final loot = (effect['random_loot'] as List? ?? []).cast<String>();
            for (final item in loot) {
              if (!itemIds.contains(item)) {
                _error(
                  '$fileName/$id: search_events[$i].random_loot '
                  '→ "$item" не найден',
                );
                totalErrors++;
              }
            }

            // scout_location
            final scoutLocation = effect['scout_location'];
            if (scoutLocation is String) {
              if (!locationIds.contains(scoutLocation)) {
                _error(
                  '$fileName/$id: search_events[$i].scout_location '
                  '= "$scoutLocation" не найдена',
                );
                totalErrors++;
              }
            } else if (scoutLocation is List) {
              for (final locId in scoutLocation.cast<String>()) {
                if (!locationIds.contains(locId)) {
                  _error(
                    '$fileName/$id: search_events[$i].scout_location '
                    '→ "$locId" не найдена',
                  );
                  totalErrors++;
                }
              }
            }
          }
        }
      } catch (e) {
        _error('Ошибка парсинга ${file.path}: $e');
      }
    }

    if (totalErrors == 0) {
      print('  ✅ $totalLocations локаций в ${files.length} файлах');
    } else {
      print('  ❌ $totalLocations локаций, $totalErrors ошибок');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВАЛИДАЦИЯ РЕЦЕПТОВ
  // ═══════════════════════════════════════════════════════════

  void validateRecipes() {
    final file = File('assets/data/recipes.json');
    if (!file.existsSync()) {
      _error('recipes.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга recipes.json: $e');
      return;
    }

    final recipes = (json['recipes'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final recipe in recipes) {
      final id = recipe['id'] as String? ?? '<без id>';
      final resultId = recipe['result_id'] as String?;

      if (resultId != null && !itemIds.contains(resultId)) {
        _error('Рецепт "$id": result_id "$resultId" не в справочнике');
        errors++;
      }

      final ingredients =
          (recipe['ingredients'] as List? ?? []).cast<Map<String, dynamic>>();
      for (int i = 0; i < ingredients.length; i++) {
        final ingId = ingredients[i]['id'] as String?;
        if (ingId == null) {
          _error('Рецепт "$id": ingredients[$i] без id');
          errors++;
        } else if (!itemIds.contains(ingId)) {
          _error('Рецепт "$id": ingredients[$i].id = "$ingId" не найден');
          errors++;
        }
      }
    }

    if (errors == 0) {
      print('  ✅ ${recipes.length} рецептов');
    } else {
      print('  ❌ ${recipes.length} рецептов, $errors ошибок');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВАЛИДАЦИЯ СОСТОЯНИЙ
  // ═══════════════════════════════════════════════════════════

  void validateConditions() {
    final file = File('assets/data/conditions.json');
    if (!file.existsSync()) {
      _error('conditions.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга conditions.json: $e');
      return;
    }

    final conditions = (json['conditions'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final cond in conditions) {
      final id = cond['id'] as String? ?? '<без id>';
      final cureItems = (cond['cure_items'] as List? ?? []).cast<String>();

      for (final item in cureItems) {
        if (!itemIds.contains(item)) {
          _error('Состояние "$id": cure_items → "$item" не найден');
          errors++;
        }
      }
    }

    if (errors == 0) {
      print('  ✅ ${conditions.length} состояний');
    } else {
      print('  ❌ ${conditions.length} состояний, $errors ошибок');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВАЛИДАЦИЯ СОБЫТИЙ ПОИСКА
  // ═══════════════════════════════════════════════════════════

  void validateSearchEvents() {
    final file = File('assets/data/search_events.json');
    if (!file.existsSync()) {
      _error('search_events.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга search_events.json: $e');
      return;
    }

    final events = (json['events'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final event in events) {
      final id = event['id'] as String? ?? '<без id>';
      final chance = event['chance'];
      if (chance == null) {
        _error('Событие "$id": нет chance');
        errors++;
      } else if ((chance as num) < 0 || chance > 1) {
        _error('Событие "$id": chance=$chance вне [0,1]');
        errors++;
      }

      final effect = event['effect'] as Map<String, dynamic>?;
      if (effect == null) continue;

      final unlock = effect['unlock_location'] as String?;
      if (unlock != null &&
          unlock != 'auto' &&
          !locationIds.contains(unlock)) {
        _error('Событие "$id": unlock_location "$unlock" не найдена');
        errors++;
      }

      final loot = (effect['random_loot'] as List? ?? []).cast<String>();
      for (final item in loot) {
        if (!itemIds.contains(item)) {
          _error('Событие "$id": random_loot → "$item" не найден');
          errors++;
        }
      }
    }

    if (errors == 0) {
      print('  ✅ ${events.length} событий');
    } else {
      print('  ❌ ${events.length} событий, $errors ошибок');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВАЛИДАЦИЯ ДОСТИЖЕНИЙ
  // ═══════════════════════════════════════════════════════════

  void validateAchievements() {
    final file = File('assets/data/achievements.json');
    if (!file.existsSync()) {
      _error('achievements.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга achievements.json: $e');
      return;
    }

    const validCategories = {
      'combat', 'survival', 'story', 'crafting', 'loot', 'medicine',
    };

    final achievements =
        (json['achievements'] as List).cast<Map<String, dynamic>>();
    int errors = 0;
    final ids = <String>{};

    for (final ach in achievements) {
      final id = ach['id'] as String? ?? '<без id>';
      if (ids.contains(id)) {
        _error('Достижение "$id": дубликат id');
        errors++;
      }
      ids.add(id);

      final category = ach['category'] as String?;
      if (category != null && !validCategories.contains(category)) {
        _warn('Достижение "$id": неизвестная категория "$category"');
      }
    }

    if (errors == 0) {
      print('  ✅ ${achievements.length} достижений');
    } else {
      print('  ❌ ${achievements.length} достижений, $errors ошибок');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕРЫ
  // ═══════════════════════════════════════════════════════════

  void _error(String message) {
    print('  ❌ $message');
    errorCount++;
  }

  void _warn(String message) {
    print('  ⚠️  $message');
    warningCount++;
  }
}
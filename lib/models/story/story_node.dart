import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Условия для выбора в ноде
class ChoiceRequirements {
  final Map<String, dynamic>? stats;
  final String? hasItem;
  final String? notItem;
  final String? flag;
  final String? notFlag;

  const ChoiceRequirements({
    this.stats,
    this.hasItem,
    this.notItem,
    this.flag,
    this.notFlag,
  });

  factory ChoiceRequirements.fromJson(Map<String, dynamic> json) {
    return ChoiceRequirements(
      stats: json['stats'],
      hasItem: json['has_item'],
      notItem: json['not_item'],
      flag: json['flag'],
      notFlag: json['not_flag'],
    );
  }
}

class StoryChoice {
  final String text;
  final Map<String, dynamic>? effects;
  final String next;
  final ChoiceRequirements? requires;

  const StoryChoice({
    required this.text,
    required this.next,
    this.effects,
    this.requires,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'],
      effects: json['effects'],
      next: json['next'],
      requires: json['requires'] != null
          ? ChoiceRequirements.fromJson(
              Map<String, dynamic>.from(json['requires']),
            )
          : null,
    );
  }

  /// Проверить, доступен ли этот выбор игроку
  bool isAvailable({
    required Map<String, int> stats,
    required Set<String> inventoryIds,
    required Set<String> flags,
  }) {
    if (requires == null) return true;

    final req = requires!;

    // Проверка ресурсов
    if (req.stats != null) {
      for (final entry in req.stats!.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;
        final currentValue = stats[statName] ?? 0;

        if (condition['min'] != null && currentValue < condition['min']) {
          return false;
        }
        if (condition['max'] != null && currentValue > condition['max']) {
          return false;
        }
      }
    }

    // Проверка предметов
    if (req.hasItem != null && !inventoryIds.contains(req.hasItem)) {
      return false;
    }
    if (req.notItem != null && inventoryIds.contains(req.notItem)) {
      return false;
    }

    // Проверка флагов
    if (req.flag != null && !flags.contains(req.flag)) {
      return false;
    }
    if (req.notFlag != null && flags.contains(req.notFlag)) {
      return false;
    }

    return true;
  }

  /// Получить причину, почему выбор недоступен
  String? getUnavailableReason({
    required Map<String, int> stats,
    required Set<String> inventoryIds,
    required Set<String> flags,
  }) {
    if (requires == null) return null;

    final req = requires!;

    if (req.stats != null) {
      for (final entry in req.stats!.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;
        final currentValue = stats[statName] ?? 0;

        if (condition['min'] != null && currentValue < condition['min']) {
          return 'Требуется $statName ≥ ${condition['min']}';
        }
        if (condition['max'] != null && currentValue > condition['max']) {
          return 'Требуется $statName ≤ ${condition['max']}';
        }
      }
    }

    if (req.hasItem != null) return 'Нужен предмет';
    if (req.notItem != null) return 'Предмет мешает';
    if (req.flag != null) return 'Нужна предыстория';
    if (req.notFlag != null) return 'Предыстория мешает';

    return null;
  }
}

class StoryNode {
  final String id;
  final String title;
  final String text;
  final List<StoryChoice> choices;
  final Map<String, dynamic>? onEnter;
  final Map<String, dynamic>? flagsSet;

  const StoryNode({
    required this.id,
    required this.title,
    required this.text,
    required this.choices,
    this.onEnter,
    this.flagsSet,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'],
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      choices: (json['choices'] as List? ?? [])
          .map((c) => StoryChoice.fromJson(c))
          .toList(),
      onEnter: json['on_enter'],
      flagsSet: json['flags_set'],
    );
  }
}

/// Акт — часть главы
class StoryAct {
  final int number;
  final String id;
  final String title;
  final String file;
  final String? startNode;
  final List<String> entryNodes;
  final String? description;

  const StoryAct({
    required this.number,
    required this.id,
    required this.title,
    required this.file,
    this.startNode,
    this.entryNodes = const [],
    this.description,
  });

  factory StoryAct.fromJson(Map<String, dynamic> json) {
    return StoryAct(
      number: json['number'] ?? 0,
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      file: json['file'] ?? '',
      startNode: json['start_node'],
      entryNodes: json['entry_nodes'] != null
          ? List<String>.from(json['entry_nodes'])
          : [],
      description: json['description'],
    );
  }
}

/// Концовка главы
class StoryEnding {
  final String id;
  final String title;
  final String description;

  const StoryEnding({
    required this.id,
    required this.title,
    required this.description,
  });

  factory StoryEnding.fromJson(Map<String, dynamic> json) {
    return StoryEnding(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

/// Вся глава целиком — собранная из meta + актов
class Story {
  final String character;
  final String characterName;
  final int chapter;
  final String title;
  final String subtitle;
  final String description;
  final List<StoryAct> acts;
  final List<StoryEnding> endings;
  final int totalNodes;
  final int estimatedMinutes;
  final Map<String, StoryNode> nodes;

  const Story({
    required this.character,
    required this.characterName,
    required this.chapter,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.acts,
    required this.endings,
    required this.totalNodes,
    required this.estimatedMinutes,
    required this.nodes,
  });

  StoryNode? getNode(String id) => nodes[id];

  /// Первая нода главы
  String get startNodeId {
    if (acts.isNotEmpty && acts.first.startNode != null) {
      return acts.first.startNode!;
    }
    return '';
  }

  /// Найти номер акта, в котором находится нода
  int? getActForNode(String nodeId) {
    for (final act in acts) {
      if (act.startNode == nodeId) return act.number;
      if (act.entryNodes.contains(nodeId)) return act.number;
    }
    return null;
  }

  /// Получить следующий акт по текущему
  StoryAct? getNextAct(int currentActNumber) {
    final currentIndex =
        acts.indexWhere((a) => a.number == currentActNumber);
    if (currentIndex < 0 || currentIndex + 1 >= acts.length) {
      return null;
    }
    return acts[currentIndex + 1];
  }

  /// Загрузить главу по персонажу и номеру главы
  /// Формат: assets/data/story/{character}/chapter_{N}/meta.json
  static Future<Story?> loadFor(
    String characterId, {
    int chapter = 1,
  }) async {
    try {
      // 1. Загружаем meta.json
      final String metaPath =
          'assets/data/story/$characterId/chapter_$chapter/meta.json';
      debugPrint('📖 Story.loadFor: загрузка $metaPath');

      final String metaJsonString = await rootBundle.loadString(metaPath);
      final Map<String, dynamic> metaMap = json.decode(metaJsonString);

      // 2. Парсим акты и концовки
      final List<StoryAct> acts = (metaMap['acts'] as List? ?? [])
          .map((a) => StoryAct.fromJson(Map<String, dynamic>.from(a)))
          .toList();

      final List<StoryEnding> endings = (metaMap['endings'] as List? ?? [])
          .map((e) => StoryEnding.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      debugPrint('📖 Story.loadFor: найдено ${acts.length} актов');

      // 3. Загружаем все акты и сливаем ноды в один словарь
      final Map<String, StoryNode> allNodes = {};
      final Map<String, String> nodeSource = {}; // id → акт (для диагностики)

      int totalDuplicates = 0;

      for (final act in acts) {
        try {
          final String actPath =
              'assets/data/story/$characterId/chapter_$chapter/${act.file}';

          debugPrint('📖 Story.loadFor: загрузка акта ${act.file}');

          final String actJsonString = await rootBundle.loadString(actPath);
          final Map<String, dynamic> actMap = json.decode(actJsonString);

          final List<dynamic> nodesJson = actMap['nodes'] ?? [];
          debugPrint(
            '📖 Story.loadFor: акт ${act.file} содержит ${nodesJson.length} нод',
          );

          int nodesAdded = 0;
          int duplicates = 0;

          for (final nodeJson in nodesJson) {
            final node = StoryNode.fromJson(
              Map<String, dynamic>.from(nodeJson),
            );

            if (allNodes.containsKey(node.id)) {
              duplicates++;
              totalDuplicates++;
              debugPrint(
                '❌ Story.loadFor: ДУБЛИКАТ ноды "${node.id}" — '
                'уже загружена из ${nodeSource[node.id]}, '
                'сейчас пришла из ${act.file}',
              );
            } else {
              allNodes[node.id] = node;
              nodeSource[node.id] = act.file;
              nodesAdded++;
            }
          }

          debugPrint(
            '✅ Story.loadFor: акт ${act.file} загружен — '
            '$nodesAdded новых нод, $duplicates дубликатов',
          );
        } catch (e, stackTrace) {
          debugPrint(
            '❌ Story.loadFor: ОШИБКА загрузки акта ${act.file}: $e',
          );
          debugPrint('📍 Stack trace:\n$stackTrace');
        }
      }

      debugPrint(
        '📖 Story.loadFor: всего загружено ${allNodes.length} нод, '
        'дубликатов: $totalDuplicates',
      );

      if (totalDuplicates > 0) {
        debugPrint(
          '⚠️ ОБНАРУЖЕНЫ ДУБЛИКАТЫ — проверь структуру актов! '
          'Возможно, END_* ноды находятся и в act_1, и в act_3.',
        );
      }

      return Story(
        character: metaMap['character'] ?? characterId,
        characterName: metaMap['character_name'] ?? characterId,
        chapter: metaMap['chapter'] ?? chapter,
        title: metaMap['title'] ?? '',
        subtitle: metaMap['subtitle'] ?? '',
        description: metaMap['description'] ?? '',
        acts: acts,
        endings: endings,
        totalNodes: metaMap['total_nodes'] ?? allNodes.length,
        estimatedMinutes: metaMap['estimated_minutes'] ?? 0,
        nodes: allNodes,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Story.loadFor: КРИТИЧЕСКАЯ ОШИБКА: $e');
      debugPrint('📍 Stack trace:\n$stackTrace');
      return null;
    }
  }

  /// Обратная совместимость со старым форматом
  static Future<Story?> loadLegacy(String characterId) async {
    try {
      debugPrint('📖 Story.loadLegacy: загрузка $characterId');

      final String jsonString = await rootBundle
          .loadString('assets/data/story_$characterId.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final Map<String, StoryNode> nodesMap = {};
      for (final nodeJson in jsonMap['nodes']) {
        final node = StoryNode.fromJson(nodeJson);
        nodesMap[node.id] = node;
      }

      return Story(
        character: characterId,
        characterName: characterId,
        chapter: jsonMap['chapter'] ?? 1,
        title: 'Тёмные часы',
        subtitle: '',
        description: '',
        acts: [
          StoryAct(
            number: 1,
            id: 'legacy',
            title: 'Глава 1',
            file: 'story_$characterId.json',
            startNode: jsonMap['start_node'],
          ),
        ],
        endings: [],
        totalNodes: nodesMap.length,
        estimatedMinutes: 0,
        nodes: nodesMap,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Story.loadLegacy: ошибка: $e');
      debugPrint('📍 Stack trace:\n$stackTrace');
      return null;
    }
  }

  /// Универсальная загрузка: пробуем новый формат, откатываемся к старому
  static Future<Story?> load(String characterId, {int chapter = 1}) async {
    final newStory = await loadFor(characterId, chapter: chapter);
    if (newStory != null) return newStory;

    debugPrint(
      '⚠️ Story.load: новый формат не загрузился, '
      'пробуем legacy для $characterId',
    );
    return await loadLegacy(characterId);
  }
}
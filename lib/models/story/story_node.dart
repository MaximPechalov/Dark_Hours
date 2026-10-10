import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:dark_hours/models/story/story_sequence.dart';

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

  bool isAvailable({
    required Map<String, int> stats,
    required Set<String> inventoryIds,
    required Set<String> flags,
  }) {
    if (requires == null) return true;

    final req = requires!;

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

    if (req.hasItem != null && !inventoryIds.contains(req.hasItem)) {
      return false;
    }
    if (req.notItem != null && inventoryIds.contains(req.notItem)) {
      return false;
    }

    if (req.flag != null && !flags.contains(req.flag)) {
      return false;
    }
    if (req.notFlag != null && flags.contains(req.notFlag)) {
      return false;
    }

    return true;
  }

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

  /// Служебная нода — авто-переход по флагам.
  final Map<String, dynamic>? autoNext;

  /// Действие при выходе из ноды.
  final String? onExit;

  const StoryNode({
    required this.id,
    required this.title,
    required this.text,
    required this.choices,
    this.onEnter,
    this.flagsSet,
    this.autoNext,
    this.onExit,
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
      autoNext: json['auto_next'] != null
          ? Map<String, dynamic>.from(json['auto_next'])
          : null,
      onExit: json['on_exit'] as String?,
    );
  }

  bool get isEnd => id.startsWith('END_');
  bool get hasAutoNext => autoNext != null;
  bool get hasOnExit => onExit != null;
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
  final String? onExit;

  const StoryAct({
    required this.number,
    required this.id,
    required this.title,
    required this.file,
    this.startNode,
    this.entryNodes = const [],
    this.description,
    this.onExit,
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
      onExit: json['on_exit'] as String?,
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

/// Вся глава целиком — собранная из meta + актов.
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

  String get startNodeId {
    if (acts.isNotEmpty && acts.first.startNode != null) {
      return acts.first.startNode!;
    }
    return '';
  }

  int? getActForNode(String nodeId) {
    for (final act in acts) {
      if (act.startNode == nodeId) return act.number;
      if (act.entryNodes.contains(nodeId)) return act.number;
    }
    return null;
  }

  StoryAct? getNextAct(int currentActNumber) {
    final currentIndex =
        acts.indexWhere((a) => a.number == currentActNumber);
    if (currentIndex < 0 || currentIndex + 1 >= acts.length) {
      return null;
    }
    return acts[currentIndex + 1];
  }

  // ═══════════════════════════════════════════════════════════
  // ЗАГРУЗКА
  // ═══════════════════════════════════════════════════════════

  /// Загрузить главу по персонажу и номеру главы.
  ///
  /// Формат: `assets/data/story/{character}/chapter_{N}/meta.json`.
  ///
  /// **Поддерживает два формата `meta.json`:**
  /// 1. **Новый** — `sequence`: массив шагов, где `type: "act"` — акт.
  /// 2. **Старый** — `acts`: массив актов напрямую.
  ///
  /// Новый формат — **приоритетный**. Если `sequence` есть — используем его.
  static Future<Story?> loadFor(
    String characterId, {
    int chapter = 1,
  }) async {
    try {
      final String metaPath =
          'assets/data/story/$characterId/chapter_$chapter/meta.json';
      debugPrint('📖 Story.loadFor: загрузка $metaPath');

      final String metaJsonString = await rootBundle.loadString(metaPath);
      final Map<String, dynamic> metaMap = json.decode(metaJsonString);

      // ═══════════════════════════════════════════════════════════
      // ОПРЕДЕЛЯЕМ ФОРМАТ
      // ═══════════════════════════════════════════════════════════

      final List<dynamic> sequenceJson =
          (metaMap['sequence'] as List?) ?? [];
      final List<dynamic> actsJson = (metaMap['acts'] as List?) ?? [];

      List<StoryAct> acts = [];
      int actNumber = 0;

      if (sequenceJson.isNotEmpty) {
        // НОВЫЙ ФОРМАТ — из sequence
        debugPrint(
          '📖 Story.loadFor: новый формат, ${sequenceJson.length} шагов',
        );

        for (final step in sequenceJson) {
          final stepMap = Map<String, dynamic>.from(step);
          if (stepMap['type'] != 'act') continue;

          actNumber++;

          // start_node может быть в самом шаге
          final startNode = stepMap['start_node'] as String?;

          acts.add(StoryAct(
            number: actNumber,
            id: stepMap['id'] as String? ?? 'act_$actNumber',
            title: stepMap['title'] as String? ?? '',
            file: stepMap['file'] as String? ?? '',
            startNode: startNode,
            entryNodes: stepMap['entry_nodes'] != null
                ? List<String>.from(stepMap['entry_nodes'])
                : [],
            description: stepMap['description'] as String?,
            onExit: stepMap['on_exit'] as String?,
          ));
        }
      } else if (actsJson.isNotEmpty) {
        // СТАРЫЙ ФОРМАТ — из acts
        debugPrint(
          '📖 Story.loadFor: старый формат, ${actsJson.length} актов',
        );

        acts = actsJson
            .map((a) => StoryAct.fromJson(Map<String, dynamic>.from(a)))
            .toList();
      } else {
        debugPrint('❌ Story.loadFor: нет ни sequence, ни acts');
        return null;
      }

      final List<StoryEnding> endings = (metaMap['endings'] as List? ?? [])
          .map((e) => StoryEnding.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      debugPrint('📖 Story.loadFor: найдено ${acts.length} актов');

      // ═══════════════════════════════════════════════════════════
      // ЗАГРУЖАЕМ НОДЫ ИЗ ВСЕХ АКТОВ
      // ═══════════════════════════════════════════════════════════

      final Map<String, StoryNode> allNodes = {};
      final Map<String, String> nodeSource = {};
      int totalDuplicates = 0;

      for (final act in acts) {
        if (act.file.isEmpty) {
          debugPrint('⚠️ Story.loadFor: акт ${act.id} без file');
          continue;
        }

        try {
          final String actPath =
              'assets/data/story/$characterId/chapter_$chapter/${act.file}';

          debugPrint('📖 Story.loadFor: загрузка ${act.file}');

          final String actJsonString = await rootBundle.loadString(actPath);
          final Map<String, dynamic> actMap = json.decode(actJsonString);

          // start_node и on_exit из самого файла акта
          final fileStartNode = actMap['start_node'] as String?;
          final fileOnExit = actMap['on_exit'] as String?;

          // Если start_node не был в sequence — берём из файла
          if (act.startNode == null && fileStartNode != null) {
            final idx = acts.indexWhere((a) => a.id == act.id);
            if (idx >= 0) {
              acts[idx] = StoryAct(
                number: act.number,
                id: act.id,
                title: act.title,
                file: act.file,
                startNode: fileStartNode,
                entryNodes: act.entryNodes,
                description: act.description,
                onExit: fileOnExit ?? act.onExit,
              );
            }
          }

          final List<dynamic> nodesJson = actMap['nodes'] ?? [];
          debugPrint(
            '📖 Story.loadFor: ${act.file} содержит ${nodesJson.length} нод',
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
                '❌ Story.loadFor: ДУБЛИКАТ "${node.id}" — '
                'уже из ${nodeSource[node.id]}, сейчас из ${act.file}',
              );
            } else {
              allNodes[node.id] = node;
              nodeSource[node.id] = act.file;
              nodesAdded++;
            }
          }

          debugPrint(
            '✅ Story.loadFor: ${act.file} — $nodesAdded нод, '
            '$duplicates дубликатов',
          );
        } catch (e, stackTrace) {
          debugPrint(
            '❌ Story.loadFor: ОШИБКА загрузки ${act.file}: $e',
          );
          debugPrint('📍 $stackTrace');
        }
      }

      debugPrint(
        '📖 Story.loadFor: всего ${allNodes.length} нод, '
        'дубликатов: $totalDuplicates',
      );

      // ═══════════════════════════════════════════════════════════
      // ВАЛИДАЦИЯ: есть ли ноды вообще
      // ═══════════════════════════════════════════════════════════

      if (allNodes.isEmpty) {
        debugPrint('❌ Story.loadFor: ноды не загружены!');
        return null;
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
      debugPrint('📍 $stackTrace');
      return null;
    }
  }

  /// Загрузить последовательность главы (новый формат).
  static Future<StorySequence?> loadSequence(
    String characterId, {
    int chapter = 1,
  }) async {
    return StorySequence.load(characterId, chapter: chapter);
  }

  /// Обратная совместимость — старый формат `story_$characterId.json`.
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
      debugPrint('📍 $stackTrace');
      return null;
    }
  }

  /// Универсальная загрузка: пробуем новый формат, откатываемся к старому.
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
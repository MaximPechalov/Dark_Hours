import 'map_goal.dart';

/// Один шаг в последовательности главы.
///
/// Может быть:
/// - `act` — сюжетный акт (открыть StoryScreen).
/// - `map` — карта (открыть MapScreen с целью).
enum ChapterStepType {
  act,
  map,
}

class ChapterStep {
  final ChapterStepType type;
  final String id;
  final String title;
  final String? description;
  final String? file;

  // Для актов
  final String? entryLocation;
  final String? entryFlag;

  // Для карт
  final MapGoal? goal;
  final List<String> sideQuests;
  final String? onCompleteFlag;

  const ChapterStep({
    required this.type,
    required this.id,
    required this.title,
    this.description,
    this.file,
    this.entryLocation,
    this.entryFlag,
    this.goal,
    this.sideQuests = const [],
    this.onCompleteFlag,
  });

  factory ChapterStep.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = typeStr == 'act' ? ChapterStepType.act : ChapterStepType.map;

    MapGoal? goal;
    if (json['goal'] != null) {
      goal = MapGoal.fromJson(
        Map<String, dynamic>.from(json['goal']),
      );
    }

    String? onCompleteFlag;
    final onComplete = json['on_complete'] as Map<String, dynamic>?;
    if (onComplete != null) {
      onCompleteFlag = onComplete['flag_set'] as String?;
    }

    return ChapterStep(
      type: type,
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      file: json['file'] as String?,
      entryLocation: json['entry_location'] as String?,
      entryFlag: json['entry_flag'] as String?,
      goal: goal,
      sideQuests: (json['side_quests'] as List? ?? []).cast<String>(),
      onCompleteFlag: onCompleteFlag,
    );
  }

  bool get isAct => type == ChapterStepType.act;
  bool get isMap => type == ChapterStepType.map;
}
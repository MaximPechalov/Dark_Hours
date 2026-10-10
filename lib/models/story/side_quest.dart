/// Побочный квест — опциональное задание на карте.
class SideQuest {
  final String id;
  final String title;
  final String description;
  final SideQuestTrigger trigger;
  final List<SideQuestStep> steps;
  final List<SideQuestOutcome> outcomes;
  final SideQuestExpiry? expiresOn;

  const SideQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.trigger,
    required this.steps,
    required this.outcomes,
    this.expiresOn,
  });

  factory SideQuest.fromJson(Map<String, dynamic> json) {
    return SideQuest(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      trigger: SideQuestTrigger.fromJson(
        Map<String, dynamic>.from(json['trigger'] ?? {}),
      ),
      steps: (json['steps'] as List? ?? [])
          .map((s) => SideQuestStep.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      outcomes: (json['outcomes'] as List? ?? [])
          .map((o) => SideQuestOutcome.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
      expiresOn: json['expires_on'] != null
          ? SideQuestExpiry.fromJson(
              Map<String, dynamic>.from(json['expires_on']),
            )
          : null,
    );
  }

  /// Найти исход, который подходит по условиям.
  SideQuestOutcome? resolveOutcome({
    required Set<String> flags,
    required Set<String> inventoryIds,
  }) {
    for (final outcome in outcomes) {
      if (outcome.matches(flags: flags, inventoryIds: inventoryIds)) {
        return outcome;
      }
    }
    return null;
  }
}

/// Триггер — когда квест активируется.
class SideQuestTrigger {
  final String locationId;
  final String event; // on_enter
  final String? hint;
  final Map<String, dynamic>? condition;

  const SideQuestTrigger({
    required this.locationId,
    required this.event,
    this.hint,
    this.condition,
  });

  factory SideQuestTrigger.fromJson(Map<String, dynamic> json) {
    return SideQuestTrigger(
      locationId: json['location_id'] as String? ?? '',
      event: json['event'] as String? ?? 'on_enter',
      hint: json['hint'] as String?,
      condition: json['condition'] as Map<String, dynamic>?,
    );
  }
}

/// Шаг квеста.
class SideQuestStep {
  final String id;
  final String type;
  final String? target;
  final String? hint;
  final bool optional;
  final Map<String, dynamic>? requires;
  final Map<String, dynamic>? onComplete;

  const SideQuestStep({
    required this.id,
    required this.type,
    this.target,
    this.hint,
    this.optional = false,
    this.requires,
    this.onComplete,
  });

  factory SideQuestStep.fromJson(Map<String, dynamic> json) {
    return SideQuestStep(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      target: json['target'] as String?,
      hint: json['hint'] as String?,
      optional: json['optional'] as bool? ?? false,
      requires: json['requires'] as Map<String, dynamic>?,
      onComplete: json['on_complete'] as Map<String, dynamic>?,
    );
  }

  String? get completionFlag {
    return onComplete?['flag_set'] as String?;
  }
}

/// Исход квеста — что происходит, если условия выполнены.
class SideQuestOutcome {
  final String id;
  final Map<String, dynamic> condition;
  final String? flagSet;
  final SideQuestReward? reward;
  final SideQuestPenalty? penalty;

  const SideQuestOutcome({
    required this.id,
    required this.condition,
    this.flagSet,
    this.reward,
    this.penalty,
  });

  factory SideQuestOutcome.fromJson(Map<String, dynamic> json) {
    return SideQuestOutcome(
      id: json['id'] as String? ?? '',
      condition: Map<String, dynamic>.from(json['condition'] ?? {}),
      flagSet: json['flag_set'] as String?,
      reward: json['reward'] != null
          ? SideQuestReward.fromJson(
              Map<String, dynamic>.from(json['reward']),
            )
          : null,
      penalty: json['penalty'] != null
          ? SideQuestPenalty.fromJson(
              Map<String, dynamic>.from(json['penalty']),
            )
          : null,
    );
  }

  /// Подходит ли исход по текущим условиям?
  bool matches({
    required Set<String> flags,
    required Set<String> inventoryIds,
  }) {
    final flagsAll = (condition['flags_all'] as List? ?? []).cast<String>();
    for (final f in flagsAll) {
      if (!flags.contains(f)) return false;
    }

    final flagsNot = (condition['flags_not'] as List? ?? []).cast<String>();
    for (final f in flagsNot) {
      if (flags.contains(f)) return false;
    }

    final hasItems = (condition['has_items'] as List? ?? []).cast<String>();
    for (final item in hasItems) {
      if (!inventoryIds.contains(item)) return false;
    }

    return true;
  }
}

/// Награда за квест.
class SideQuestReward {
  final List<String> items;
  final int sanity;
  final String? message;

  const SideQuestReward({
    this.items = const [],
    this.sanity = 0,
    this.message,
  });

  factory SideQuestReward.fromJson(Map<String, dynamic> json) {
    return SideQuestReward(
      items: (json['items'] as List? ?? []).cast<String>(),
      sanity: json['sanity'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

/// Штраф за квест.
class SideQuestPenalty {
  final int sanity;
  final String? message;

  const SideQuestPenalty({
    this.sanity = 0,
    this.message,
  });

  factory SideQuestPenalty.fromJson(Map<String, dynamic> json) {
    return SideQuestPenalty(
      sanity: json['sanity'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

/// Когда квест "истекает" — если не выполнить.
class SideQuestExpiry {
  final String flagSet;
  final String? message;

  const SideQuestExpiry({
    required this.flagSet,
    this.message,
  });

  factory SideQuestExpiry.fromJson(Map<String, dynamic> json) {
    return SideQuestExpiry(
      flagSet: json['flag_set'] as String? ?? '',
      message: json['message'] as String?,
    );
  }
}

/// Состояние квеста в игре.
enum SideQuestStatus {
  available,
  active,
  completed,
  failed,
  expired,
}

/// Активный квест с прогрессом.
class ActiveSideQuest {
  final SideQuest quest;
  SideQuestStatus status;
  final Set<String> completedSteps;
  final DateTime startedAt;

  ActiveSideQuest({
    required this.quest,
    this.status = SideQuestStatus.available,
    Set<String>? completedSteps,
    DateTime? startedAt,
  })  : completedSteps = completedSteps ?? {},
        startedAt = startedAt ?? DateTime.now();

  bool isStepComplete(String stepId) => completedSteps.contains(stepId);

  void markStepComplete(String stepId) {
    completedSteps.add(stepId);
  }
}
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/services/progress/run_tracker.dart';

class ChapterSummary {
  final String characterId;
  final String characterName;
  final int chapter;
  final int daysSurvived;
  final int kills;
  final int defeats;
  final int itemsLooted;
  final int itemsCrafted;
  final int infections;
  final int sanityDaysLow;
  final String finalNode;
  final List<String> flags;

  const ChapterSummary({
    required this.characterId,
    required this.characterName,
    required this.chapter,
    required this.daysSurvived,
    required this.kills,
    required this.defeats,
    required this.itemsLooted,
    required this.itemsCrafted,
    required this.infections,
    required this.sanityDaysLow,
    required this.finalNode,
    required this.flags,
  });

  /// Есть ли у игрока хотя бы одно событие в этой главе?
  bool get hasCombat => kills > 0;
  bool get wasWounded => defeats > 0;
  bool get wasCrafty => itemsCrafted > 0;
  bool get wasLucky => itemsLooted > 0;
  bool get wasSick => infections > 0;
  bool get wasUnstable => sanityDaysLow > 0;

  /// Текстовое описание финала
  String get finalDescription {
    if (finalNode.contains('died')) {
      return 'Ты погиб в этой главе. Но история продолжается...';
    }
    if (finalNode.contains('north')) {
      return 'Ты покинул город. Впереди — длинная дорога.';
    }
    if (finalNode.contains('shelter')) {
      return 'Ты переждал первые дни. Впереди — неизвестность.';
    }
    if (finalNode.contains('alliance')) {
      return 'Ты нашёл союзников. Но кому доверять?';
    }
    if (finalNode.contains('ally')) {
      return 'Ты не один. Это шанс. И это риск.';
    }
    return 'Ты выжил. Но это только начало.';
  }

  /// Короткий заголовок концовки
  String get finalTitle {
    if (finalNode.contains('died')) return 'СМЕРТЬ';
    if (finalNode.contains('north')) return 'ДОРОГА';
    if (finalNode.contains('shelter')) return 'УБЕЖИЩЕ';
    if (finalNode.contains('alliance')) return 'СОЮЗНИКИ';
    if (finalNode.contains('ally')) return 'СЕМЬЯ';
    if (finalNode.contains('vaska')) return 'БАНДА';
    if (finalNode.contains('zina')) return 'СТАРУШКА';
    if (finalNode.contains('lena')) return 'С ЛЕНОЙ';
    if (finalNode.contains('group')) return 'ОТРЯД';
    if (finalNode.contains('irina')) return 'АПТЕКА';
    if (finalNode.contains('office')) return 'ОФИС';
    if (finalNode.contains('radio')) return 'СИГНАЛ';
    if (finalNode.contains('basement')) return 'БОМБОУБЕЖИЩЕ';
    if (finalNode.contains('hut')) return 'СТОРОЖКА';
    if (finalNode.contains('siege')) return 'ОСАДА';
    if (finalNode.contains('hospital_stay')) return 'БОЛЬНИЦА';
    if (finalNode.contains('looking')) return 'ПОИСК';
    if (finalNode.contains('morning')) return 'УТРО';
    if (finalNode.contains('katya')) return 'С КАТЕЙ';
    return 'НЕИЗВЕСТНО';
  }

  /// Собрать статистику из save и tracker
  static ChapterSummary fromSaveAndTracker(
    SaveData save,
    RunTracker tracker, {
    required int daysSurvived,
    required String finalNode,
  }) {
    return ChapterSummary(
      characterId: save.characterId,
      characterName: save.characterName,
      chapter: save.chapter,
      daysSurvived: daysSurvived,
      kills: tracker.kills,
      defeats: tracker.defeats,
      itemsLooted: tracker.lootedCount,
      itemsCrafted: tracker.craftedCount,
      infections: tracker.infections,
      sanityDaysLow: tracker.sanityDaysLow,
      finalNode: finalNode,
      flags: save.history,
    );
  }
}
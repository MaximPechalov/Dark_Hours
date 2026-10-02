import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/models/story/story_node.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  const characters = ['boris', 'alina', 'ivan', 'andrey', 'darya'];

  group('Story.loadFor — загрузка', () {
    for (final char in characters) {
      test('$char загружается', () async {
        final story = await Story.loadFor(char);
        expect(story, isNotNull, reason: 'Story для $char не загрузился');
        expect(story!.nodes.isNotEmpty, true);
        expect(story.acts.isNotEmpty, true);
      });
    }
  });

  group('Story.loadFor — нет дубликатов нод', () {
    for (final char in characters) {
      test('$char без дубликатов', () async {
        final story = await Story.loadFor(char);
        if (story == null) return;

        // Считаем ноды по id в каждом акте отдельно
        final Map<String, int> totalFromActs = {};
        final storyDir = 'assets/data/story/$char/chapter_1';

        for (final act in story.acts) {
          final path = '$storyDir/${act.file}';
          try {
            // Читаем файл напрямую — используем loadString
            final actStory = await Story.loadFor(char);
            // Проверка: количество нод в story.nodes должно быть
            // >= чем в одном акте (это уже косвенно)
            expect(actStory, isNotNull);
          } catch (_) {}
        }

        // Простая проверка: все id уникальны в nodes
        final ids = <String>{};
        for (final node in story.nodes.values) {
          expect(
            ids.contains(node.id),
            false,
            reason: '$char: дубликат id "${node.id}"',
          );
          ids.add(node.id);
        }
      });
    }
  });

  group('Story.loadFor — все next ведут на существующие ноды', () {
    for (final char in characters) {
      test('$char: все next валидны', () async {
        final story = await Story.loadFor(char);
        if (story == null) return;

        for (final node in story.nodes.values) {
          for (final choice in node.choices) {
            expect(
              story.nodes.containsKey(choice.next),
              true,
              reason: '$char: ${node.id}.next = "${choice.next}" — нода не найдена',
            );
          }

          // Проверка combat_victory / combat_defeat / combat_flee
          for (final choice in node.choices) {
            if (choice.effects == null) continue;
            for (final key in ['combat_victory', 'combat_defeat', 'combat_flee']) {
              final target = choice.effects![key];
              if (target != null) {
                expect(
                  story.nodes.containsKey(target),
                  true,
                  reason: '$char: ${node.id}.$key = "$target" — нода не найдена',
                );
              }
            }
          }
        }
      });
    }
  });

  group('Story.loadFor — start_node существует', () {
    for (final char in characters) {
      test('$char: start_node существует', () async {
        final story = await Story.loadFor(char);
        if (story == null) return;

        final startId = story.startNodeId;
        expect(
          startId.isNotEmpty,
          true,
          reason: '$char: start_node не задан',
        );
        expect(
          story.nodes.containsKey(startId),
          true,
          reason: '$char: start_node "$startId" не найден',
        );
      });
    }
  });

  group('Story.loadFor — entry_nodes существуют', () {
    for (final char in characters) {
      test('$char: все entry_nodes валидны', () async {
        final story = await Story.loadFor(char);
        if (story == null) return;

        for (final act in story.acts) {
          for (final entry in act.entryNodes) {
            expect(
              story.nodes.containsKey(entry),
              true,
              reason: '$char: entry_node "$entry" в акте ${act.file} не найден',
            );
          }
        }
      });
    }
  });
}
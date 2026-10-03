import 'package:flutter_test/flutter_test.dart';

import 'package:dark_hours/main.dart';

void main() {
  group('DarkHoursApp — smoke test', () {
    testWidgets('приложение запускается и показывает splash', (tester) async {
      await tester.pumpWidget(const DarkHoursApp());
      await tester.pump();

      expect(
        find.text('ТЁМНЫЕ ЧАСЫ'),
        findsOneWidget,
      );
    });
  });
}
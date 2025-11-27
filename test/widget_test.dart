import 'package:flutter_test/flutter_test.dart';
import 'package:draughts_game/main.dart';

void main() {
  testWidgets('Draughts app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DraughtsApp());
    expect(find.text('Draughts'), findsOneWidget);
  });
}

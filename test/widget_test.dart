import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ninth_scout/widgets/note_chips.dart';
import 'package:ninth_scout/utils/formatters.dart';

void main() {
  testWidgets('NoteChips renders the parsed notes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NoteChips(notes: ['دو', 'ري', 'مي']),
        ),
      ),
    );

    expect(find.text('دو'), findsOneWidget);
    expect(find.text('ري'), findsOneWidget);
    expect(find.text('مي'), findsOneWidget);
  });

  test('formatPrice uses configured currency', () {
    final formatted = formatPrice(5);
    expect(formatted, contains('د.ك'));
  });
}
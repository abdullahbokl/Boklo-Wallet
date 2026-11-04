import 'package:boklo/features/transfers/presentation/widgets/amount_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('digits accumulate and parse as money', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextField(controller: controller),
                Expanded(child: AmountKeypad(controller: controller)),
              ],
            ),
          ),
        ),
      ),
    );

    Future<void> tapDigit(String d) async {
      await tester.tap(find.descendant(
        of: find.byType(AmountKeypad),
        matching: find.text(d),
      ));
      await tester.pump();
    }

    await tapDigit('1');
    await tapDigit('2');
    await tapDigit('5');
    await tapDigit('.');
    await tapDigit('5');
    expect(controller.text, '125.5');

    // Second decimal digit is accepted.
    await tapDigit('0');
    expect(controller.text, '125.50');

    // Third decimal is rejected.
    await tapDigit('5');
    expect(controller.text, '125.50');

    // Second separator is rejected.
    await tapDigit('.');
    expect(controller.text, '125.50');
  });

  testWidgets('leading zeros collapse', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountKeypad(controller: controller),
        ),
      ),
    );

    Future<void> tap(String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await tap('0');
    await tap('0');
    expect(controller.text, '0', reason: 'extra leading zeros collapse');

    await tap('5');
    // A non-separator digit replaces a lone leading zero.
    expect(controller.text, '5');
  });

  testWidgets('backspace removes the last digit', (tester) async {
    final controller = TextEditingController()..text = '12.5';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountKeypad(controller: controller),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(controller.text, '12.');
  });
}

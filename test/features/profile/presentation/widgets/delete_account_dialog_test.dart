import 'package:boklo/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(
      home: Scaffold(
        body: DeleteAccountDialog(),
      ),
    );
  }

  testWidgets('shows delete account content', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Delete account'), findsNWidgets(2));
    expect(find.textContaining('permanently removes your profile data'), findsOneWidget);
  });

  testWidgets('confirm stays disabled until password is entered',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    var deleteButton = tester.widget<AppButton>(find.byType(AppButton));
    expect(deleteButton.onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), 'password123');
    await tester.pump();

    deleteButton = tester.widget<AppButton>(find.byType(AppButton));
    expect(deleteButton.onPressed, isNotNull);
  });
}

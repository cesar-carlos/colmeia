import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should invoke onPressed when not loading', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppSecondaryButton(
            label: 'Continuar',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('should not invoke onPressed when loading', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppSecondaryButton(
            label: 'Salvar',
            isLoading: true,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(tapped, isFalse);
  });
}

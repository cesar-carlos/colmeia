import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should call onPressed when not loading', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Salvar',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('should not call onPressed when loading', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Salvar',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tapped, isFalse);
  });
}

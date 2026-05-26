import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'does not throw when laid out with unbounded horizontal width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Wrap(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 88,
                      child: AppDropdownField<int>(
                        value: 10,
                        density: AppTextFieldDensity.compact,
                        options: const <AppDropdownOption<int>>[
                          AppDropdownOption<int>(value: 10, label: '10'),
                          AppDropdownOption<int>(value: 20, label: '20'),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('should call onChanged when an option is selected', (
    tester,
  ) async {
    String? selected = 'a';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 280,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AppDropdownField<String>(
                    value: selected,
                    options: const <AppDropdownOption<String>>[
                      AppDropdownOption<String>(value: 'a', label: 'Alpha'),
                      AppDropdownOption<String>(value: 'b', label: 'Beta'),
                    ],
                    onChanged: (value) => setState(() => selected = value),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beta'));
    await tester.pump();

    expect(selected, 'b');
  });
}

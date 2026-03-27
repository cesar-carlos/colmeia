import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/forms/app_checkbox_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should toggle checkbox when label tapped', (tester) async {
    var value = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppCheckboxField(
                value: value,
                onChanged: (v) => setState(() => value = v ?? false),
                label: 'Aceito',
              );
            },
          ),
        ),
      ),
    );

    expect(value, isFalse);
    await tester.tap(find.text('Aceito'));
    await tester.pump();
    expect(value, isTrue);
  });
}

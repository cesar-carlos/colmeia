import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/forms/app_radio_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should update group value on tap', (tester) async {
    String? selected = 'a';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
                options: const <AppRadioOption<String>>[
                  AppRadioOption<String>(value: 'a', label: 'Opcao A'),
                  AppRadioOption<String>(value: 'b', label: 'Opcao B'),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Opcao B'));
    await tester.pump();
    expect(selected, 'b');
  });
}

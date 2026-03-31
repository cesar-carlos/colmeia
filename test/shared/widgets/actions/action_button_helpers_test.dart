import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'wrapAppActionButtonSemantics announces Carregando with label when loading',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: wrapAppActionButtonSemantics(
            child: const SizedBox.shrink(),
            isLoading: true,
            onPressed: () {},
            labelForLoadingAnnouncement: 'Salvar',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Carregando: Salvar'), findsOneWidget);
    },
  );

  testWidgets(
    'wrapAppActionButtonSemantics uses custom semanticsLabel when provided',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: wrapAppActionButtonSemantics(
            child: const SizedBox.shrink(),
            isLoading: true,
            onPressed: () {},
            semanticsLabel: 'Enviando formulario',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Enviando formulario'), findsOneWidget);
    },
  );

  testWidgets(
    'wrapAppActionButtonSemantics passes through child when idle without label',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: wrapAppActionButtonSemantics(
            child: const Text('Somente texto'),
            isLoading: false,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Somente texto'), findsOneWidget);
    },
  );
}

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_sunburst_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading state uses AppSkeleton instead of spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppSunburstChart<String>(
            title: 'Loading demo',
            items: <String>[],
            idBuilder: _identity,
            labelBuilder: _identity,
            valueBuilder: _zero,
            parentIdBuilder: _nullParent,
            isLoading: true,
            loadingSemanticsLabel: 'Carregando hierarquia de custos',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.bySemanticsLabel('Carregando hierarquia de custos'),
      findsOneWidget,
    );
  });

  testWidgets(
    'exposes default semantics label and hint for interactive chart',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: AppSunburstChart<_SunburstMetric>(
              title: 'Hierarquia de receita',
              items: const <_SunburstMetric>[
                _SunburstMetric(id: 'root', label: 'Root', value: 0),
                _SunburstMetric(
                  id: 'child',
                  label: 'Child',
                  value: 10,
                  parentId: 'root',
                ),
              ],
              idBuilder: (item) => item.id,
              labelBuilder: (item) => item.label,
              valueBuilder: (item) => item.value,
              parentIdBuilder: (item) => item.parentId,
              onSegmentTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      const semanticsLabel =
          'Hierarquia de receita, grafico sunburst com 2 itens.';
      const semanticsHint = 'Toque em um segmento para explorar a hierarquia.';

      expect(find.bySemanticsLabel(semanticsLabel), findsOneWidget);
      final semanticsNode = tester.getSemantics(
        find.bySemanticsLabel(semanticsLabel),
      );
      expect(semanticsNode.hint, semanticsHint);
    },
  );

  testWidgets('exposes custom empty semantics label', (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppSunburstChart<String>(
            title: 'Sunburst vazio',
            items: <String>[],
            idBuilder: _identity,
            labelBuilder: _identity,
            valueBuilder: _zero,
            parentIdBuilder: _nullParent,
            emptySemanticsLabel: 'Sunburst vazio sem hierarquia',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('Sunburst vazio sem hierarquia'),
      findsOneWidget,
    );
  });

  testWidgets('aggregates internal node own value with child totals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AppSunburstChart<_SunburstMetric>(
            items: const <_SunburstMetric>[
              _SunburstMetric(id: 'opex', label: 'OPEX', value: 10),
              _SunburstMetric(
                id: 'infra',
                label: 'Infra',
                value: 5,
                parentId: 'opex',
              ),
            ],
            idBuilder: (item) => item.id,
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.value,
            parentIdBuilder: (item) => item.parentId,
            centerLabel: 'Total',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('15'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }
}

String _identity(String item) => item;

String? _nullParent(String _) => null;

num _zero(String _) => 0;

class _SunburstMetric {
  const _SunburstMetric({
    required this.id,
    required this.label,
    required this.value,
    this.parentId,
  });

  final String id;
  final String label;
  final double value;
  final String? parentId;
}

import 'package:colmeia/shared/widgets/charts/app_chart_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'fades and slides the child in over the configured duration',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppChartFadeIn(
              duration: Duration(milliseconds: 200),
              child: SizedBox(
                key: ValueKey<String>('child'),
                width: 80,
                height: 80,
              ),
            ),
          ),
        ),
      );

      // Frame 0: fully transparent and offset by slideOffsetPx.
      final initialOpacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(initialOpacity.opacity, lessThan(0.05));
      final initialTransform = tester.widget<Transform>(
        find.byType(Transform),
      );
      // Translation Y is the value at index 13 of a 4x4 matrix (`storage[13]`).
      expect(initialTransform.transform.storage[13], greaterThan(0));

      // After enough time the animation has settled and Opacity is 1.
      await tester.pump(const Duration(milliseconds: 300));
      final settledOpacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(settledOpacity.opacity, 1);
      final settledTransform = tester.widget<Transform>(
        find.byType(Transform),
      );
      expect(settledTransform.transform.storage[13], 0);

      expect(find.byKey(const ValueKey<String>('child')), findsOneWidget);
    },
  );

  testWidgets(
    'skips animation entirely when reduce-motion is enabled',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(
              child: AppChartFadeIn(
                child: SizedBox(
                  key: ValueKey<String>('child'),
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          ),
        ),
      );

      // No Opacity/Transform are inserted in the reduce-motion path.
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(Transform), findsNothing);
      expect(find.byKey(const ValueKey<String>('child')), findsOneWidget);
    },
  );

  testWidgets(
    'slideOffsetPx == 0 disables the translate but keeps the fade',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppChartFadeIn(
              slideOffsetPx: 0,
              duration: Duration(milliseconds: 100),
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      expect(find.byType(Opacity), findsOneWidget);
      expect(find.byType(Transform), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
    },
  );
}

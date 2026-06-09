import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChartShareActions emits share request through callback', (
    tester,
  ) async {
    final captureKey = GlobalKey();
    AppChartShareRequest? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final actions = ChartShareActions(
              context: context,
              captureKey: captureKey,
              metadata: const ChartShareMetadata(title: 'Chart'),
              onRequestShare: (ctx, request) => captured = request,
            );

            return TextButton(
              onPressed: actions.shareCallback(),
              child: const Text('Share'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Share'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.captureKey, captureKey);
    expect(captured!.title, 'Chart');
  });

  testWidgets('ChartShareActions returns null share callback when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final actions = ChartShareActions(
              context: context,
              captureKey: GlobalKey(),
              metadata: const ChartShareMetadata(title: 'Chart'),
              onRequestShare: (_, _) {},
              shareEnabled: false,
            );

            expect(actions.shareCallback(), isNull);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}

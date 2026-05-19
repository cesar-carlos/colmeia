import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('updates countdown label from shared ticker listenable', (
    tester,
  ) async {
    final ticker = ValueNotifier<DateTime>(DateTime(2026, 5, 19, 12));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AutoRefreshActionsRow(
            options: const <AutoRefreshOption>[
              AutoRefreshOption(
                id: 'fiveMinutes',
                duration: Duration(minutes: 5),
              ),
            ],
            optionLabelBuilder: (option) => option.id,
            value: null,
            onChanged: (_) {},
            onRefreshNow: () {},
            enabled: true,
            refreshNowLabel: 'Refresh now',
            offLabel: 'Off',
            tooltipLabel: 'Auto refresh',
            nextDueAt: DateTime(2026, 5, 19, 12, 0, 5),
            countdownTicker: ticker,
            countdownLabelBuilder: (remaining, {required isBackingOff}) {
              return '${remaining.inSeconds}s';
            },
          ),
        ),
      ),
    );

    expect(find.text('5s'), findsOneWidget);

    ticker.value = DateTime(2026, 5, 19, 12, 0, 3);
    await tester.pump();

    expect(find.text('2s'), findsOneWidget);

    ticker.value = DateTime(2026, 5, 19, 12, 0, 8);
    await tester.pump();

    expect(find.text('0s'), findsOneWidget);
  });

  testWidgets('renders a compact status label when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AutoRefreshActionsRow(
            options: const <AutoRefreshOption>[
              AutoRefreshOption(
                id: 'fiveMinutes',
                duration: Duration(minutes: 5),
              ),
            ],
            optionLabelBuilder: (option) => option.id,
            value: const AutoRefreshOption(
              id: 'fiveMinutes',
              duration: Duration(minutes: 5),
            ),
            onChanged: (_) {},
            onRefreshNow: () {},
            enabled: false,
            refreshNowLabel: 'Refresh now',
            offLabel: 'Off',
            tooltipLabel: 'Auto refresh',
            statusLabel: 'Auto-refresh paused while loading',
          ),
        ),
      ),
    );

    expect(find.text('Auto-refresh paused while loading'), findsOneWidget);
  });
}

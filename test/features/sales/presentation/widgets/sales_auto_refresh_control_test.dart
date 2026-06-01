import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _offLabel = 'Off';
const String _tooltipLabel = 'Auto-refresh';

void main() {
  testWidgets('shows off and fixed interval options', (tester) async {
    await _pumpControl(
      tester,
      value: null,
      onChanged: (_) {},
    );

    await tester.tap(find.text(_offLabel));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('sales-auto-refresh-off')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sales-auto-refresh-fiveMinutes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sales-auto-refresh-tenMinutes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sales-auto-refresh-fifteenMinutes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sales-auto-refresh-thirtyMinutes')),
      findsOneWidget,
    );
  });

  testWidgets('calls back when an interval is selected', (tester) async {
    AutoRefreshOption? selected;

    await _pumpControl(
      tester,
      value: null,
      onChanged: (value) => selected = value,
    );

    await tester.tap(find.text(_offLabel));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('sales-auto-refresh-tenMinutes')),
    );
    await tester.pumpAndSettle();

    expect(selected, SalesAutoRefreshOptions.tenMinutes);
  });

  testWidgets('calls back with null when turned off', (tester) async {
    AutoRefreshOption? selected = SalesAutoRefreshOptions.fiveMinutes;

    await _pumpControl(
      tester,
      value: SalesAutoRefreshOptions.fiveMinutes,
      onChanged: (value) => selected = value,
    );

    await tester.tap(
      find.text(
        AppLocalizationsEn().salesAutoRefreshIntervalFiveMinutes,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('sales-auto-refresh-off')),
    );
    await tester.pumpAndSettle();

    expect(selected, isNull);
  });
}

Future<void> _pumpControl(
  WidgetTester tester, {
  required AutoRefreshOption? value,
  required ValueChanged<AutoRefreshOption?> onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SalesAutoRefreshControl(
            value: value,
            onChanged: onChanged,
            offLabel: _offLabel,
            tooltipLabel: _tooltipLabel,
          ),
        ),
      ),
    ),
  );
}

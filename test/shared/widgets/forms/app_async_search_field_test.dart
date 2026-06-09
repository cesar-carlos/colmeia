import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/forms/app_async_search_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debounces search, shows results, and selects option', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                child: _DebouncedSearchHarness(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Todos').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), 'al');
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('Grupo Alpha'), findsOneWidget);

    await tester.tap(find.text('Grupo Alpha'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Grupo Alpha'), findsWidgets);
  });

  testWidgets('ignores stale loader responses', (tester) async {
    Future<AppAsyncSearchLoadResult<int>> loader(
      AppAsyncSearchQuery query,
    ) async {
      if (query.searchTerm == 'slow') {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return const AppAsyncSearchLoadResult<int>(
          options: <AppAsyncSearchOption<int>>[
            AppAsyncSearchOption<int>(value: 1, label: 'Stale'),
          ],
          hasMore: false,
        );
      }
      return const AppAsyncSearchLoadResult<int>(
        options: <AppAsyncSearchOption<int>>[
          AppAsyncSearchOption<int>(value: 2, label: 'Fresh'),
        ],
        hasMore: false,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: AppAsyncSearchField<int>(
                hintText: 'Selecione',
                loader: loader,
                debounceDuration: const Duration(milliseconds: 20),
                onChanged: (_, {label}) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Selecione'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), 'slow');
    await tester.pump(const Duration(milliseconds: 25));
    await tester.enterText(find.byType(TextField), 'fast');
    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Fresh'), findsOneWidget);
    expect(find.text('Stale'), findsNothing);
  });

  testWidgets('shows inline error panel and retry action', (tester) async {
    var loadAttempts = 0;

    Future<AppAsyncSearchLoadResult<int>> loader(
      AppAsyncSearchQuery query,
    ) async {
      loadAttempts++;
      return const AppAsyncSearchLoadResult<int>(
        options: <AppAsyncSearchOption<int>>[],
        hasMore: false,
        errorMessage: 'Group options failed',
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppAsyncSearchField<int>(
            hintText: 'Todos',
            loader: loader,
            debounceDuration: const Duration(milliseconds: 20),
            onChanged: (_, {label}) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Todos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'be');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('Group options failed'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 30));

    expect(loadAttempts, greaterThan(1));
  });
}

class _DebouncedSearchHarness extends StatefulWidget {
  const _DebouncedSearchHarness();

  @override
  State<_DebouncedSearchHarness> createState() =>
      _DebouncedSearchHarnessState();
}

class _DebouncedSearchHarnessState extends State<_DebouncedSearchHarness> {
  int? _selectedValue;
  String? _selectedLabel;

  Future<AppAsyncSearchLoadResult<int>> _loader(
    AppAsyncSearchQuery query,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return const AppAsyncSearchLoadResult<int>(
      options: <AppAsyncSearchOption<int>>[
        AppAsyncSearchOption<int>(value: 10, label: 'Grupo Alpha'),
        AppAsyncSearchOption<int>(value: 20, label: 'Grupo Beta'),
      ],
      hasMore: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppAsyncSearchField<int>(
      label: 'Grupo',
      hintText: 'Todos',
      searchHintText: 'Buscar grupo',
      clearOptionLabel: 'Todos',
      value: _selectedValue,
      selectedDisplayLabel: _selectedLabel,
      density: AppTextFieldDensity.compact,
      debounceDuration: const Duration(milliseconds: 50),
      loader: _loader,
      onChanged: (value, {label}) {
        setState(() {
          _selectedValue = value;
          _selectedLabel = label;
        });
      },
    );
  }
}

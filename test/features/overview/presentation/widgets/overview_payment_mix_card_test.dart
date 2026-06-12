import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_mix_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_placeholder_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  testWidgets('shows loading state while payment mix is loading', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: OverviewPaymentMixCard(
          l10n: l10n,
          methods: const <OverviewPaymentMethodBreakdown>[],
          isLoading: true,
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(AppCategoryDonutCard), findsOneWidget);
    expect(find.byType(CategoryDonutCardLoadingBlock), findsOneWidget);
  });

  testWidgets('disables share while loading', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: OverviewPaymentMixCard(
          l10n: l10n,
          methods: const <OverviewPaymentMethodBreakdown>[],
          isLoading: true,
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip(l10n.chartShareTooltip), findsNothing);
  });
}

import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/l10n/app_localizations.dart';

extension OverviewChartCardDescriptorL10n on OverviewChartCardDescriptor {
  String resolvedTitle(AppLocalizations l10n) {
    return switch (id) {
      'daily_sales' => l10n.overviewDailySalesTitle,
      'payment_mix' => l10n.overviewPaymentMixTitle,
      'weekday_sales' => l10n.overviewWeekdaySalesTitle,
      'weekday_user_sales' => l10n.overviewWeekdayUserSalesTitle,
      'user_ranking' => l10n.dashboardUserRankingTitle,
      'lucratividade_period' => l10n.overviewLucratividadeTitle,
      _ => id,
    };
  }
}

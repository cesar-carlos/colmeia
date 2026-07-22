import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/l10n/app_localizations.dart';

extension OverviewProgressiveSectionLoadingL10n on OverviewProgressiveSection {
  String loadingSemanticsLabel(AppLocalizations l10n) {
    return switch (this) {
      OverviewProgressiveSection.dailySales =>
        l10n.overviewLoadingDailySalesSemantics,
      OverviewProgressiveSection.paymentMix =>
        l10n.overviewLoadingPaymentMixSemantics,
      OverviewProgressiveSection.weekdaySales =>
        l10n.overviewLoadingWeekdaySalesSemantics,
      OverviewProgressiveSection.weekdayUserSales =>
        l10n.overviewLoadingWeekdayUserSalesSemantics,
      OverviewProgressiveSection.userRanking =>
        l10n.overviewLoadingRankingsSemantics,
      OverviewProgressiveSection.lucratividadePeriod =>
        l10n.overviewLoadingLucratividadeSemantics,
      _ => l10n.appLoadingDataSemantics,
    };
  }
}

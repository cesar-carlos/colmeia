import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_summary_bar.dart';
import 'package:flutter/material.dart';

class OverviewKpiBar extends StatelessWidget {
  const OverviewKpiBar({
    required this.l10n,
    required this.kpis,
    super.key,
  });

  final AppLocalizations l10n;
  final OverviewPaymentKpis kpis;

  @override
  Widget build(BuildContext context) {
    return AppReportSummaryBar(
      items: <AppReportSummaryItem>[
        AppReportSummaryItem(
          label: l10n.overviewKpiTotalRevenue,
          value: AppBrFormatters.currency(kpis.totalAmount),
          icon: Icons.payments_outlined,
        ),
        AppReportSummaryItem(
          label: l10n.overviewKpiSales,
          value: kpis.totalSalesCount.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        AppReportSummaryItem(
          label: l10n.overviewKpiAvgTicket,
          value: AppBrFormatters.currency(kpis.averageTicket),
          icon: Icons.local_offer_outlined,
        ),
        AppReportSummaryItem(
          label: l10n.overviewKpiPaymentMethodCount,
          value: kpis.paymentMethodCount.toString(),
          icon: Icons.credit_card_outlined,
        ),
      ],
    );
  }
}

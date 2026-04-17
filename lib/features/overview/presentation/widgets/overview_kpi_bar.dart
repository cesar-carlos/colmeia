import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_summary_bar.dart';
import 'package:flutter/material.dart';

class OverviewKpiBar extends StatefulWidget {
  const OverviewKpiBar({
    required this.l10n,
    required this.kpis,
    super.key,
  });

  final AppLocalizations l10n;
  final OverviewPaymentKpis kpis;

  @override
  State<OverviewKpiBar> createState() => _OverviewKpiBarState();
}

class _OverviewKpiBarState extends State<OverviewKpiBar> {
  ({
    String locale,
    int totalSalesCount,
    double totalAmount,
    double averageTicket,
    int paymentMethodCount,
  })? _itemsKey;

  List<AppReportSummaryItem>? _items;

  void _rebuildItemsIfNeeded() {
    final k = widget.kpis;
    final nextKey = (
      locale: widget.l10n.localeName,
      totalSalesCount: k.totalSalesCount,
      totalAmount: k.totalAmount,
      averageTicket: k.averageTicket,
      paymentMethodCount: k.paymentMethodCount,
    );
    if (_items != null && _itemsKey == nextKey) {
      return;
    }
    _itemsKey = nextKey;
    final l10n = widget.l10n;
    _items = <AppReportSummaryItem>[
      AppReportSummaryItem(
        label: l10n.overviewKpiTotalRevenue,
        value: AppBrFormatters.currency(k.totalAmount),
        icon: Icons.payments_outlined,
      ),
      AppReportSummaryItem(
        label: l10n.overviewKpiSales,
        value: k.totalSalesCount.toString(),
        icon: Icons.receipt_long_outlined,
      ),
      AppReportSummaryItem(
        label: l10n.overviewKpiAvgTicket,
        value: AppBrFormatters.currency(k.averageTicket),
        icon: Icons.local_offer_outlined,
      ),
      AppReportSummaryItem(
        label: l10n.overviewKpiPaymentMethodCount,
        value: k.paymentMethodCount.toString(),
        icon: Icons.credit_card_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _rebuildItemsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OverviewKpiBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildItemsIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return AppReportSummaryBar(items: _items!);
  }
}

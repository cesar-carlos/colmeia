import 'package:flutter/foundation.dart';

/// Optional copy for monthly parcel combo charts outside the overview
/// (e.g. Sales hub) so titles do not imply multi-branch scope.
@immutable
class MonthlyParcelsComboChartStrings {
  const MonthlyParcelsComboChartStrings({
    required this.chartTitle,
    required this.subtitleWhenSalesPrimary,
    required this.subtitleWhenValuePrimary,
    required this.switchSalesLabel,
    required this.switchParcelValueLabel,
    required this.seriesSalesLabel,
    required this.seriesParcelAmountLabel,
    required this.emptyMessage,
    required this.loadFailedMessage,
    required this.semanticsWhenSalesPrimary,
    required this.semanticsWhenValuePrimary,
  });

  final String chartTitle;
  final String subtitleWhenSalesPrimary;
  final String subtitleWhenValuePrimary;
  final String switchSalesLabel;
  final String switchParcelValueLabel;
  final String seriesSalesLabel;
  final String seriesParcelAmountLabel;
  final String emptyMessage;
  final String loadFailedMessage;
  final String semanticsWhenSalesPrimary;
  final String semanticsWhenValuePrimary;
}

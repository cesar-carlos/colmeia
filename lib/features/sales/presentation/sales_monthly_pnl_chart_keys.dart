import 'package:flutter/foundation.dart';

/// Stable keys for horizontally scrollable chart shells on the sales monthly P&L page.
abstract final class SalesMonthlyPnlChartKeys {
  SalesMonthlyPnlChartKeys._();

  static const ValueKey<String> lineHorizontalScrollShell = ValueKey<String>(
    'salesMonthlyPnl.line.horizontalScrollShell',
  );

  static const ValueKey<String> barHorizontalScrollShell = ValueKey<String>(
    'salesMonthlyPnl.bar.horizontalScrollShell',
  );
}

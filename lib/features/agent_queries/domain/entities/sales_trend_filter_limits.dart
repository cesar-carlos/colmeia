import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';

/// Shared validation helpers for trend filter volume / threshold fields.
abstract final class SalesTrendFilterLimits {
  static const int defaultMinVolumeUnits = 10;
  static const int minMinVolumeUnits = 1;
  static const int maxMinVolumeUnits = 100000;
  static const List<int> minVolumePresets = <int>[5, 10, 50];

  static const double defaultTrendThresholdPercent = 0.2;
  static const double minTrendThresholdPercent = 0.05;
  static const double maxTrendThresholdPercent = 0.9;
  static const List<double> trendThresholdPresets = <double>[0.1, 0.2, 0.3];

  static String? validateMinVolumeUnits(int value) {
    if (value < minMinVolumeUnits || value > maxMinVolumeUnits) {
      return 'minVolumeUnits must be between $minMinVolumeUnits and '
          '$maxMinVolumeUnits';
    }
    return null;
  }

  static String? validateTrendThresholdPercent(double value) {
    if (value < minTrendThresholdPercent || value > maxTrendThresholdPercent) {
      return 'trendThresholdPercent must be between '
          '$minTrendThresholdPercent and $maxTrendThresholdPercent';
    }
    return null;
  }

  static String? validateCodFilial(int? value) {
    if (value != null && value <= 0) {
      return 'codFilial must be > 0 when provided';
    }
    return null;
  }

  static String? validateClassificacao(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    if (SalesTrendClassificacao.normalize(raw) == null) {
      return 'classificacao is not allowed';
    }
    return null;
  }

  static SalesTrendMetricMode metricModeFromName(String? name) {
    return SalesTrendMetricMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => SalesTrendMetricMode.quantity,
    );
  }

  static SalesTrendTopMoversSortBy topMoversSortFromName(String? name) {
    return SalesTrendTopMoversSortBy.values.firstWhere(
      (sort) => sort.name == name,
      orElse: () => SalesTrendTopMoversSortBy.diferenca,
    );
  }
}

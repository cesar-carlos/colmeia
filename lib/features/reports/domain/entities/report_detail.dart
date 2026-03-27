import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_page_info.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/report_summary_metric.dart';

class ReportDetail {
  const ReportDetail({
    required this.definition,
    required this.storeName,
    required this.generatedAtLabel,
    required this.parameters,
    required this.pageInfo,
    required this.summaryMetrics,
    required this.rows,
  });

  final ReportDefinition definition;
  final String storeName;
  final String generatedAtLabel;
  final List<ReportParameterDescriptor> parameters;
  final ReportPageInfo pageInfo;
  final List<ReportSummaryMetric> summaryMetrics;
  final List<ReportResultRow> rows;
}

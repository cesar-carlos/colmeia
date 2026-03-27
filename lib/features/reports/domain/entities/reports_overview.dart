import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';

class ReportsOverview {
  const ReportsOverview({
    required this.availableReports,
    required this.parameters,
    required this.rows,
  });

  final List<ReportDefinition> availableReports;
  final List<ReportParameterDescriptor> parameters;
  final List<ReportResultRow> rows;
}

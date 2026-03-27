import 'dart:convert';

import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/reports_overview.dart';

class ReportsOverviewModel {
  const ReportsOverviewModel({
    required this.availableReports,
    required this.parameters,
    required this.rows,
  });

  factory ReportsOverviewModel.fromJson(Map<String, dynamic> json) {
    final availableReportsJson = json['availableReports'] as List<dynamic>;
    final parametersJson = json['parameters'] as List<dynamic>;
    final rowsJson = json['rows'] as List<dynamic>;

    return ReportsOverviewModel(
      availableReports: availableReportsJson
          .map(
            (item) {
              final reportJson = item as Map<String, dynamic>;

              return ReportDefinition(
                id: reportJson['id'] as String,
                title: reportJson['title'] as String,
                subtitle: reportJson['subtitle'] as String,
              );
            },
          )
          .toList(growable: false),
      parameters: parametersJson
          .map(_parameterFromJson)
          .toList(growable: false),
      rows: rowsJson
          .map(
            (item) {
              final rowJson = item as Map<String, dynamic>;

              return ReportResultRow(
                seller: rowJson['seller'] as String,
                store: rowJson['store'] as String,
                revenue: (rowJson['revenue'] as num).toDouble(),
                orders: rowJson['orders'] as int,
              );
            },
          )
          .toList(growable: false),
    );
  }

  factory ReportsOverviewModel.decode(String raw) {
    return ReportsOverviewModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  final List<ReportDefinition> availableReports;
  final List<ReportParameterDescriptor> parameters;
  final List<ReportResultRow> rows;

  ReportsOverview toEntity() {
    return ReportsOverview(
      availableReports: availableReports,
      parameters: parameters,
      rows: rows,
    );
  }

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'availableReports': availableReports
          .map((report) {
            return <String, Object?>{
              'id': report.id,
              'title': report.title,
              'subtitle': report.subtitle,
            };
          })
          .toList(growable: false),
      'parameters': parameters.map(_parameterToJson).toList(growable: false),
      'rows': rows
          .map((row) {
            return <String, Object?>{
              'seller': row.seller,
              'store': row.store,
              'revenue': row.revenue,
              'orders': row.orders,
            };
          })
          .toList(growable: false),
    };
  }

  static ReportParameterDescriptor _parameterFromJson(dynamic item) {
    final parameterJson = item as Map<String, dynamic>;
    final optionsJson =
        parameterJson['options'] as List<dynamic>? ?? <dynamic>[];

    return ReportParameterDescriptor(
      name: parameterJson['name'] as String,
      label: parameterJson['label'] as String,
      type: ReportParameterType.values.byName(parameterJson['type'] as String),
      required: parameterJson['required'] as bool? ?? false,
      initialValue: _decodeParameterValue(parameterJson['initialValue']),
      options: optionsJson
          .map(
            (option) {
              final optionJson = option as Map<String, dynamic>;

              return ReportParameterOption(
                value: optionJson['value'] as String,
                label: optionJson['label'] as String,
              );
            },
          )
          .toList(growable: false),
    );
  }

  static Map<String, Object?> _parameterToJson(ReportParameterDescriptor item) {
    return <String, Object?>{
      'name': item.name,
      'label': item.label,
      'type': item.type.name,
      'required': item.required,
      'initialValue': _encodeParameterValue(item.initialValue),
      'options': item.options
          .map((option) {
            return <String, Object?>{
              'value': option.value,
              'label': option.label,
            };
          })
          .toList(growable: false),
    };
  }

  static Object? _encodeParameterValue(Object? value) {
    if (value is DateTime) {
      return <String, Object?>{
        'type': 'dateTime',
        'value': value.toIso8601String(),
      };
    }

    return value;
  }

  static Object? _decodeParameterValue(Object? value) {
    if (value case <String, dynamic>{
      'type': 'dateTime',
      'value': final String rawValue,
    }) {
      return DateTime.parse(rawValue);
    }

    return value;
  }
}

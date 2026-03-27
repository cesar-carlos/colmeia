import 'dart:convert';

import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/entities/report_page_info.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/report_summary_metric.dart';

class ReportDetailModel {
  const ReportDetailModel({
    required this.definition,
    required this.storeName,
    required this.generatedAtLabel,
    required this.parameters,
    required this.pageInfo,
    required this.summaryMetrics,
    required this.rows,
  });

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    final definitionJson = json['definition'] as Map<String, dynamic>;
    final parametersJson = json['parameters'] as List<dynamic>? ?? <dynamic>[];
    final pageInfoJson = json['pageInfo'] as Map<String, dynamic>;
    final summaryMetricsJson = json['summaryMetrics'] as List<dynamic>;
    final rowsJson = json['rows'] as List<dynamic>;

    return ReportDetailModel(
      definition: ReportDefinition(
        id: definitionJson['id'] as String,
        title: definitionJson['title'] as String,
        subtitle: definitionJson['subtitle'] as String,
      ),
      storeName: json['storeName'] as String,
      generatedAtLabel: json['generatedAtLabel'] as String,
      parameters: parametersJson
          .map(_parameterFromJson)
          .toList(growable: false),
      pageInfo: ReportPageInfo(
        currentPage: pageInfoJson['currentPage'] as int,
        pageSize: pageInfoJson['pageSize'] as int,
        totalRows: pageInfoJson['totalRows'] as int,
        totalPages: pageInfoJson['totalPages'] as int,
      ),
      summaryMetrics: summaryMetricsJson
          .map(
            (item) {
              final metricJson = item as Map<String, dynamic>;

              return ReportSummaryMetric(
                title: metricJson['title'] as String,
                value: metricJson['value'] as String,
                detailLabel: metricJson['detailLabel'] as String,
              );
            },
          )
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

  factory ReportDetailModel.decode(String raw) {
    return ReportDetailModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  final ReportDefinition definition;
  final String storeName;
  final String generatedAtLabel;
  final List<ReportParameterDescriptor> parameters;
  final ReportPageInfo pageInfo;
  final List<ReportSummaryMetric> summaryMetrics;
  final List<ReportResultRow> rows;

  ReportDetail toEntity() {
    return ReportDetail(
      definition: definition,
      storeName: storeName,
      generatedAtLabel: generatedAtLabel,
      parameters: parameters,
      pageInfo: pageInfo,
      summaryMetrics: summaryMetrics,
      rows: rows,
    );
  }

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'definition': <String, Object?>{
        'id': definition.id,
        'title': definition.title,
        'subtitle': definition.subtitle,
      },
      'storeName': storeName,
      'generatedAtLabel': generatedAtLabel,
      'parameters': parameters.map(_parameterToJson).toList(growable: false),
      'pageInfo': <String, Object?>{
        'currentPage': pageInfo.currentPage,
        'pageSize': pageInfo.pageSize,
        'totalRows': pageInfo.totalRows,
        'totalPages': pageInfo.totalPages,
      },
      'summaryMetrics': summaryMetrics
          .map((metric) {
            return <String, Object?>{
              'title': metric.title,
              'value': metric.value,
              'detailLabel': metric.detailLabel,
            };
          })
          .toList(growable: false),
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

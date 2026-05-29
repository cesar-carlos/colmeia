import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';

/// Produces and shares plain-text report exports (JSON and CSV).
abstract final class ReportTextExporter {
  static Future<void> exportJson<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
  }) async {
    final objects = <Map<String, Object?>>[];
    for (final row in rows) {
      final map = <String, Object?>{};
      for (final col in columns) {
        map[col.key] = _cellValue(col, row);
      }
      objects.add(map);
    }
    final str = const JsonEncoder.withIndent('  ').convert(objects);
    final bytes = Uint8List.fromList(utf8.encode(str));
    await shareReportExportBytes(
      format: AppReportExportFormat.json,
      bytes: bytes,
      title: title,
    );
  }

  static Future<void> exportCsv<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
  }) async {
    final buffer = StringBuffer()
      ..writeln(columns.map((c) => _escapeCsvField(c.label)).join(','));
    for (final row in rows) {
      final line = columns
          .map((col) => _escapeCsvField(col.formatValue(col.valueGetter(row))))
          .join(',');
      buffer.writeln(line);
    }
    final bytes = Uint8List.fromList(<int>[
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(buffer.toString()),
    ]);
    await shareReportExportBytes(
      format: AppReportExportFormat.csv,
      bytes: bytes,
      title: title,
    );
  }

  static Object? _cellValue<T>(AppReportColumn<T> col, T row) {
    final v = col.valueGetter(row);
    if (v == null) {
      return null;
    }
    if (v is num || v is bool) {
      return v;
    }
    if (v is String) {
      return v;
    }
    return col.formatValue(v);
  }

  static String _escapeCsvField(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

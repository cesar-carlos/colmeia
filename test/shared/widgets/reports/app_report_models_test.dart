import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppReportExportFormatX', () {
    test('should expose document metadata for pdf', () {
      expect(AppReportExportFormat.pdf.label, 'PDF');
      expect(AppReportExportFormat.pdf.fileExtension, 'pdf');
      expect(AppReportExportFormat.pdf.mimeType, 'application/pdf');
      expect(AppReportExportFormat.pdf.supportsMetadataSections, isTrue);
      expect(AppReportExportFormat.pdf.supportsLandscapeOptions, isTrue);
      expect(
        AppReportExportFormat.pdf.icon,
        Icons.picture_as_pdf_outlined,
      );
    });

    test('should expose tabular metadata for json and csv', () {
      expect(AppReportExportFormat.json.label, 'JSON');
      expect(AppReportExportFormat.json.fileExtension, 'json');
      expect(AppReportExportFormat.json.supportsMetadataSections, isFalse);
      expect(AppReportExportFormat.json.supportsLandscapeOptions, isFalse);

      expect(AppReportExportFormat.csv.label, 'CSV');
      expect(AppReportExportFormat.csv.fileExtension, 'csv');
      expect(AppReportExportFormat.csv.mimeType, 'text/csv');
      expect(AppReportExportFormat.csv.supportsMetadataSections, isFalse);
    });
  });
}

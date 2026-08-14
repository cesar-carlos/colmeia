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

  group('nextSingleColumnSort', () {
    test('should start from initialDirection when the column is not active', () {
      expect(
        nextSingleColumnSort(
          columnKey: 'margem',
          currentSorts: const <AppReportSortDescriptor>[
            AppReportSortDescriptor(
              columnKey: 'nomeProduto',
              direction: AppReportSortDirection.ascending,
            ),
          ],
          initialDirection: AppReportSortDirection.descending,
        ),
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: 'margem',
            direction: AppReportSortDirection.descending,
          ),
        ],
      );
    });

    test('should toggle ascending to descending on the active column', () {
      expect(
        nextSingleColumnSort(
          columnKey: 'nomeProduto',
          currentSorts: const <AppReportSortDescriptor>[
            AppReportSortDescriptor(
              columnKey: 'nomeProduto',
              direction: AppReportSortDirection.ascending,
            ),
          ],
        ),
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: 'nomeProduto',
            direction: AppReportSortDirection.descending,
          ),
        ],
      );
    });

    test('should toggle descending to ascending on the active column', () {
      expect(
        nextSingleColumnSort(
          columnKey: 'nomeProduto',
          currentSorts: const <AppReportSortDescriptor>[
            AppReportSortDescriptor(
              columnKey: 'nomeProduto',
              direction: AppReportSortDirection.descending,
            ),
          ],
        ),
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: 'nomeProduto',
            direction: AppReportSortDirection.ascending,
          ),
        ],
      );
    });
  });
}

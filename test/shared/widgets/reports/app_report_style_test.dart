import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppReportViewerStyle.numericalDetailing', () {
    test('should provide the expected dense numerical preset', () {
      final style = AppReportViewerStyle.numericalDetailing(
        entityLabel: 'itens',
        gridHeight: 320,
        dataRowHeight: 68,
        frozenColumnsCount: 2,
        showExportActions: true,
      );

      expect(style.variant, AppReportViewerVariant.minimal);
      expect(style.toolbarMode, AppReportToolbarMode.compact);
      expect(style.showToolbarLabel, isFalse);
      expect(style.showExportActions, isTrue);
      expect(style.showRefreshAction, isFalse);
      expect(style.showFiltersPanel, isFalse);
      expect(style.showSummaryBar, isFalse);
      expect(style.entityLabel, 'itens');
      expect(style.gridHeight, 320);
      expect(style.dataRowHeight, 68);
      expect(style.headerRowHeight, 48);
      expect(style.frozenColumnsCount, 2);
      expect(style.headerBackgroundColor, const Color(0xFFF8FAFC));
      expect(style.headerDividerColor, const Color(0xFFE2E8F0));
      expect(style.headerTextStyle?.fontWeight, FontWeight.w800);
      expect(style.dataTextStyle?.fontSize, 14);
      expect(style.alternateRowColor, const Color(0xFFF8FAFC));
    });
  });
}

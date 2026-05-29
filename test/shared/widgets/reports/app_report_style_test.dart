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
      // Header/zebra colors are resolved from the active theme at render time
      // (theme-aware) instead of baked light-only constants, so the preset
      // leaves the explicit color overrides null and opts into zebra striping.
      expect(style.headerBackgroundColor, isNull);
      expect(style.headerDividerColor, isNull);
      expect(style.headerTextStyle?.fontWeight, FontWeight.w800);
      expect(style.dataTextStyle?.fontSize, 14);
      expect(style.alternateRowColor, isNull);
      expect(style.zebraRows, isTrue);
    });
  });
}

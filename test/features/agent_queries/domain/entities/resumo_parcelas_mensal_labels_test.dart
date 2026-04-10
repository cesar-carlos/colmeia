import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasMensalLabels', () {
    test('format zero-pads month', () {
      check(ResumoParcelasMensalLabels.format(2026, 1)).equals('2026/01');
      check(ResumoParcelasMensalLabels.format(2026, 9)).equals('2026/09');
      check(ResumoParcelasMensalLabels.format(2026, 12)).equals('2026/12');
    });

    test('format rejects month out of range', () {
      expect(
        () => ResumoParcelasMensalLabels.format(2026, 0),
        throwsArgumentError,
      );
      expect(
        () => ResumoParcelasMensalLabels.format(2026, 13),
        throwsArgumentError,
      );
    });

    test('isValidCalendarYear matches configured bounds', () {
      check(ResumoParcelasMensalLabels.isValidCalendarYear(1900)).isTrue();
      check(ResumoParcelasMensalLabels.isValidCalendarYear(2100)).isTrue();
      check(ResumoParcelasMensalLabels.isValidCalendarYear(1899)).isFalse();
      check(ResumoParcelasMensalLabels.isValidCalendarYear(2101)).isFalse();
    });

    test('formatPortugueseAbbreviated uses month abbreviations', () {
      check(
        ResumoParcelasMensalLabels.formatPortugueseAbbreviated(2026, 4),
      ).equals('abr/2026');
      check(
        ResumoParcelasMensalLabels.formatPortugueseAbbreviated(2026, 1),
      ).equals('jan/2026');
    });

    test('formatPortugueseAbbreviated rejects month out of range', () {
      expect(
        () => ResumoParcelasMensalLabels.formatPortugueseAbbreviated(2026, 0),
        throwsArgumentError,
      );
    });
  });
}

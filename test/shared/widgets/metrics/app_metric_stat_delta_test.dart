import 'package:checks/checks.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMetricDeltaSign', () {
    test('should return negative when string starts with ASCII hyphen', () {
      check(parseMetricDeltaSign('-12%')).equals(MetricDeltaSign.negative);
      check(parseMetricDeltaSign('-0,8%')).equals(MetricDeltaSign.negative);
    });

    test('should return negative when string starts with Unicode minus', () {
      final unicodeMinus = '${String.fromCharCode(0x2212)}0,5%';
      check(parseMetricDeltaSign(unicodeMinus)).equals(
        MetricDeltaSign.negative,
      );
    });

    test('should return neutral for em-dash en-dash equals approx', () {
      check(parseMetricDeltaSign('—')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('–')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('=')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('≈')).equals(MetricDeltaSign.neutral);
    });

    test('should return neutral for numeric zero deltas', () {
      check(parseMetricDeltaSign('+0%')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('+0,0%')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('-0%')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('-0,00%')).equals(MetricDeltaSign.neutral);
    });

    test('should return positive for explicit positive values', () {
      check(parseMetricDeltaSign('+12,4%')).equals(MetricDeltaSign.positive);
      check(parseMetricDeltaSign('8%')).equals(MetricDeltaSign.positive);
    });

    test('should return neutral for empty or whitespace', () {
      check(parseMetricDeltaSign('')).equals(MetricDeltaSign.neutral);
      check(parseMetricDeltaSign('   ')).equals(MetricDeltaSign.neutral);
    });
  });

  group('isZeroDeltaString', () {
    test('should detect zero after sign', () {
      check(isZeroDeltaString('+0%')).isTrue();
      check(isZeroDeltaString('-0,0%')).isTrue();
      check(isZeroDeltaString('+0,1%')).isFalse();
    });
  });

  group('splitMetricTrendLabel', () {
    test('should split on vs clause case-insensitively', () {
      final a = splitMetricTrendLabel('+12,5% vs último período');
      check(a.primary).equals('+12,5%');
      check(a.suffix).equals('vs último período');

      final b = splitMetricTrendLabel('+2% VS last period');
      check(b.primary).equals('+2%');
      check(b.suffix).equals('VS last period');
    });

    test('should return full string when no vs clause', () {
      final c = splitMetricTrendLabel('Sem mudança');
      check(c.primary).equals('Sem mudança');
      check(c.suffix).isNull();
    });
  });
}

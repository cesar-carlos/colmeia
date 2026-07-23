import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_filter_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contiguous periods have no gap', () {
    final atual = DateTimeRange(
      start: DateTime(2026, 3),
      end: DateTime(2026, 3, 31),
    );
    final anterior = DateTimeRange(
      start: DateTime(2026, 2),
      end: DateTime(2026, 2, 28),
    );
    check(salesTrendPeriodsHaveGap(atual, anterior)).isFalse();
  });

  test('non-contiguous custom periods report a gap', () {
    final atual = DateTimeRange(
      start: DateTime(2026, 3, 10),
      end: DateTime(2026, 3, 20),
    );
    final anterior = DateTimeRange(
      start: DateTime(2026, 2),
      end: DateTime(2026, 2, 10),
    );
    check(salesTrendPeriodsHaveGap(atual, anterior)).isTrue();
  });
}

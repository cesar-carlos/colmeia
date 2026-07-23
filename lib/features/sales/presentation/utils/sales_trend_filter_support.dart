import 'package:flutter/material.dart';

/// True when [anterior] and [atual] are not contiguous and not an allowed
/// aligned pair (full-month or month-to-date), so the UI can warn managers.
bool salesTrendPeriodsHaveGap(DateTimeRange atual, DateTimeRange anterior) {
  final atualStart = DateTime(
    atual.start.year,
    atual.start.month,
    atual.start.day,
  );
  final anteriorEnd = DateTime(
    anterior.end.year,
    anterior.end.month,
    anterior.end.day,
  );
  final expectedAtualStart = anteriorEnd.add(const Duration(days: 1));
  if (atualStart == expectedAtualStart) {
    return false;
  }

  final atualIsFullMonth = _isWholeMonth(atual);
  final anteriorIsFullMonth = _isWholeMonth(anterior);
  if (atualIsFullMonth && anteriorIsFullMonth) {
    final expectedPrevEnd = DateTime(atualStart.year, atualStart.month, 0);
    return anteriorEnd != expectedPrevEnd;
  }

  if (atualStart.day == 1 &&
      DateTime(anterior.start.year, anterior.start.month, anterior.start.day)
              .day ==
          1) {
    final expectedPrevStart = DateTime(atualStart.year, atualStart.month - 1);
    final antStart = DateTime(
      anterior.start.year,
      anterior.start.month,
      anterior.start.day,
    );
    if (antStart == expectedPrevStart) {
      return false;
    }
  }

  return true;
}

bool _isWholeMonth(DateTimeRange range) {
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day);
  if (start.day != 1) {
    return false;
  }
  final lastDay = DateTime(end.year, end.month + 1, 0).day;
  return end.day == lastDay &&
      end.year == start.year &&
      end.month == start.month;
}

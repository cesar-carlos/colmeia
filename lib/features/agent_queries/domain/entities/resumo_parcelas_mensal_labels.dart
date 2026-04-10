abstract final class ResumoParcelasMensalLabels {
  static const int minCalendarYear = 1900;
  static const int maxCalendarYear = 2100;

  static const List<String> _mesAbrevPt = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  /// Whether [ano] is in the supported reporting range for merge/fill.
  static bool isValidCalendarYear(int ano) =>
      ano >= minCalendarYear && ano <= maxCalendarYear;

  /// Canonical `YYYY/MM` label (month zero-padded).
  static String format(int ano, int mes) {
    if (mes < 1 || mes > 12) {
      throw ArgumentError.value(mes, 'mes', 'Expected month in range 1..12');
    }
    return '$ano/${mes.toString().padLeft(2, '0')}';
  }

  /// Short Portuguese month abbreviation for UI (e.g. `abr/2026`).
  ///
  /// Domain keeps [format] as the stable sort key; use this only in views.
  static String formatPortugueseAbbreviated(int ano, int mes) {
    if (mes < 1 || mes > 12) {
      throw ArgumentError.value(mes, 'mes', 'Expected month in range 1..12');
    }
    return '${_mesAbrevPt[mes - 1]}/$ano';
  }
}

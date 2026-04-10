/// Portuguese weekday names for `diaSemanaNumero` (1 = Sunday … 7 = Saturday).
///
/// Numbers follow Sunday = 1 through Saturday = 7, independent of SQL
/// session settings when the query uses the same numbering rule.
abstract final class ResumoParcelasDiaSemanaLabels {
  static const List<String> _ordered = <String>[
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];

  /// Returns the display name for [diaSemanaNumero] in 1..7.
  static String labelFor(int diaSemanaNumero) {
    if (diaSemanaNumero < 1 || diaSemanaNumero > 7) {
      throw FormatException(
        'diaSemanaNumero must be 1..7, got $diaSemanaNumero',
      );
    }
    return _ordered[diaSemanaNumero - 1];
  }
}

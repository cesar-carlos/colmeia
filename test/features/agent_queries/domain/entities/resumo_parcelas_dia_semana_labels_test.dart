import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaLabels', () {
    test('labelFor maps 1..7 to Portuguese names', () {
      check(ResumoParcelasDiaSemanaLabels.labelFor(1)).equals('Domingo');
      check(ResumoParcelasDiaSemanaLabels.labelFor(7)).equals('Sábado');
    });

    test('labelFor throws for out of range', () {
      expect(
        () => ResumoParcelasDiaSemanaLabels.labelFor(0),
        throwsFormatException,
      );
      expect(
        () => ResumoParcelasDiaSemanaLabels.labelFor(8),
        throwsFormatException,
      );
    });
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasSqlDimensionFilters', () {
    test('validationError returns null for valid optional dimensions', () {
      check(
        ResumoParcelasSqlDimensionFilters.validationError(
          codEmpresa: 1,
          codFilial: 2,
          codVendedor: 3,
        ),
      ).isNull();
      check(
        ResumoParcelasSqlDimensionFilters.validationError(),
      ).isNull();
    });

    test('validationError rejects non-positive codes', () {
      check(
        ResumoParcelasSqlDimensionFilters.validationError(codEmpresa: 0),
      ).isNotNull();
      check(
        ResumoParcelasSqlDimensionFilters.validationError(codFilial: -1),
      ).isNotNull();
      check(
        ResumoParcelasSqlDimensionFilters.validationError(codVendedor: 0),
      ).isNotNull();
    });

    test('validationError requires codEmpresa when codFilial is set', () {
      check(
        ResumoParcelasSqlDimensionFilters.validationError(codFilial: 1),
      ).isNotNull();
    });

    test('namedParams forwards nulls for unset dimensions', () {
      check(
        ResumoParcelasSqlDimensionFilters.namedParams(),
      ).deepEquals(<String, Object?>{
        'codEmpresa': null,
        'codFilial': null,
        'codVendedor': null,
      });
      check(
        ResumoParcelasSqlDimensionFilters.namedParams(
          codEmpresa: 9,
          codVendedor: 7,
        ),
      ).deepEquals(<String, Object?>{
        'codEmpresa': 9,
        'codFilial': null,
        'codVendedor': 7,
      });
    });

    test('literalWhereLines is empty when dimensions unset', () {
      check(ResumoParcelasSqlDimensionFilters.literalWhereLines()).equals('');
    });

    test('literalWhereLines emits AND lines for set dimensions', () {
      check(
        ResumoParcelasSqlDimensionFilters.literalWhereLines(
          codEmpresa: 9,
          codFilial: 3,
          codVendedor: 7,
        ),
      ).equals(
        '      AND CodEmpresa = 9\n'
        '      AND CodFilial = 3\n'
        '      AND CodVendedor = 7',
      );
    });

    test('embedLiteralDimensionWhere replaces placeholder', () {
      final template = 'WHERE 1=1\n'
          '${ResumoParcelasSqlDimensionFilters.resumoParcelasWhereDimensionPlaceholder}\n'
          'GROUP BY x';
      check(
        ResumoParcelasSqlDimensionFilters.embedLiteralDimensionWhere(
          template,
          codEmpresa: 1,
        ),
      ).equals(
        'WHERE 1=1\n'
        '      AND CodEmpresa = 1\n'
        'GROUP BY x',
      );
    });
  });
}

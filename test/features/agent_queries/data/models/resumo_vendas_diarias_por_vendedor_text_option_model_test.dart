import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_text_option_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fromBairroMap', () {
    test('accepts PascalCase', () {
      final model = ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
        <String, dynamic>{'Bairro': '  Centro  '},
      );
      check(model.value).equals('Centro');
      check(model.toEntity().value).equals('Centro');
    });

    test('accepts camelCase and lowercase', () {
      final camel = ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
        <String, dynamic>{'bairro': 'Sul'},
      );
      final lower = ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
        <String, dynamic>{'bairro': 'Norte'},
      );
      check(camel.value).equals('Sul');
      check(lower.value).equals('Norte');
    });

    test('throws when bairro missing or blank', () {
      expect(
        () => ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
          <String, dynamic>{},
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
          <String, dynamic>{'Bairro': '  '},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('fromMunicipioMap', () {
    test('accepts PascalCase', () {
      final model =
          ResumoVendasDiariasPorVendedorTextOptionModel.fromMunicipioMap(
            <String, dynamic>{'NomeMunicipio': ' Curitiba '},
          );
      check(model.value).equals('Curitiba');
    });

    test('accepts camelCase', () {
      final model =
          ResumoVendasDiariasPorVendedorTextOptionModel.fromMunicipioMap(
            <String, dynamic>{'nomeMunicipio': 'Maringa'},
          );
      check(model.value).equals('Maringa');
    });

    test('throws when municipio missing or blank', () {
      expect(
        () => ResumoVendasDiariasPorVendedorTextOptionModel.fromMunicipioMap(
          <String, dynamic>{},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

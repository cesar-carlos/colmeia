import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/municipio_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps PascalCase row to entity', () {
    final model = MunicipioRowModel.fromMap(<String, dynamic>{
      'CodMunicipio': 4106902,
      'NomeMunicipio': 'Curitiba',
      'CodigoIBGE': '4106902',
      'NomeEstado': 'Parana',
      'UF': 'PR',
    });
    check(model.codMunicipio).equals(4106902);
    check(model.nomeMunicipio).equals('Curitiba');
    check(model.codigoIbge).equals('4106902');
    check(model.nomeEstado).equals('Parana');
    check(model.uf).equals('PR');

    final entity = model.toEntity();
    check(entity.codMunicipio).equals(4106902);
    check(entity.codigoIbge).equals('4106902');
  });

  test('CodigoIBGE null yields null in model and entity', () {
    final model = MunicipioRowModel.fromMap(<String, dynamic>{
      'CodMunicipio': 1,
      'NomeMunicipio': 'X',
      'CodigoIBGE': null,
      'NomeEstado': 'Y',
      'UF': 'Z',
    });
    check(model.codigoIbge).isNull();
    check(model.toEntity().codigoIbge).isNull();
  });

  test('accepts int CodMunicipio from num bridge', () {
    final model = MunicipioRowModel.fromMap(<String, dynamic>{
      'codMunicipio': 42,
      'nomeMunicipio': 'A',
      'nomeEstado': 'B',
      'uf': 'C',
    });
    check(model.codMunicipio).equals(42);
  });
}

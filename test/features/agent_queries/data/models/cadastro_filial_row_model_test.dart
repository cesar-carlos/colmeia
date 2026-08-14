import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/cadastro_filial_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadastroFilialRowModel', () {
    test('fromMap trims municipio and keeps only CEP digits', () {
      final model = CadastroFilialRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 2,
          'NomeFilial': ' Filial Centro ',
          'NomeFantasia': ' Loja Centro ',
          'CNPJ': '12.345.678/0001-90',
          'Endereco': ' Rua A ',
          'NumeroEndereco': 123,
          'Bairro': ' Centro ',
          'CEP': '78.005- 123A',
          'CodMunicipio': '5103403',
          'NomeMunicipio': ' Cuiaba ',
          'CodigoIBGE': 5103403,
          'UFMunicipio': ' MT ',
        },
      );

      final entity = model.toEntity();
      check(entity.codEmpresa).equals(1);
      check(entity.codFilial).equals(2);
      check(entity.nomeFilial).equals('Filial Centro');
      check(entity.nomeFantasia).equals('Loja Centro');
      check(entity.numeroEndereco).equals('123');
      check(entity.cep).equals('78005123');
      check(entity.codMunicipio).equals(5103403);
      check(entity.nomeMunicipio).equals('Cuiaba');
      check(entity.codigoIbge).equals('5103403');
      check(entity.ufMunicipio).equals('MT');
    });

    test('fromMap accepts lowercase keys and nullable optional fields', () {
      final model = CadastroFilialRowModel.fromMap(
        <String, dynamic>{
          'codempresa': 1,
          'codfilial': 0,
          'nomefilial': 'Matriz',
          'cep': '',
          'nomemunicipio': null,
        },
      );

      final entity = model.toEntity();
      check(entity.codFilial).equals(0);
      check(entity.cep).isNull();
      check(entity.nomeMunicipio).isNull();
    });

    test('fromMap falls back to fantasy name when NomeFilial is empty', () {
      final model = CadastroFilialRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 2,
          'NomeFilial': '  ',
          'NomeFantasia': ' Loja Centro ',
        },
      );

      check(model.toEntity().nomeFilial).equals('Loja Centro');
    });

    test('fromMap falls back to company/branch codes when names are empty', () {
      final model = CadastroFilialRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 0,
          'NomeFilial': '',
        },
      );

      check(model.toEntity().nomeFilial).equals('1/0');
    });
  });
}

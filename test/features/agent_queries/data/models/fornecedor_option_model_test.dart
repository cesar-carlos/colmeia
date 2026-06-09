import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/fornecedor_option_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FornecedorOptionModel', () {
    test('fromMap accepts PascalCase keys and maps entity', () {
      final model = FornecedorOptionModel.fromMap(
        <String, dynamic>{
          'CodFornecedor': 42,
          'NomeFornecedor': 'ACME LTDA',
          'NomeFantasia': 'ACME',
          'CNPJ_CPF': '12.345.678/0001-90',
          'EMail': 'contato@acme.com',
          'Telefone': '1133334444',
          'Endereco': 'Rua A',
          'NumeroEndereco': '100',
          'Bairro': 'Centro',
          'Complemento': null,
          'CEP': '01000-000',
          'CodMunicipio': 3550308,
          'NomeMunicipio': 'São Paulo',
          'UFMunicipio': 'SP',
          'CodigoIBGE': '3550308',
        },
      );

      check(model.codFornecedor).equals(42);
      check(model.codigoIbge).equals('3550308');

      final entity = model.toEntity();
      check(entity.codFornecedor).equals(42);
      check(entity.codigoIbge).equals('3550308');
      check(entity.displayLabel).equals('ACME LTDA (ACME · 12.345.678/0001-90)');
    });

    test('fromMap coerces int CodigoIBGE from bridge', () {
      final model = FornecedorOptionModel.fromMap(
        <String, dynamic>{
          'CodFornecedor': 1,
          'NomeFornecedor': 'X',
          'NomeMunicipio': 'Sinop',
          'UFMunicipio': 'MT',
          'CodigoIBGE': 5107909,
        },
      );

      check(model.codigoIbge).equals('5107909');
      check(model.toEntity().codigoIbge).equals('5107909');
    });

    test('CodigoIBGE null yields null in model and entity', () {
      final model = FornecedorOptionModel.fromMap(
        <String, dynamic>{
          'CodFornecedor': 1,
          'NomeFornecedor': 'X',
          'NomeMunicipio': 'Y',
          'UFMunicipio': 'Z',
          'CodigoIBGE': null,
        },
      );

      check(model.codigoIbge).isNull();
      check(model.toEntity().codigoIbge).isNull();
    });
  });
}

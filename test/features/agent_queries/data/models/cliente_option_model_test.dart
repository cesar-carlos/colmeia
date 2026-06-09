import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/cliente_option_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClienteOptionModel', () {
    test('fromMap accepts PascalCase keys and maps entity subset', () {
      final model = ClienteOptionModel.fromMap(
        <String, dynamic>{
          'CodCliente': 42,
          'NomeCliente': 'ACME LTDA',
          'NomeFantasia': 'ACME',
          'CNPJ_CPF': '12.345.678/0001-90',
          'EMail': 'contato@acme.com',
          'Telefone': '4133334444',
          'Celular': '4199998888',
          'Endereco': 'Rua A',
          'NumeroEndereco': '100',
          'Bairro': 'Centro',
          'Complemento': 'Sala 1',
          'CEP': '80000000',
          'CodMunicipio': 7,
          'NomeMunicipio': 'Curitiba',
          'UFMunicipio': 'PR',
          'CodigoIBGE': '4106902',
        },
      );

      check(model.codCliente).equals(42);
      check(model.nomeCliente).equals('ACME LTDA');
      check(model.nomeFantasia).equals('ACME');
      check(model.cnpjCpf).equals('12.345.678/0001-90');
      check(model.codMunicipio).equals(7);
      check(model.codigoIbge).equals('4106902');

      final entity = model.toEntity();
      check(entity.codCliente).equals(42);
      check(entity.codigoIbge).equals('4106902');
      check(entity.displayLabel).equals('ACME LTDA (ACME)');
      check(entity.municipioDisplay).equals('Curitiba - PR');
    });

    test('fromMap coerces int CodigoIBGE from bridge', () {
      final model = ClienteOptionModel.fromMap(
        <String, dynamic>{
          'CodCliente': 1,
          'NomeCliente': 'X',
          'NomeMunicipio': 'Sinop',
          'UFMunicipio': 'MT',
          'CodigoIBGE': 5107909,
        },
      );

      check(model.codigoIbge).equals('5107909');
      check(model.toEntity().codigoIbge).equals('5107909');
    });

    test('CodigoIBGE null yields null in model and entity', () {
      final model = ClienteOptionModel.fromMap(
        <String, dynamic>{
          'CodCliente': 1,
          'NomeCliente': 'X',
          'NomeMunicipio': 'Y',
          'UFMunicipio': 'Z',
          'CodigoIBGE': null,
        },
      );

      check(model.codigoIbge).isNull();
      check(model.toEntity().codigoIbge).isNull();
    });

    test('fromMap throws FormatException when CodCliente is missing', () {
      expect(
        () => ClienteOptionModel.fromMap(
          <String, dynamic>{'NomeCliente': 'A'},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/grupo_produto_option_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GrupoProdutoOptionModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = GrupoProdutoOptionModel.fromMap(
        <String, dynamic>{
          'codGrupoProduto': 13,
          'nomeGrupoProduto': 'ACESSORIOS',
        },
      );
      check(model.codGrupoProduto).equals(13);
      check(model.nomeGrupoProduto).equals('ACESSORIOS');
      check(model.toEntity().codGrupoProduto).equals(13);
    });

    test('fromMap parses integer from string and trims name', () {
      final model = GrupoProdutoOptionModel.fromMap(
        <String, dynamic>{
          'CodGrupoProduto': '14',
          'NomeGrupoProduto': '  SUSPENSAO  ',
        },
      );
      check(model.codGrupoProduto).equals(14);
      check(model.nomeGrupoProduto).equals('SUSPENSAO');
    });

    test('fromMap throws FormatException when CodGrupoProduto is missing', () {
      expect(
        () => GrupoProdutoOptionModel.fromMap(
          <String, dynamic>{'NomeGrupoProduto': 'A'},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

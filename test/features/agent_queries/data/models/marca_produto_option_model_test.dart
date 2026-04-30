import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/marca_produto_option_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarcaProdutoOptionModel', () {
    test('fromMap accepts lowercase keys', () {
      final model = MarcaProdutoOptionModel.fromMap(
        <String, dynamic>{
          'codmarca': 490,
          'nomemarca': 'SMART FOX',
        },
      );
      check(model.codMarca).equals(490);
      check(model.nomeMarca).equals('SMART FOX');
      check(model.toEntity().nomeMarca).equals('SMART FOX');
    });

    test('fromMap parses integer from string and trims name', () {
      final model = MarcaProdutoOptionModel.fromMap(
        <String, dynamic>{
          'CodMarca': '10',
          'NomeMarca': '  TRILHA  ',
        },
      );
      check(model.codMarca).equals(10);
      check(model.nomeMarca).equals('TRILHA');
    });

    test('fromMap throws FormatException when NomeMarca is missing', () {
      expect(
        () => MarcaProdutoOptionModel.fromMap(
          <String, dynamic>{'CodMarca': 1},
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

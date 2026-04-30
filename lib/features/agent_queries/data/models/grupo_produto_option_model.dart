import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';

class GrupoProdutoOptionModel {
  const GrupoProdutoOptionModel({
    required this.codGrupoProduto,
    required this.nomeGrupoProduto,
  });

  factory GrupoProdutoOptionModel.fromMap(Map<String, dynamic> map) {
    return GrupoProdutoOptionModel(
      codGrupoProduto: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodGrupoProduto'),
      ),
      nomeGrupoProduto: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeGrupoProduto'),
      ),
    );
  }

  final int codGrupoProduto;
  final String nomeGrupoProduto;

  GrupoProdutoOption toEntity() {
    return GrupoProdutoOption(
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
    );
  }
}

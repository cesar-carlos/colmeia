import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';

class MarcaProdutoOptionModel {
  const MarcaProdutoOptionModel({
    required this.codMarca,
    required this.nomeMarca,
  });

  factory MarcaProdutoOptionModel.fromMap(Map<String, dynamic> map) {
    return MarcaProdutoOptionModel(
      codMarca: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMarca'),
      ),
      nomeMarca: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeMarca'),
      ),
    );
  }

  final int codMarca;
  final String nomeMarca;

  MarcaProdutoOption toEntity() {
    return MarcaProdutoOption(
      codMarca: codMarca,
      nomeMarca: nomeMarca,
    );
  }
}

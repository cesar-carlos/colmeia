import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';

/// Product group and brand catalog options from a single `sql.executeBatch`.
class GrupoMarcaProdutoOptionsBatch {
  const GrupoMarcaProdutoOptionsBatch({
    required this.grupoOptions,
    required this.marcaOptions,
  });

  final List<GrupoProdutoOption> grupoOptions;
  final List<MarcaProdutoOption> marcaOptions;
}

import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';

/// Named binds for the entrada-note line-item query.
abstract final class NotasEntradaItensSqlParams {
  static Map<String, Object?> namedParamsFor(NotasEntradaItensFilter filter) {
    return <String, Object?>{'compraId': filter.compraId};
  }
}

import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';

/// Header context passed when opening the entrada-note items screen.
class SalesNotasEntradaItensRouteExtra {
  const SalesNotasEntradaItensRouteExtra({
    required this.note,
    this.agentId,
  });

  final NotaEntradaRow note;
  final String? agentId;

  static SalesNotasEntradaItensRouteExtra? tryParse(Object? extra) {
    return extra is SalesNotasEntradaItensRouteExtra ? extra : null;
  }
}

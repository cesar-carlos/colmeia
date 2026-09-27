import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_itens_route_extra.dart';
import 'package:flutter/widgets.dart';

void pushSalesNotasEntradaItens(
  BuildContext context, {
  required NotaEntradaRow row,
  String? agentId,
}) {
  final trimmedAgentId = agentId?.trim();
  unawaited(
    context.pushTo<void>(
      AppRoute.salesNotasEntradaItens,
      pathParameters: <String, String>{'compraId': '${row.compraId}'},
      extra: SalesNotasEntradaItensRouteExtra(
        note: row,
        agentId: trimmedAgentId == null || trimmedAgentId.isEmpty
            ? null
            : trimmedAgentId,
      ),
    ),
  );
}

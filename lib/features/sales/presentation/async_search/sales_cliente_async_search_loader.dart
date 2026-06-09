import 'package:colmeia/features/agent_queries/application/usecases/load_cliente_options_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_options_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/presentation/async_search/sales_produto_dimension_async_search_loaders.dart';
import 'package:colmeia/shared/widgets/forms/app_async_search_field.dart';

AppAsyncSearchLoader<int> createSalesClienteAsyncSearchLoader({
  required LoadClienteOptionsUseCase useCase,
  required String userId,
  required SalesAgentIdProvider agentIdProvider,
  required SalesClientTokenResolver resolveClientToken,
  required String clientTokenUnavailableMessage,
  AgentQueriesCancelScope? cancelScope,
}) {
  return (AppAsyncSearchQuery query) async {
    final agentId = agentIdProvider()?.trim();
    if (userId.trim().isEmpty || agentId == null || agentId.isEmpty) {
      return const AppAsyncSearchLoadResult<int>(
        options: <AppAsyncSearchOption<int>>[],
        hasMore: false,
      );
    }

    final clientToken = await resolveClientToken(agentId);
    if (clientToken == null || clientToken.trim().isEmpty) {
      return AppAsyncSearchLoadResult<int>(
        options: const <AppAsyncSearchOption<int>>[],
        hasMore: false,
        errorMessage: clientTokenUnavailableMessage,
      );
    }

    final result = await useCase(
      userId: userId,
      agentId: agentId,
      filter: ClienteOptionsFilter(
        searchTerm: query.searchTerm,
        page: query.page,
        pageSize: query.pageSize,
      ),
      clientToken: clientToken,
      cancelScope: cancelScope,
    );

    return result.fold(
      (page) => AppAsyncSearchLoadResult<int>(
        options: page.items
            .map(
              (option) => AppAsyncSearchOption<int>(
                value: option.codCliente,
                label: option.displayLabel,
              ),
            )
            .toList(growable: false),
        hasMore: page.items.length >= query.pageSize,
      ),
      (failure) => AppAsyncSearchLoadResult<int>(
        options: const <AppAsyncSearchOption<int>>[],
        hasMore: false,
        errorMessage: failure.displayMessage,
      ),
    );
  };
}

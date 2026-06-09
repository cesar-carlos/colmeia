import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/shared/widgets/forms/app_async_search_field.dart';

typedef SalesAgentIdProvider = String? Function();

typedef SalesClientTokenResolver = Future<String?> Function(String agentId);

typedef SalesProdutoDimensionLoaderFactory = AppAsyncSearchLoader<int> Function(
  SalesAgentIdProvider agentIdProvider,
);

AppAsyncSearchLoader<int> createSalesGrupoProdutoAsyncSearchLoader({
  required LoadGrupoProdutoOptionsUseCase useCase,
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
      page: query.page,
      pageSize: query.pageSize,
      searchTerm: query.searchTerm,
      clientToken: clientToken,
      cancelScope: cancelScope,
    );

    return result.fold(
      (options) => AppAsyncSearchLoadResult<int>(
        options: options
            .map(
              (option) => AppAsyncSearchOption<int>(
                value: option.codGrupoProduto,
                label: option.nomeGrupoProduto,
              ),
            )
            .toList(growable: false),
        hasMore: options.length >= query.pageSize,
      ),
      (failure) => AppAsyncSearchLoadResult<int>(
        options: const <AppAsyncSearchOption<int>>[],
        hasMore: false,
        errorMessage: failure.displayMessage,
      ),
    );
  };
}

AppAsyncSearchLoader<int> createSalesMarcaProdutoAsyncSearchLoader({
  required LoadMarcaProdutoOptionsUseCase useCase,
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
      page: query.page,
      pageSize: query.pageSize,
      searchTerm: query.searchTerm,
      clientToken: clientToken,
      cancelScope: cancelScope,
    );

    return result.fold(
      (options) => AppAsyncSearchLoadResult<int>(
        options: options
            .map(
              (option) => AppAsyncSearchOption<int>(
                value: option.codMarca,
                label: option.nomeMarca,
              ),
            )
            .toList(growable: false),
        hasMore: options.length >= query.pageSize,
      ),
      (failure) => AppAsyncSearchLoadResult<int>(
        options: const <AppAsyncSearchOption<int>>[],
        hasMore: false,
        errorMessage: failure.displayMessage,
      ),
    );
  };
}

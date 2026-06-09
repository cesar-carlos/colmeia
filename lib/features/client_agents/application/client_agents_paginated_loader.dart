import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:result_dart/result_dart.dart';

/// Safety cap for unfiltered list hydration (50 items/page × 100 pages).
const int kClientAgentsMaxPaginatedPages = 100;

Future<AppResult<PaginatedResult<T>>> loadAllClientAgentsPages<T>({
  required Future<AppResult<PaginatedResult<T>>> Function(PaginatedQuery query)
  loadPage,
  required PaginatedQuery query,
  String? search,
  String? status,
}) async {
  if (search != null || status != null) {
    return loadPage(query);
  }

  final firstResult = await loadPage(query);
  return firstResult.fold(
    (first) async {
      if (first.total <= first.items.length ||
          first.items.length < query.pageSize) {
        return Success<PaginatedResult<T>, AppFailure>(first);
      }

      final mergedItems = List<T>.from(first.items);
      var page = query.page + 1;
      var pagesFetched = 1;

      while (mergedItems.length < first.total &&
          pagesFetched < kClientAgentsMaxPaginatedPages) {
        final nextResult = await loadPage(query.copyWith(page: page));
        final failure = nextResult.exceptionOrNull();
        if (failure != null) {
          return Failure<PaginatedResult<T>, AppFailure>(failure);
        }
        final next = nextResult.getOrNull()!;
        if (next.items.isEmpty) {
          break;
        }
        mergedItems.addAll(next.items);
        page++;
        pagesFetched++;
      }

      return Success<PaginatedResult<T>, AppFailure>(
        PaginatedResult<T>(
          items: mergedItems,
          count: mergedItems.length,
          total: first.total,
          page: query.page,
          pageSize: query.pageSize,
          isStaleCache: first.isStaleCache,
        ),
      );
    },
    (failure) async => Failure<PaginatedResult<T>, AppFailure>(failure),
  );
}

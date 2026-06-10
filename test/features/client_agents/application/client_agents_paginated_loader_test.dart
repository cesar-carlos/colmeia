import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/application/client_agents_paginated_loader.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('loadAllClientAgentsPages', () {
    test('merges subsequent pages until total is reached', () async {
      const query = PaginatedQuery(pageSize: 2);
      var callCount = 0;

      final result = await loadAllClientAgentsPages<String>(
        query: query,
        loadPage: (pageQuery) async {
          callCount++;
          if (pageQuery.page == 1) {
            return const Success<PaginatedResult<String>, AppFailure>(
              PaginatedResult<String>(
                items: <String>['a', 'b'],
                count: 2,
                total: 4,
                page: 1,
                pageSize: 2,
              ),
            );
          }
          if (pageQuery.page == 2) {
            return const Success<PaginatedResult<String>, AppFailure>(
              PaginatedResult<String>(
                items: <String>['c', 'd'],
                count: 2,
                total: 4,
                page: 2,
                pageSize: 2,
              ),
            );
          }
          return Success<PaginatedResult<String>, AppFailure>(
            PaginatedResult<String>(
              items: const <String>[],
              count: 0,
              total: 4,
              page: pageQuery.page,
              pageSize: 2,
            ),
          );
        },
      );

      expect(result.isSuccess(), isTrue);
      expect(callCount, 2);
      expect(result.getOrNull()?.items, <String>['a', 'b', 'c', 'd']);
      expect(result.getOrNull()?.total, 4);
    });

    test(
      'marks result truncated when page cap is reached before total',
      () async {
        const pageSize = 2;
        const query = PaginatedQuery(pageSize: pageSize);
        var callCount = 0;

        final result = await loadAllClientAgentsPages<String>(
          query: query,
          loadPage: (pageQuery) async {
            callCount++;
            return Success<PaginatedResult<String>, AppFailure>(
              PaginatedResult<String>(
                items: List<String>.generate(
                  pageSize,
                  (i) => 'p${pageQuery.page}-$i',
                ),
                count: pageSize,
                total: pageSize * kClientAgentsMaxPaginatedPages + 10,
                page: pageQuery.page,
                pageSize: pageSize,
              ),
            );
          },
        );

        expect(result.isSuccess(), isTrue);
        expect(callCount, kClientAgentsMaxPaginatedPages);
        final page = result.getOrNull()!;
        expect(page.isResultTruncated, isTrue);
        expect(page.items.length, pageSize * kClientAgentsMaxPaginatedPages);
        expect(page.total, greaterThan(page.items.length));
      },
    );

    test('returns first page only when search filter is active', () async {
      var callCount = 0;

      final result = await loadAllClientAgentsPages<String>(
        query: const PaginatedQuery(pageSize: 2),
        search: 'agent-1',
        loadPage: (_) async {
          callCount++;
          return const Success<PaginatedResult<String>, AppFailure>(
            PaginatedResult<String>(
              items: <String>['match'],
              count: 1,
              total: 10,
              page: 1,
              pageSize: 2,
            ),
          );
        },
      );

      expect(result.isSuccess(), isTrue);
      expect(callCount, 1);
      expect(result.getOrNull()?.items, <String>['match']);
    });
  });
}

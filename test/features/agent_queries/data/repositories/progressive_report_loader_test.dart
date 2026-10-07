import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/paged_report_progress_loader.dart';
import 'package:colmeia/features/agent_queries/data/repositories/progressive_report_loader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

class _Page {
  const _Page(this.rows, this.total);
  final List<int> rows;
  final int total;
}

void main() {
  test(
    'should emit typed rows before completion and preserve the final snapshot',
    () async {
      final finish = Completer<AppResult<List<int>>>();
      final first = Completer<void>();
      final events = <AppResult<AgentQueryProgress<int>>>[];
      final stream = const ProgressiveReportLoader<int>().load(
        mapRows: (execution) =>
            execution.rows.map((r) => r['id'] as int).toList(),
        execute: (scope) {
          scope.progressObserver!.publish(
            const AgentSqlExecutionResult(
              rows: [
                {'id': 1},
              ],
              rowCount: 1,
            ),
          );
          return finish.future;
        },
      );
      final done = Completer<void>();
      stream.listen((event) {
        events.add(event);
        if (!first.isCompleted) first.complete();
      }, onDone: done.complete);
      await first.future;
      expect(events.single.getOrThrow().isComplete, false);
      expect(events.single.getOrThrow().rows, [1]);
      finish.complete(const Success([1, 2]));
      await done.future;
      expect(events.last.getOrThrow().isComplete, true);
      expect(events.last.getOrThrow().rows, [1, 2]);
    },
  );
  test(
    'should retain failure after partial rows instead of completing',
    () async {
      final events = await const ProgressiveReportLoader<int>()
          .loadBatches(
            execute: (scope, publish) async {
              publish([1]);
              return const Failure(NetworkFailure(message: 'lost'));
            },
          )
          .toList();
      expect(events.first.getOrThrow().isComplete, false);
      expect(events.last.isError(), true);
    },
  );
  test('should cancel owned work when the subscription is abandoned', () async {
    final pending = Completer<AppResult<List<int>>>();
    AgentQueriesCancelScope? owned;
    final subscription = const ProgressiveReportLoader<int>()
        .loadBatches(
          execute: (scope, publish) {
            owned = scope;
            publish([1]);
            return pending.future;
          },
        )
        .listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    expect(owned!.isCancelled, true);
    pending.complete(const Success([1]));
  });
  for (final (label, second) in [
    ('changed total', const _Page([3], 4)),
    ('duplicate identity', const _Page([1], 3)),
    ('short page', const _Page([], 3)),
  ]) {
    test('should reject $label after a partial page', () async {
      final events = await const PagedReportProgressLoader<_Page, int>()
          .load(
            loadPage: (page, scope) async =>
                Success(page == 1 ? const _Page([1, 2], 3) : second),
            items: (p) => p.rows,
            totalCount: (p) => p.total,
            rowKey: (r) => r,
            pageSize: 2,
            maxRows: 10,
          )
          .toList();
      expect(events.first.getOrThrow().rows, [1, 2]);
      expect(events.last.isError(), true);
    });
  }
  test(
    'should collect pages with stable numbering and complete exactly once',
    () async {
      final calls = <int>[];
      final events = await const PagedReportProgressLoader<_Page, int>()
          .load(
            loadPage: (page, scope) async {
              calls.add(page);
              return Success(
                page == 1 ? const _Page([1, 2], 3) : const _Page([3], 3),
              );
            },
            items: (p) => p.rows,
            totalCount: (p) => p.total,
            rowKey: (r) => r,
            pageSize: 2,
            maxRows: 10,
          )
          .toList();
      expect(calls, [1, 2]);
      expect(events.last.getOrThrow().rows, [1, 2, 3]);
      expect(events.last.getOrThrow().isComplete, true);
    },
  );
  test(
    'should reject row limits before publishing an oversized catalog',
    () async {
      final events = await const PagedReportProgressLoader<_Page, int>()
          .load(
            loadPage: (page, scope) async => const Success(_Page([1, 2], 3)),
            items: (p) => p.rows,
            totalCount: (p) => p.total,
            rowKey: (r) => r,
            pageSize: 2,
            maxRows: 2,
          )
          .toList();
      expect(events.single.exceptionOrNull(), isA<ValidationFailure>());
    },
  );
}

import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/controllers/progressive_report_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  test('cancellation during the initial notification prevents starting the producer', () async {
    final controller = ProgressiveReportController<int>();
    addTearDown(controller.dispose);
    var started = false;
    controller.addListener(() {
      if (controller.isLoading) controller.cancel();
    });
    final result = await controller.load((_) {
      started = true;
      return const Stream.empty();
    });
    expect(result.exceptionOrNull(), isA<OperationCancelledFailure>());
    expect(started, false);
    expect(controller.isLoading, false);
  });
  test(
    'parent cancellation ends the awaited load and abandons its subscription',
    () async {
      final controller = ProgressiveReportController<int>();
      addTearDown(controller.dispose);
      var cancelled = false;
      final source = StreamController<AppResult<AgentQueryProgress<int>>>(
        onCancel: () => cancelled = true,
      );
      final parent = AgentQueriesCancelScope();
      final result = controller.load((_) => source.stream, cancelScope: parent);
      parent.cancelAll();
      expect(
        (await result).exceptionOrNull(),
        isA<OperationCancelledFailure>(),
      );
      expect(controller.isLoading, false);
      expect(cancelled, true);
      await source.close();
    },
  );

  test(
    'dispose completes a pending load even when the producer never responds',
    () async {
      final controller = ProgressiveReportController<int>();
      final source = StreamController<AppResult<AgentQueryProgress<int>>>();
      final result = controller.load((_) => source.stream);
      controller.dispose();
      expect(
        (await result).exceptionOrNull(),
        isA<OperationCancelledFailure>(),
      );
      await source.close();
    },
  );
  test(
    'synchronous startup failure ends loading and cancels owned work',
    () async {
      final controller = ProgressiveReportController<int>();
      addTearDown(controller.dispose);
      AgentQueriesCancelScope? owned;
      await controller.load((scope) {
        owned = scope;
        throw StateError('loader startup failed');
      });
      expect(controller.isLoading, false);
      expect(controller.isComplete, false);
      expect(controller.canExport, false);
      expect(controller.failure, isA<UnknownFailure>());
      expect(owned!.isCancelled, true);
    },
  );
  test('should publish first rows immediately and throttle subsequent notifications', () async {
    final source = StreamController<AppResult<AgentQueryProgress<int>>>();
    final controller = ProgressiveReportController<int>();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    unawaited(controller.load((_) => source.stream));
    source.add(
      Success(
        AgentQueryProgress(rows: [1], isComplete: false, receivedRowCount: 1),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.rows, [1]);
    expect(notifications, 2);
    source.add(
      Success(
        AgentQueryProgress(rows: [2], isComplete: false, receivedRowCount: 2),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 2);
    expect(controller.canExport, false);
    source.add(
      Success(
        AgentQueryProgress(rows: [1, 2], isComplete: true, receivedRowCount: 2),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.rows, [1, 2]);
    expect(controller.canExport, true);
    expect(notifications, 3);
    await source.close();
  });
  test(
    'should reset partial data and cancel old work when filters change',
    () async {
      final first = StreamController<AppResult<AgentQueryProgress<int>>>();
      final second = StreamController<AppResult<AgentQueryProgress<int>>>();
      final controller = ProgressiveReportController<int>();
      addTearDown(controller.dispose);
      AgentQueriesCancelScope? oldScope;
      final abandoned = controller.load((scope) {
        oldScope = scope;
        return first.stream;
      });
      first.add(
        Success(
          AgentQueryProgress(rows: [1], isComplete: false, receivedRowCount: 1),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      unawaited(controller.load((_) => second.stream));
      expect(
        (await abandoned).exceptionOrNull(),
        isA<OperationCancelledFailure>(),
      );
      expect(oldScope!.isCancelled, true);
      expect(controller.rows, isEmpty);
      first.add(
        Success(
          AgentQueryProgress(rows: [1], isComplete: true, receivedRowCount: 1),
        ),
      );
      second.add(const Failure(NetworkFailure(message: 'lost')));
      await Future<void>.delayed(Duration.zero);
      expect(controller.canExport, false);
      expect(controller.failure, isA<NetworkFailure>());
      await first.close();
      await second.close();
    },
  );
  test(
    'partial failures keep rows and prohibit exporting a complete report',
    () async {
      final source = StreamController<AppResult<AgentQueryProgress<int>>>();
      final controller = ProgressiveReportController<int>();
      addTearDown(controller.dispose);
      AgentQueriesCancelScope? scope;
      unawaited(
        controller.load((owned) {
          scope = owned;
          return source.stream;
        }),
      );
      source
        ..add(
          Success(
            AgentQueryProgress(
              rows: [1],
              isComplete: false,
              receivedRowCount: 1,
            ),
          ),
        )
        ..add(const Failure(NetworkFailure(message: 'lost')))
        ..add(
          Success(
            AgentQueryProgress(
              rows: [1, 2],
              isComplete: true,
              receivedRowCount: 2,
            ),
          ),
        );
      await Future<void>.delayed(Duration.zero);
      expect(controller.rows, [1]);
      expect(controller.isIncomplete, true);
      expect(controller.isLoading, false);
      expect(controller.canExport, false);
      expect(scope!.isCancelled, true);
      await source.close();
    },
  );
}

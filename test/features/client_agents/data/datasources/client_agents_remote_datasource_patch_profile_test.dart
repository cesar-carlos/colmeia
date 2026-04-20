import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClientAgentsRemoteDataSource.patchAgentProfile', () {
    late Dio dio;
    late ApiClientAgentsRemoteDataSource sut;
    late RequestOptions captured;

    setUp(() {
      // Replace the network adapter with a stub that captures the request
      // and returns a minimal valid catalog payload.
      dio = Dio()
        ..httpClientAdapter = _CapturingAdapter(
          onCapture: (options) => captured = options,
        );
      sut = ApiClientAgentsRemoteDataSource(dio);
    });

    test(
      'forwards the Idempotency-Key header when provided',
      () async {
        await sut.patchAgentProfile(
          agentId: 'agent-1',
          body: const <String, Object?>{'name': 'New name'},
          idempotencyKey: '  key-abc  ',
        );

        check(captured.headers['Idempotency-Key']).equals('key-abc');
      },
    );

    test(
      'omits the Idempotency-Key header when key is null/blank',
      () async {
        await sut.patchAgentProfile(
          agentId: 'agent-1',
          body: const <String, Object?>{'name': 'New name'},
        );
        check(captured.headers.containsKey('Idempotency-Key')).isFalse();

        await sut.patchAgentProfile(
          agentId: 'agent-1',
          body: const <String, Object?>{'name': 'New name'},
          idempotencyKey: '   ',
        );
        check(captured.headers.containsKey('Idempotency-Key')).isFalse();
      },
    );
  });
}

/// Minimal `HttpClientAdapter` that captures the outgoing request and
/// answers with a canned catalog record so the datasource pipeline can
/// finish without hitting the network.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({required this.onCapture});

  final void Function(RequestOptions options) onCapture;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onCapture(options);
    return ResponseBody.fromString(
      '{"agentId":"agent-1","name":"x","status":"active",'
      '"createdAt":"2026-04-01T00:00:00.000Z",'
      '"updatedAt":"2026-04-01T00:00:00.000Z",'
      '"profileVersion":1}',
      200,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }
}

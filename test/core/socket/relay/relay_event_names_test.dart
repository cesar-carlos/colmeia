import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RelayEventNames', () {
    test('keeps the wire strings expected by plug_server docs', () {
      // These are pinned by `socket_relay_protocol.md`. If the hub ever
      // renames an event, this test breaks first.
      check(RelayEventNames.conversationStart).equals('relay:conversation.start');
      check(RelayEventNames.conversationStarted)
          .equals('relay:conversation.started');
      check(RelayEventNames.conversationEnd).equals('relay:conversation.end');
      check(RelayEventNames.conversationEnded)
          .equals('relay:conversation.ended');
      check(RelayEventNames.rpcRequest).equals('relay:rpc.request');
      check(RelayEventNames.rpcAccepted).equals('relay:rpc.accepted');
      check(RelayEventNames.rpcResponse).equals('relay:rpc.response');
      check(RelayEventNames.rpcChunk).equals('relay:rpc.chunk');
      check(RelayEventNames.rpcComplete).equals('relay:rpc.complete');
      check(RelayEventNames.rpcStreamPull).equals('relay:rpc.stream.pull');
      check(RelayEventNames.rpcStreamPullResponse)
          .equals('relay:rpc.stream.pull_response');
      check(RelayEventNames.appError).equals('app:error');
    });
  });

  group('RelayPayloadFrameCompression', () {
    test('parse maps wire strings to the canonical enum', () {
      check(RelayPayloadFrameCompression.parse('always'))
          .equals(RelayPayloadFrameCompression.always);
      check(RelayPayloadFrameCompression.parse('  ALWAYS  '))
          .equals(RelayPayloadFrameCompression.always);
      check(RelayPayloadFrameCompression.parse('none'))
          .equals(RelayPayloadFrameCompression.none);
      check(RelayPayloadFrameCompression.parse('default'))
          .equals(RelayPayloadFrameCompression.auto);
      check(RelayPayloadFrameCompression.parse(null))
          .equals(RelayPayloadFrameCompression.auto);
      check(RelayPayloadFrameCompression.parse('something else'))
          .equals(RelayPayloadFrameCompression.auto);
    });

    test('wireValue produces the strings the hub expects', () {
      check(RelayPayloadFrameCompression.auto.wireValue).equals('default');
      check(RelayPayloadFrameCompression.none.wireValue).equals('none');
      check(RelayPayloadFrameCompression.always.wireValue).equals('always');
    });
  });
}

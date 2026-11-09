import 'dart:async';

import 'package:colmeia/core/socket/socket_command_coalescer.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'should retain shared work until its last follower is detached',
    () async {
      final coalescer = SocketCommandCoalescer();
      addTearDown(coalescer.dispose);
      final hub = Completer<Map<String, dynamic>>();
      final leader = coalescer.beginLead(
        key: 'key',
        rpcId: 'leader',
        hubFuture: hub.future,
      );
      final followers = <Future<Map<String, dynamic>>>[];
      for (var index = 0; index < 1000; index++) {
        followers.add(
          coalescer.tryJoinAsFollower(
            key: 'key',
            rpcId: 'f-$index',
            agentId: 'agent',
          )!,
        );
      }
      expect(coalescer.leaderKeyForRpcId('leader'), 'key');
      for (var index = 0; index < 1000; index++) {
        expect(coalescer.hasFollowersForKey('key'), isTrue);
        coalescer.takeFollower('f-$index')!.complete(<String, dynamic>{
          'detached': true,
        });
      }
      expect(coalescer.hasFollowersForKey('key'), isFalse);
      hub.complete(<String, dynamic>{'ok': true});
      await leader;
      await Future.wait(followers);
      await Future<void>.delayed(Duration.zero);
      expect(coalescer.leaderKeyForRpcId('leader'), isNull);
      expect(coalescer.pendingClientRpcIds, isEmpty);
    },
  );

  test('should clear follower counts after normal shared completion', () async {
    final coalescer = SocketCommandCoalescer();
    addTearDown(coalescer.dispose);
    final hub = Completer<Map<String, dynamic>>();
    final leader = coalescer.beginLead(
      key: 'key',
      rpcId: 'leader',
      hubFuture: hub.future,
    );
    final follower = coalescer.tryJoinAsFollower(
      key: 'key',
      rpcId: 'follower',
      agentId: 'agent',
    )!;
    hub.complete(<String, dynamic>{'ok': true});
    await Future.wait(<Future<Map<String, dynamic>>>[leader, follower]);
    await Future<void>.delayed(Duration.zero);
    expect(coalescer.hasFollowersForKey('key'), isFalse);
    expect(coalescer.pendingClientRpcIds, isEmpty);
  });

  test(
    'should preserve replacement followers when old hub work finishes',
    () async {
      final coalescer = SocketCommandCoalescer();
      addTearDown(coalescer.dispose);
      final oldHub = Completer<Map<String, dynamic>>();
      final oldLeader = coalescer.beginLead(
        key: 'key',
        rpcId: 'leader',
        hubFuture: oldHub.future,
      );
      final oldFollower = expectLater(
        coalescer.tryJoinAsFollower(
          key: 'key',
          rpcId: 'follower',
          agentId: 'agent',
        ),
        throwsA(isA<SocketDispatchDisconnected>()),
      );
      coalescer.failFollowersAndClearInflight(
        const SocketDispatchDisconnected(message: 'lost'),
      );
      await oldFollower;
      expect(coalescer.leaderKeyForRpcId('leader'), isNull);
      expect(coalescer.hasFollowersForKey('key'), isFalse);

      final newHub = Completer<Map<String, dynamic>>();
      final newLeader = coalescer.beginLead(
        key: 'key',
        rpcId: 'leader',
        hubFuture: newHub.future,
      );
      final newFollower = coalescer.tryJoinAsFollower(
        key: 'key',
        rpcId: 'follower',
        agentId: 'agent',
      )!;
      oldHub.complete(<String, dynamic>{'old': true});
      await oldLeader;
      await Future<void>.delayed(Duration.zero);
      expect(coalescer.leaderKeyForRpcId('leader'), 'key');
      expect(coalescer.hasFollowersForKey('key'), isTrue);
      final detached = coalescer.takeFollower('follower');
      expect(detached, isNotNull);
      detached!.complete(<String, dynamic>{'detached': true});
      newHub.complete(<String, dynamic>{'new': true});
      await newLeader;
      await newFollower;
      expect(coalescer.hasFollowersForKey('key'), isFalse);
    },
  );
}

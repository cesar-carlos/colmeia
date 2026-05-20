import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_request_access_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

class _PersistCall {
  const _PersistCall({
    required this.agentIdRaw,
    required this.clientTokenRaw,
  });

  final String agentIdRaw;
  final String clientTokenRaw;
}

class _RequestAccessHarness extends StatefulWidget {
  const _RequestAccessHarness({
    required this.persistCalls,
    required this.submitRows,
    this.submitAccepted = false,
    this.loadClientToken,
  });

  final List<_PersistCall> persistCalls;
  final List<List<ClientAgentAccessRequestRowInput>> submitRows;
  final bool submitAccepted;
  final Future<String?> Function(String agentId)? loadClientToken;

  @override
  State<_RequestAccessHarness> createState() => _RequestAccessHarnessState();
}

class _RequestAccessHarnessState extends State<_RequestAccessHarness> {
  List<String> _draftSlots = const <String>[''];
  int _resetRevision = 0;

  @override
  Widget build(BuildContext context) {
    return LocalizedTestApp(
      child: SingleChildScrollView(
        child: ClientAgentsRequestAccessTab(
          draftSeedAgentIdSlots: _draftSlots,
          draftResetRevision: _resetRevision,
          isMutating: false,
          onDraftSlotsChanged: (slots) {
            setState(() {
              _draftSlots = List<String>.from(slots);
            });
          },
          onClearMessages: () {},
          loadClientToken: widget.loadClientToken ?? ((_) async => null),
          persistClientTokenDraftLine:
              ({
                required agentIdRaw,
                required clientTokenRaw,
              }) async {
                widget.persistCalls.add(
                  _PersistCall(
                    agentIdRaw: agentIdRaw,
                    clientTokenRaw: clientTokenRaw,
                  ),
                );
              },
          onSubmitRows: (rows) async {
            widget.submitRows.add(rows);
            if (widget.submitAccepted) {
              setState(() {
                _draftSlots = const <String>[''];
                _resetRevision++;
              });
            }
            return widget.submitAccepted;
          },
        ),
      ),
    );
  }
}

void main() {
  const validAgentId = '11111111-1111-1111-8111-111111111111';

  testWidgets(
    'preserves token text and pending persist timer when parent echoes draft changes',
    (tester) async {
      final persistCalls = <_PersistCall>[];
      final submitRows = <List<ClientAgentAccessRequestRowInput>>[];

      await tester.pumpWidget(
        _RequestAccessHarness(
          persistCalls: persistCalls,
          submitRows: submitRows,
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), validAgentId);
      await tester.pump();

      await tester.enterText(fields.at(1), 'tok-1');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(find.text('tok-1'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));

      expect(
        persistCalls.any(
          (call) =>
              call.agentIdRaw == validAgentId && call.clientTokenRaw == 'tok-1',
        ),
        isTrue,
      );
      check(submitRows).isEmpty();
    },
  );

  testWidgets(
    'clears the form only after the parent issues an explicit reset revision',
    (tester) async {
      final persistCalls = <_PersistCall>[];
      final submitRows = <List<ClientAgentAccessRequestRowInput>>[];

      await tester.pumpWidget(
        _RequestAccessHarness(
          persistCalls: persistCalls,
          submitRows: submitRows,
          submitAccepted: true,
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), validAgentId);
      await tester.pump();

      expect(find.text(validAgentId), findsOneWidget);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text(validAgentId), findsNothing);
      check(submitRows.single.single.agentIdRaw).equals(validAgentId);
    },
  );

  testWidgets(
    'rehydrates the latest valid UUID when the id changes mid-flight',
    (tester) async {
      const firstId = '22222222-2222-2222-8222-222222222222';
      const secondId = '33333333-3333-3333-8333-333333333333';
      final persistCalls = <_PersistCall>[];
      final submitRows = <List<ClientAgentAccessRequestRowInput>>[];
      final completers = <String, Completer<String?>>{
        firstId: Completer<String?>(),
        secondId: Completer<String?>(),
      };

      await tester.pumpWidget(
        _RequestAccessHarness(
          persistCalls: persistCalls,
          submitRows: submitRows,
          loadClientToken: (agentId) => completers[agentId]!.future,
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), firstId);
      await tester.pump();
      await tester.enterText(fields.at(0), secondId);
      await tester.pump();

      completers[firstId]!.complete('tok-old');
      completers[secondId]!.complete('tok-new');
      await tester.pump();
      await tester.pump();

      expect(find.text('tok-new'), findsOneWidget);
      expect(find.text('tok-old'), findsNothing);
      check(persistCalls).isEmpty();
      check(submitRows).isEmpty();
    },
  );
}

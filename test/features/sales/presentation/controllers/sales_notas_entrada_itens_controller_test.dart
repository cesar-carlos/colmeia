import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_itens_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/ports/sales_preferences_port.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_notas_entrada_itens_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSalesPreferences extends Mock implements SalesPreferencesPort {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

class _MockNotasEntradaItensRepository extends Mock
    implements NotasEntradaItensRepository {}

void main() {
  late _MockSalesPreferences preferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockNotasEntradaItensRepository repository;
  late SalesNotasEntradaItensController controller;

  setUpAll(() {
    registerFallbackValue(const NotasEntradaItensFilter(compraId: 1));
    registerFallbackValue(AgentQueriesCancelScope());
  });

  setUp(() {
    preferences = _MockSalesPreferences();
    tokenReader = _MockAgentClientTokenReader();
    repository = _MockNotasEntradaItensRepository();
    when(() => preferences.selectedAgentId).thenReturn('agent-1');
    when(
      () => tokenReader.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const <String, String>{'agent-1': 'token-1'});
  });

  tearDown(() => controller.dispose());

  SalesNotasEntradaItensController buildController({
    int compraId = 80,
    NotaEntradaRow? note,
    String? initialAgentId = 'agent-1',
  }) {
    return SalesNotasEntradaItensController(
      sessionService: SalesSessionService(preferences),
      resolveSalesAgentClientToken: ResolveSalesAgentClientTokenUseCase(
        tokenReader,
      ),
      repository: repository,
      compraId: compraId,
      note: note,
      initialAgentId: initialAgentId,
    );
  }

  void stubLoad(NotasEntradaItensResult loaded) {
    when(
      () => repository.load(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => Success<NotasEntradaItensResult, AppFailure>(loaded),
    );
  }

  NotasEntradaItensFilter capturedFilter() {
    return verify(
          () => repository.load(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: captureAny(named: 'filter'),
            clientToken: 'token-1',
            cancelScope: any(named: 'cancelScope'),
          ),
        ).captured.single
        as NotasEntradaItensFilter;
  }

  test('queries the opened note by CompraId', () async {
    controller = buildController(note: _note());
    stubLoad(_loaded());

    await controller.bindUser('user-1');

    final filter = capturedFilter();
    check(filter.compraId).equals(80);
    check(controller.rows.single.codProduto).equals(15);
    check(controller.totalsDifferFromNote).isFalse();
  });

  test('loads by CompraId when the header is missing', () async {
    controller = buildController(initialAgentId: null);
    stubLoad(_loaded());

    await controller.bindUser('user-1');

    final filter = capturedFilter();
    check(filter.compraId).equals(80);
  });

  test('stops when the client token is missing', () async {
    when(
      () => tokenReader.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const <String, String>{});
    controller = buildController(note: _note());

    await controller.bindUser('user-1');

    check(controller.missingClientToken).isTrue();
    check(controller.rows).isEmpty();
    verifyNever(
      () => repository.load(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    );
  });

  test('does not query an invalid purchase id', () async {
    controller = buildController(compraId: 0, note: _note());

    await controller.bindUser('user-1');

    check(controller.hasValidCompraId).isFalse();
    check(controller.isLoading).isFalse();
    verifyNever(
      () => repository.load(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    );
  });

  test('exposes a cancelled purchase from the loaded lines', () async {
    controller = buildController(note: _note());
    stubLoad(_loaded(compraCancelada: 'S'));

    await controller.bindUser('user-1');

    check(controller.isCancelled).isTrue();
  });

  test('flags a header total that differs from the loaded lines', () async {
    controller = buildController(note: _note(valorTotalCompra: 100));
    stubLoad(_loaded());

    await controller.bindUser('user-1');

    check(controller.totalsDifferFromNote).isTrue();
    check(controller.truncationLimit).isNull();
  });

  test('skips the header comparison when the result is truncated', () async {
    controller = buildController(note: _note(valorTotalCompra: 100));
    stubLoad(_loaded(isTruncated: true));

    await controller.bindUser('user-1');

    check(controller.isTruncated).isTrue();
    check(controller.truncationLimit).equals(2000);
    check(controller.totalsDifferFromNote).isFalse();
  });

  test('surfaces a load failure', () async {
    controller = buildController(note: _note());
    when(
      () => repository.load(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Failure<NotasEntradaItensResult, AppFailure>(
        ValidationFailure(message: 'boom'),
      ),
    );

    await controller.bindUser('user-1');

    check(controller.loadFailure).isA<ValidationFailure>();
    check(controller.rows).isEmpty();
  });

  test('hides a cancelled query failure', () async {
    controller = buildController(note: _note());
    when(
      () => repository.load(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Failure<NotasEntradaItensResult, AppFailure>(
        OperationCancelledFailure(),
      ),
    );

    await controller.bindUser('user-1');

    check(controller.loadFailure).isNull();
    check(controller.isLoading).isFalse();
  });
}

NotaEntradaRow _note({double valorTotalCompra = 45.5}) {
  return NotaEntradaRow(
    compraId: 80,
    codEmpresa: 2,
    codFilial: 17,
    nomeFilial: 'Filial',
    codTipoOperacaoCompra: 1,
    descricaoTipoOperacaoCompra: 'Compra',
    numeroDocumento: 'NF-80',
    dataLancamento: DateTime(2026, 3, 6),
    codFornecedor: 9,
    nomeFornecedor: 'Fornecedor',
    valorTotalCompra: valorTotalCompra,
  );
}

NotaEntradaItemRow _item({String compraCancelada = 'N'}) {
  return NotaEntradaItemRow(
    codEmpresa: 2,
    codFilial: 17,
    compraId: 80,
    compraCancelada: compraCancelada,
    codProduto: 15,
    nomeProduto: 'Mel',
    quantidade: 2,
    valorUnitario: 22.75,
    subTotal: 45.5,
    valorDescontoItem: 0,
    valorTotalDesconto: 0,
    valorDescontoProporcional: 0,
    valorTotal: 45.5,
  );
}

NotasEntradaItensResult _loaded({
  String compraCancelada = 'N',
  bool isTruncated = false,
  int maxRows = 2000,
}) {
  return NotasEntradaItensResult(
    items: <NotaEntradaItemRow>[_item(compraCancelada: compraCancelada)],
    isTruncated: isTruncated,
    maxRows: maxRows,
  );
}

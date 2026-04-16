import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockResumoRepository extends Mock
    implements ResumoVendasDiariasPorVendedorRepository {}

class _MockFilterOptionsRepository extends Mock
    implements ResumoVendasDiariasPorVendedorFilterOptionsRepository {}

class _MockFilterOptionsAcrossRepository extends Mock
    implements
        ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository {}

typedef _VendedorOptsAcrossAgentsUseCase =
    LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase;
typedef _MunicipioOptsAcrossAgentsUseCase =
    LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase;

void main() {
  final dataInicio = DateTime.utc(2026, 4);
  final dataFim = DateTime.utc(2026, 4, 30);
  final filter = ResumoVendasDiariasPorVendedorFilter(
    dataVendaInicio: dataInicio,
    dataVendaFim: dataFim,
  );

  setUpAll(() {
    registerFallbackValue(filter);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  group('LoadResumoVendasDiariasPorVendedorUseCase', () {
    late _MockResumoRepository repository;
    late LoadResumoVendasDiariasPorVendedorUseCase useCase;

    setUp(() {
      repository = _MockResumoRepository();
      useCase = LoadResumoVendasDiariasPorVendedorUseCase(repository);
    });

    test('forwards to repository.load', () async {
      when(
        () => repository.load(
          userId: 'user-1',
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<List<ResumoVendasDiariasPorVendedorRow>, AppFailure>(
              <ResumoVendasDiariasPorVendedorRow>[],
            ),
      );

      await useCase(userId: 'user-1', 
        agentId: 'a1',
        filter: filter,
        clientToken: 'ct',
        bridgeTimeoutMs: 3000,
      );

      verify(
        () => repository.load(
          userId: 'user-1',
          agentId: 'a1',
          filter: filter,
          clientToken: 'ct',
          bridgeTimeoutMs: 3000,
        ),
      ).called(1);
    });
  });

  group('LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase', () {
    late _MockFilterOptionsRepository repository;
    late LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase useCase;

    setUp(() {
      repository = _MockFilterOptionsRepository();
      useCase = LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase(
        repository,
      );
    });

    test('forwards to loadVendedorOptions', () async {
      when(
        () => repository.loadVendedorOptions(
          userId: 'user-1',
          agentId: any(named: 'agentId'),
          dataVendaInicio: any(named: 'dataVendaInicio'),
          dataVendaFim: any(named: 'dataVendaFim'),
          searchTerm: any(named: 'searchTerm'),
          limit: any(named: 'limit'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              List<ResumoVendasDiariasPorVendedorVendedorOption>,
              AppFailure
            >(<ResumoVendasDiariasPorVendedorVendedorOption>[]),
      );

      await useCase(userId: 'user-1', 
        agentId: 'a1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
        searchTerm: 'jo',
        limit: 12,
        clientToken: 't',
        bridgeTimeoutMs: 4000,
      );

      verify(
        () => repository.loadVendedorOptions(
          userId: 'user-1',
          agentId: 'a1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
          searchTerm: 'jo',
          limit: 12,
          clientToken: 't',
          bridgeTimeoutMs: 4000,
        ),
      ).called(1);
    });
  });

  group('LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase', () {
    late _MockFilterOptionsRepository repository;
    late LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase useCase;

    setUp(() {
      repository = _MockFilterOptionsRepository();
      useCase = LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase(
        repository,
      );
    });

    test('forwards to loadBairroOptions', () async {
      when(
        () => repository.loadBairroOptions(
          userId: 'user-1',
          agentId: any(named: 'agentId'),
          dataVendaInicio: any(named: 'dataVendaInicio'),
          dataVendaFim: any(named: 'dataVendaFim'),
          searchTerm: any(named: 'searchTerm'),
          limit: any(named: 'limit'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              List<ResumoVendasDiariasPorVendedorTextOption>,
              AppFailure
            >(<ResumoVendasDiariasPorVendedorTextOption>[]),
      );

      await useCase(userId: 'user-1', 
        agentId: 'a1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
      );

      verify(
        () => repository.loadBairroOptions(
          userId: 'user-1',
          agentId: 'a1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
          searchTerm: any(named: 'searchTerm'),
          limit: any(named: 'limit'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).called(1);
    });
  });

  group('LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase', () {
    late _MockFilterOptionsRepository repository;
    late LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase useCase;

    setUp(() {
      repository = _MockFilterOptionsRepository();
      useCase = LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase(
        repository,
      );
    });

    test('forwards to loadMunicipioOptions', () async {
      when(
        () => repository.loadMunicipioOptions(
          userId: 'user-1',
          agentId: any(named: 'agentId'),
          dataVendaInicio: any(named: 'dataVendaInicio'),
          dataVendaFim: any(named: 'dataVendaFim'),
          searchTerm: any(named: 'searchTerm'),
          limit: any(named: 'limit'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              List<ResumoVendasDiariasPorVendedorTextOption>,
              AppFailure
            >(<ResumoVendasDiariasPorVendedorTextOption>[]),
      );

      await useCase(userId: 'user-1', 
        agentId: 'a1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
        limit: 5,
      );

      verify(
        () => repository.loadMunicipioOptions(
          userId: 'user-1',
          agentId: 'a1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
          searchTerm: any(named: 'searchTerm'),
          limit: 5,
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).called(1);
    });
  });

  group(
    'LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase',
    () {
      late _MockFilterOptionsAcrossRepository repository;
      late _VendedorOptsAcrossAgentsUseCase useCase;

      setUp(() {
        repository = _MockFilterOptionsAcrossRepository();
        useCase = _VendedorOptsAcrossAgentsUseCase(repository);
      });

      test('forwards to repository.loadVendedorOptions', () async {
        when(
          () => repository.loadVendedorOptions(
            userId: any(named: 'userId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<
                List<ResumoVendasDiariasPorVendedorVendedorOption>,
                AppFailure
              >(<ResumoVendasDiariasPorVendedorVendedorOption>[]),
        );

        await useCase(
          userId: 'u1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
          selectedAgentIds: {'x'},
          searchTerm: 'ab',
          limit: 8,
          strategy: AgentQueryExecutionStrategy.race,
          bridgeTimeoutMs: 7000,
          raceMaxSources: 3,
        );

        verify(
          () => repository.loadVendedorOptions(
            userId: 'u1',
            dataVendaInicio: dataInicio,
            dataVendaFim: dataFim,
            selectedAgentIds: {'x'},
            searchTerm: 'ab',
            limit: 8,
            strategy: AgentQueryExecutionStrategy.race,
            bridgeTimeoutMs: 7000,
            raceMaxSources: 3,
          ),
        ).called(1);
      });
    },
  );

  group(
    'LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase',
    () {
      late _MockFilterOptionsAcrossRepository repository;
      late LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase
      useCase;

      setUp(() {
        repository = _MockFilterOptionsAcrossRepository();
        useCase =
            LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase(
              repository,
            );
      });

      test('forwards to repository.loadBairroOptions', () async {
        when(
          () => repository.loadBairroOptions(
            userId: any(named: 'userId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<
                List<ResumoVendasDiariasPorVendedorTextOption>,
                AppFailure
              >(<ResumoVendasDiariasPorVendedorTextOption>[]),
        );

        await useCase(
          userId: 'u1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
        );

        verify(
          () => repository.loadBairroOptions(
            userId: 'u1',
            dataVendaInicio: dataInicio,
            dataVendaFim: dataFim,
            selectedAgentIds: any(named: 'selectedAgentIds'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).called(1);
      });
    },
  );

  group(
    'LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase',
    () {
      late _MockFilterOptionsAcrossRepository repository;
      late _MunicipioOptsAcrossAgentsUseCase useCase;

      setUp(() {
        repository = _MockFilterOptionsAcrossRepository();
        useCase = _MunicipioOptsAcrossAgentsUseCase(repository);
      });

      test('forwards to repository.loadMunicipioOptions', () async {
        when(
          () => repository.loadMunicipioOptions(
            userId: any(named: 'userId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<
                List<ResumoVendasDiariasPorVendedorTextOption>,
                AppFailure
              >(<ResumoVendasDiariasPorVendedorTextOption>[]),
        );

        await useCase(
          userId: 'u1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
          selectedAgentIds: {'p', 'q'},
          strategy: AgentQueryExecutionStrategy.singleSource,
        );

        verify(
          () => repository.loadMunicipioOptions(
            userId: 'u1',
            dataVendaInicio: dataInicio,
            dataVendaFim: dataFim,
            selectedAgentIds: {'p', 'q'},
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            strategy: AgentQueryExecutionStrategy.singleSource,
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).called(1);
      });
    },
  );
}

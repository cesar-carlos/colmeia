import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class LoadClientAgentDetailUseCase {
  LoadClientAgentDetailUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<ClientAgent>> call({
    required String userId,
    required String agentId,
  }) async {
    final approvedFuture = _repository.loadApprovedAgentById(
      userId: userId,
      agentId: agentId,
    );
    final catalogFuture = _repository.loadCatalogAgentById(
      userId: userId,
      agentId: agentId,
    );
    final approvedResult = await approvedFuture;
    return approvedResult.fold(
      (approved) async {
        final catalogResult = await catalogFuture;
        return catalogResult.fold(
          (item) => Success<ClientAgent, AppFailure>(
            mergeApprovedAgentWithCatalog(approved, item.agent),
          ),
          (_) => Success<ClientAgent, AppFailure>(approved),
        );
      },
      (failure) async => Failure<ClientAgent, AppFailure>(failure),
    );
  }
}

ClientAgent mergeApprovedAgentWithCatalog(
  ClientAgent approved,
  ClientAgent catalog,
) {
  String? coalesceOptional(String? primary, String? secondary) {
    final p = primary?.trim();
    if (p != null && p.isNotEmpty) {
      return primary;
    }
    final s = secondary?.trim();
    if (s != null && s.isNotEmpty) {
      return secondary;
    }
    return primary ?? secondary;
  }

  String coalesceName(String primary, String secondary) {
    final p = primary.trim();
    if (p.isNotEmpty) {
      return primary;
    }
    final s = secondary.trim();
    if (s.isNotEmpty) {
      return secondary;
    }
    return primary;
  }

  return ClientAgent(
    agentId: approved.agentId,
    name: coalesceName(approved.name, catalog.name),
    tradeName: coalesceOptional(approved.tradeName, catalog.tradeName),
    document: coalesceOptional(approved.document, catalog.document),
    cnpjCpf: coalesceOptional(approved.cnpjCpf, catalog.cnpjCpf),
    registrationDocument: coalesceOptional(
      approved.registrationDocument,
      catalog.registrationDocument,
    ),
    documentType: coalesceOptional(approved.documentType, catalog.documentType),
    phone: coalesceOptional(approved.phone, catalog.phone),
    mobile: coalesceOptional(approved.mobile, catalog.mobile),
    email: coalesceOptional(approved.email, catalog.email),
    address: approved.address ?? catalog.address,
    notes: coalesceOptional(approved.notes, catalog.notes),
    observation: coalesceOptional(approved.observation, catalog.observation),
    profileUpdatedAt: approved.profileUpdatedAt ?? catalog.profileUpdatedAt,
    catalogStatus: catalog.catalogStatus,
    connectionStatus: catalog.connectionStatus,
    createdAt: approved.createdAt,
    updatedAt: approved.updatedAt.isAfter(catalog.updatedAt)
        ? approved.updatedAt
        : catalog.updatedAt,
  );
}

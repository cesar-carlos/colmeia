import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/agent_document_digits.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';

abstract interface class ClientAgentDetailProfileHost {
  bool get isDisposed;

  ClientAgent? get agent;

  String? get currentUserId;

  ClientAgentsPresentationMessage consumeFailure(AppFailure failure);

  void notifyProfileChanged();

  Future<void> reloadAgentDetail({
    required String agentId,
    required bool forceRefresh,
  });
}

class ClientAgentDetailProfileCoordinator {
  ClientAgentDetailProfileCoordinator({
    required ClientAgentDetailProfileHost host,
    required UpdateClientAgentProfileUseCase updateClientAgentProfileUseCase,
    required String Function() idempotencyKeyGenerator,
  }) : _host = host,
       _updateClientAgentProfileUseCase = updateClientAgentProfileUseCase,
       _idempotencyKeyGenerator = idempotencyKeyGenerator;

  final ClientAgentDetailProfileHost _host;
  final UpdateClientAgentProfileUseCase _updateClientAgentProfileUseCase;
  final String Function() _idempotencyKeyGenerator;

  bool _isSavingProfile = false;
  ClientAgentsPresentationMessage? _profileSaveError;
  ClientAgentsPresentationMessage? _profileSaveSuccess;

  bool get isSavingProfile => _isSavingProfile;
  ClientAgentsPresentationMessage? get profileSaveError => _profileSaveError;
  ClientAgentsPresentationMessage? get profileSaveSuccess => _profileSaveSuccess;

  void clearProfileFeedback() {
    if (_profileSaveError == null && _profileSaveSuccess == null) {
      return;
    }
    _profileSaveError = null;
    _profileSaveSuccess = null;
    _host.notifyProfileChanged();
  }

  Future<void> saveAgentProfile({
    required String agentId,
    required String name,
    required String tradeName,
    required String cnpjCpf,
    required String phone,
    required String mobile,
    required String email,
    required String street,
    required String number,
    required String district,
    required String postalCode,
    required String city,
    required String state,
    required String notes,
    required String observation,
  }) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _profileSaveSuccess = null;
      _profileSaveError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _host.notifyProfileChanged();
      return;
    }

    _isSavingProfile = true;
    _profileSaveError = null;
    _profileSaveSuccess = null;
    _host.notifyProfileChanged();

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _profileSaveError =
          ClientAgentsPresentationMessage.clientAgentDetailProfileNameRequired();
      _isSavingProfile = false;
      _host.notifyProfileChanged();
      return;
    }

    final current = _host.agent;
    final request = AgentProfileUpdateRequest(
      name: trimmedName,
      tradeName: tradeName.trim().isEmpty ? null : tradeName.trim(),
      cnpjCpf: digitsOnlyDocument(cnpjCpf),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      mobile: mobile.trim().isEmpty ? null : mobile.trim(),
      email: email.trim().isEmpty ? null : email.trim(),
      address: _optionalAgentProfileAddress(
        street: street,
        number: number,
        district: district,
        postalCode: postalCode,
        city: city,
        state: state,
      ),
      notes: notes.trim().isEmpty ? null : notes.trim(),
      observation: observation.trim().isEmpty ? null : observation.trim(),
      expectedProfileVersion: current?.profileVersion,
      idempotencyKey: _idempotencyKeyGenerator(),
    );

    try {
      final result = await _updateClientAgentProfileUseCase(
        userId: userId,
        agentId: agentId,
        request: request,
      );
      if (_host.isDisposed) {
        return;
      }
      final updated = result.getOrNull();
      if (updated != null) {
        await _host.reloadAgentDetail(agentId: agentId, forceRefresh: true);
        if (_host.isDisposed) {
          return;
        }
        _profileSaveSuccess =
            ClientAgentsPresentationMessage.clientAgentDetailProfileSaved();
      } else {
        final failure = result.exceptionOrNull()!;
        _profileSaveError = _host.consumeFailure(failure);
        AppLogger.warning(
          'Client agent profile update failed',
          context: <String, Object?>{
            'operation': 'saveAgentProfile',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      if (!_host.isDisposed) {
        _isSavingProfile = false;
        _host.notifyProfileChanged();
      }
    }
  }
}

AgentProfileAddress? _optionalAgentProfileAddress({
  required String street,
  required String number,
  required String district,
  required String postalCode,
  required String city,
  required String state,
}) {
  String? nz(String raw) {
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  final st = nz(street);
  final numStr = nz(number);
  final dist = nz(district);
  final pc = nz(postalCode);
  final ct = nz(city);
  final stCode = nz(state);
  if (st == null &&
      numStr == null &&
      dist == null &&
      pc == null &&
      ct == null &&
      stCode == null) {
    return null;
  }
  return AgentProfileAddress(
    street: st,
    number: numStr,
    district: dist,
    postalCode: pc,
    city: ct,
    state: stCode,
  );
}

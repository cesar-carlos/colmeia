import 'package:colmeia/features/client_agents/domain/repositories/client_access_requests_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agent_catalog_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/owner_agents_repository.dart';

export 'package:colmeia/features/client_agents/domain/repositories/client_access_requests_repository.dart';
export 'package:colmeia/features/client_agents/domain/repositories/client_agent_catalog_repository.dart';
export 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
export 'package:colmeia/features/client_agents/domain/repositories/owner_agents_repository.dart';

/// Facade interface composing the four bounded repositories the feature
/// uses:
///
/// - [ClientAgentCatalogRepository] — browse + edit the global catalog.
/// - [ClientApprovedAgentsRepository] — read the agents the current
///   client is approved to access plus presence side-effects.
/// - [ClientAccessRequestsRepository] — file/retry/discard requests,
///   sync the local queue, look up status by token.
/// - [OwnerAgentsRepository] — owner-side moderation of incoming
///   requests and existing client access.
///
/// New code should depend on the narrowest sub-interface it actually
/// needs. The facade is kept so existing call sites that asked for
/// `ClientAgentsRepository` keep compiling without change.
abstract interface class ClientAgentsRepository
    implements
        ClientAgentCatalogRepository,
        ClientApprovedAgentsRepository,
        ClientAccessRequestsRepository,
        OwnerAgentsRepository {}

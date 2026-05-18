import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/cadastro_filial_postal_address_adapter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/shared/maps/resolve_postal_address_location_use_case.dart';

class ResolveCadastroFilialLocationUseCase {
  const ResolveCadastroFilialLocationUseCase(
    this._resolvePostalAddressLocation,
  );

  final ResolvePostalAddressLocationUseCase _resolvePostalAddressLocation;

  Future<AppResult<AppResolvedOptionalLocation>> call(
    CadastroFilialRow filial,
  ) {
    return _resolvePostalAddressLocation(filial.toPostalAddress());
  }
}

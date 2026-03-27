import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';

/// Demo store rows for access requests (Stitch-aligned). Shared by UI and fake.
class RegisterStoreOption {
  const RegisterStoreOption({
    required this.id,
    required this.stateCode,
    required this.unitName,
    required this.cityLine,
  });

  final String id;
  final String stateCode;
  final String unitName;
  final String cityLine;

  static const List<RegisterStoreOption> stitchDefaults = <RegisterStoreOption>[
    RegisterStoreOption(
      id: 'sp-morumbi',
      stateCode: 'SP',
      unitName: 'Unidade Morumbi',
      cityLine: 'São Paulo - SP',
    ),
    RegisterStoreOption(
      id: 'rj-barra',
      stateCode: 'RJ',
      unitName: 'Unidade Barra',
      cityLine: 'Rio de Janeiro - RJ',
    ),
    RegisterStoreOption(
      id: 'mg-savassi',
      stateCode: 'MG',
      unitName: 'Unidade Savassi',
      cityLine: 'Belo Horizonte - MG',
    ),
  ];
}

/// Maps selected catalog ids to [StoreScope] rows for the fake identity store.
abstract final class RegisterStoreCatalog {
  static List<StoreScope> scopesForSelectedIds(
    List<String> selectedIds, {
    required int userSequence,
  }) {
    final scopes = <StoreScope>[];
    for (final id in selectedIds) {
      final option = RegisterStoreOption.stitchDefaults
          .where((o) => o.id == id)
          .firstOrNull;
      if (option != null) {
        scopes.add(
          StoreScope(
            id: '${option.id}-u$userSequence',
            name: option.unitName,
          ),
        );
      }
    }
    return scopes;
  }
}

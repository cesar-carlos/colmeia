/// Canonical branch-key formatters shared across `LoadSalesLiveMapUseCase`
/// and `SalesLiveMapBranchAggregator`.
///
/// The internal key is opaque (`'$agentId:$codEmpresa:$codFilial'`) and
/// must not be parsed back — agent ids are UUIDs and may legally contain
/// characters that overlap with separators. Callers that need to round-trip
/// to a parseable form should use `SalesLiveMapBranchRefCodec` instead.
///
/// `SalesLiveMapBranchAggregate.id` uses a different (`-` separator)
/// format because it is also persisted in the branch location cache; the
/// two formats must not be mixed.
abstract final class SalesLiveMapBranchKeys {
  /// Produces an opaque per-load lookup key for a branch.
  static String of({
    required String agentId,
    required int codEmpresa,
    required int codFilial,
  }) {
    return '$agentId:$codEmpresa:$codFilial';
  }
}

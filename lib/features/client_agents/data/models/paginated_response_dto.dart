import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';

/// Common pagination metadata shared by every `Paginated*ResponseDto` the
/// repository consumes. Implementing this interface unlocks the
/// [PaginatedResponseDtoMapping.toPaginatedResult] extension so call sites
/// can map a DTO's items to [PaginatedResult] without manually copying the
/// 4 metadata fields each time.
abstract interface class PaginatedResponseDto {
  int get count;
  int get total;
  int get page;
  int get pageSize;
}

extension PaginatedResponseDtoMapping on PaginatedResponseDto {
  /// Wraps [items] in a [PaginatedResult] inheriting `count` / `total` /
  /// `page` / `pageSize` from this DTO. Use this in repository mappers so
  /// every paginated response goes through a single shape — the DTO knows
  /// its metadata, callers only describe the item transform.
  PaginatedResult<T> toPaginatedResult<T>(
    List<T> items, {
    bool isStaleCache = false,
  }) {
    return PaginatedResult<T>(
      items: items,
      count: count,
      total: total,
      page: page,
      pageSize: pageSize,
      isStaleCache: isStaleCache,
    );
  }
}

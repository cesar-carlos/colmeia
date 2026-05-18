import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:result_dart/result_dart.dart';

class AppResolvedOptionalLocation {
  const AppResolvedOptionalLocation({
    required this.location,
  });

  const AppResolvedOptionalLocation.notFound() : location = null;

  final AppResolvedLocation? location;

  bool get found => location != null;

  double? get latitude => location?.point.latitude;

  double? get longitude => location?.point.longitude;

  String? get city => location?.details?.city;

  String? get uf => location?.details?.uf;
}

class ResolvePostalAddressLocationUseCase {
  const ResolvePostalAddressLocationUseCase(this._resolver);

  final AppLocationResolver _resolver;

  Future<AppResult<AppResolvedOptionalLocation>> call(
    AppPostalAddress address,
  ) async {
    if (address.isEmpty) {
      return const Success<AppResolvedOptionalLocation, AppFailure>(
        AppResolvedOptionalLocation.notFound(),
      );
    }

    final result = await _resolver.resolve(
      AppLocationLookupInput.streetAddress(
        postalAddress: address,
      ),
    );

    if (result.isError()) {
      return Failure<AppResolvedOptionalLocation, AppFailure>(
        result.exceptionOrNull()!,
      );
    }

    final outcome = result.getOrNull();
    return switch (outcome) {
      AppLocationResolutionResolved(:final location) =>
        Success<AppResolvedOptionalLocation, AppFailure>(
          AppResolvedOptionalLocation(location: location),
        ),
      AppLocationResolutionNotFound() ||
      null => const Success<AppResolvedOptionalLocation, AppFailure>(
        AppResolvedOptionalLocation.notFound(),
      ),
    };
  }
}

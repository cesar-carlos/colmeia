import 'package:colmeia/shared/maps/app_here_geocoding_candidate_matcher.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppHereGeocodingCandidateMatcher', () {
    test('prioritizes matching CEP and rejects divergent postal code sets', () {
      final selected = AppHereGeocodingCandidateMatcher.selectBest(
        input: const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Rua das Flores',
            number: '123',
            city: 'Sinop',
            uf: 'MT',
            cep: '78550005',
          ),
        ),
        candidates: <AppHereGeocodingCandidate>[
          _candidate(
            postalCode: '01001000',
            city: 'Sinop',
            uf: 'MT',
            resultType: 'houseNumber',
          ),
          _candidate(
            postalCode: '78550005',
            city: 'Sinop',
            uf: 'MT',
            resultType: 'street',
          ),
        ],
      );

      expect(selected?.postalCode, '78550005');
    });

    test('rejects candidates with divergent UF', () {
      final selected = AppHereGeocodingCandidateMatcher.selectBest(
        input: const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            city: 'Sinop',
            uf: 'MT',
          ),
        ),
        candidates: <AppHereGeocodingCandidate>[
          _candidate(city: 'Sinop', uf: 'GO'),
        ],
      );

      expect(selected, isNull);
    });

    test('prioritizes normalized city match when available', () {
      final selected = AppHereGeocodingCandidateMatcher.selectBest(
        input: const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            city: 'Tangara da Serra',
            uf: 'MT',
          ),
        ),
        candidates: <AppHereGeocodingCandidate>[
          _candidate(city: 'Cuiaba', uf: 'MT'),
          _candidate(city: 'Tangará da Serra', uf: 'MT'),
        ],
      );

      expect(selected?.city, 'Tangará da Serra');
    });

    test('prefers houseNumber over less specific result types', () {
      final selected = AppHereGeocodingCandidateMatcher.selectBest(
        input: const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Av Paulista',
            number: '1000',
            city: 'Sao Paulo',
            uf: 'SP',
          ),
        ),
        candidates: <AppHereGeocodingCandidate>[
          _candidate(
            city: 'Sao Paulo',
            uf: 'SP',
            resultType: 'street',
          ),
          _candidate(
            city: 'Sao Paulo',
            uf: 'SP',
            resultType: 'houseNumber',
          ),
        ],
      );

      expect(selected?.resultType, 'houseNumber');
    });

    test('returns notFound when no candidate survives filters', () {
      final selected = AppHereGeocodingCandidateMatcher.selectBest(
        input: const AppLocationLookupInput.cep(cep: '78550005'),
        candidates: <AppHereGeocodingCandidate>[
          _candidate(postalCode: '01001000', uf: 'MT'),
        ],
      );

      expect(selected, isNull);
    });
  });
}

AppHereGeocodingCandidate _candidate({
  String? city,
  String? uf,
  String? postalCode,
  String? resultType,
}) {
  return AppHereGeocodingCandidate(
    point: const AppGeoPoint(latitude: -11.86, longitude: -55.50),
    resultType: resultType,
    label: 'candidate',
    title: 'candidate',
    city: city,
    uf: uf,
    district: null,
    postalCode: postalCode,
    countryCode: 'BRA',
  );
}

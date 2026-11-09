import 'package:colmeia/features/pwa/data/pwa_authorization_gateway.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Dio extends Mock implements Dio {}

void main() {
  for (final skew in [0, 410, 5000, 5001]) {
    test(
      'should preserve absolute validity with issuance skew ${skew}ms',
      () async {
        final dio = _Dio();
        var now = DateTime.utc(2026, 11, 9);
        final issued = now.add(Duration(milliseconds: skew));
        final expires = issued.add(const Duration(hours: 24));
        final waits = <Duration>[];
        when(
          () => dio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/'),
            data: {
              'data': {
                'version': 1,
                'userId': 'user',
                'agentIds': ['agent'],
                'issuedAt': issued.toIso8601String(),
                'expiresAt': expires.toIso8601String(),
              },
            },
          ),
        );
        final gateway = PwaAuthorizationGateway(
          dio,
          clock: () => now,
          delay: (duration) async {
            waits.add(duration);
            now = now.add(duration);
          },
        );
        final grant = await gateway.authorize('agent');
        expect(grant.issuedAt, issued);
        expect(grant.expiresAt, expires);
        expect(grant.permits('user', 'agent', now), skew <= 5000);
        expect(grant.permits('user', 'agent', expires), isFalse);
        expect(grant.permits('other', 'agent', now), isFalse);
        expect(
          waits,
          skew > 0 && skew <= 5000 ? [Duration(milliseconds: skew)] : isEmpty,
        );
      },
    );
  }
}

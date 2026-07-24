import 'package:checks/checks.dart';
import 'package:colmeia/core/di/injector_socket.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  tearDown(() {
    dotenv.loadFromString(
      envString: '''
SOCKET_PAYLOAD_REQUIRE_SIGNATURE=false
SOCKET_PAYLOAD_SIGNING_KEY=
''',
    );
  });

  group('registerInjectorSocket PayloadFrameCodec bootstrap', () {
    test(
      'throws StateError when require signature is true with empty key',
      () {
        dotenv.loadFromString(
          envString: '''
SOCKET_PAYLOAD_REQUIRE_SIGNATURE=true
SOCKET_PAYLOAD_SIGNING_KEY=
''',
        );

        final getIt = GetIt.asNewInstance();
        registerInjectorSocket(getIt);

        PayloadFrameCodec resolveCodec() => getIt<PayloadFrameCodec>();
        expect(
          resolveCodec,
          throwsA(
            isA<StateError>()
                .having(
                  (error) => error.message,
                  'message',
                  contains('SOCKET_PAYLOAD_REQUIRE_SIGNATURE is true'),
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('SOCKET_PAYLOAD_SIGNING_KEY is empty'),
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains(
                    'set the key or disable SOCKET_PAYLOAD_REQUIRE_SIGNATURE',
                  ),
                ),
          ),
        );
      },
    );

    test(
      'resolves permissive codec when require signature is false with empty key',
      () {
        dotenv.loadFromString(
          envString: '''
SOCKET_PAYLOAD_REQUIRE_SIGNATURE=false
SOCKET_PAYLOAD_SIGNING_KEY=
''',
        );

        final getIt = GetIt.asNewInstance();
        registerInjectorSocket(getIt);

        final codec = getIt<PayloadFrameCodec>();
        check(codec).isA<PayloadFrameCodec>();
      },
    );
  });
}

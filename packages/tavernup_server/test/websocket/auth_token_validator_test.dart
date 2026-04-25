import 'package:dio/dio.dart';
import 'package:tavernup_server/src/websocket/auth_token_validator.dart';
import 'package:test/test.dart';

({Dio dio, _Capture captured}) _fakeDio({
  required dynamic Function(RequestOptions options) respond,
  int statusCode = 200,
}) {
  final captured = _Capture();
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      captured.last = options;
      handler.resolve(Response<dynamic>(
        requestOptions: options,
        statusCode: statusCode,
        data: respond(options),
      ));
    },
  ));
  return (dio: dio, captured: captured);
}

({Dio dio, _Capture captured}) _errorDio({
  required int statusCode,
  dynamic body,
}) {
  final captured = _Capture();
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      captured.last = options;
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
          type: DioExceptionType.badResponse,
        ),
        true,
      );
    },
  ));
  return (dio: dio, captured: captured);
}

class _Capture {
  RequestOptions? last;
}

SupabaseAuthTokenValidator _validator(Dio dio) => SupabaseAuthTokenValidator(
      supabaseUrl: 'http://localhost:54321',
      apiKey: 'test-key',
      dio: dio,
    );

void main() {
  test('returns TokenValid with userId for HTTP 200', () async {
    final fake = _fakeDio(respond: (_) => {'id': 'user-42', 'email': 'a@b.c'});
    final result = await _validator(fake.dio).validate('jwt-good');

    expect(result, isA<TokenValid>());
    expect((result as TokenValid).userId, 'user-42');
  });

  test('sends Bearer token in Authorization and apikey header', () async {
    final fake = _fakeDio(respond: (_) => {'id': 'user-42'});
    await _validator(fake.dio).validate('jwt-good');

    expect(fake.captured.last!.path, '/auth/v1/user');
    expect(
      fake.captured.last!.headers['Authorization'],
      'Bearer jwt-good',
    );
    expect(fake.captured.last!.headers['apikey'], 'test-key');
  });

  test('returns TokenInvalid on HTTP 401', () async {
    final fake = _errorDio(statusCode: 401, body: {'msg': 'invalid'});
    final result = await _validator(fake.dio).validate('jwt-bad');

    expect(result, isA<TokenInvalid>());
    expect((result as TokenInvalid).reason, contains('rejected'));
  });

  test('returns TokenInvalid on HTTP 5xx', () async {
    final fake = _errorDio(statusCode: 503);
    final result = await _validator(fake.dio).validate('jwt-good');

    expect(result, isA<TokenInvalid>());
    expect((result as TokenInvalid).reason, contains('503'));
  });

  test('returns TokenInvalid when response lacks id', () async {
    final fake = _fakeDio(respond: (_) => {'no_id': 'here'});
    final result = await _validator(fake.dio).validate('jwt-good');

    expect(result, isA<TokenInvalid>());
  });
}

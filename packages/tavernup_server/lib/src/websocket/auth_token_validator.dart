import 'package:dio/dio.dart';

/// Result of a token validation: either a valid user id, or an error.
sealed class TokenValidationResult {
  const TokenValidationResult();
}

class TokenValid extends TokenValidationResult {
  final String userId;
  const TokenValid(this.userId);
}

class TokenInvalid extends TokenValidationResult {
  final String reason;
  const TokenInvalid(this.reason);
}

/// Validates a Supabase Auth JWT and resolves it to a user id.
abstract interface class IAuthTokenValidator {
  Future<TokenValidationResult> validate(String token);
}

/// Validates the token by calling Supabase Auth's `/auth/v1/user`
/// endpoint with the token as a Bearer credential. Supabase returns 200
/// with the user record if the token is valid, 401 otherwise.
///
/// This costs one HTTP roundtrip per connect. Acceptable at the expected
/// concurrency. A future optimisation is local HS256 validation against
/// the project's JWT secret — keep that as a follow-up; not part of the
/// initial mechanism.
class SupabaseAuthTokenValidator implements IAuthTokenValidator {
  final Dio _dio;
  final String _apiKey;

  /// [supabaseUrl] is the project URL (e.g. `http://localhost:54321`).
  /// [apiKey] is sent in the `apikey` header — the `service_role` key
  /// is fine since the server already holds it; the Bearer token is
  /// what Supabase actually authenticates.
  SupabaseAuthTokenValidator({
    required String supabaseUrl,
    required String apiKey,
    Dio? dio,
  })  : _apiKey = apiKey,
        _dio = (dio ?? Dio())..options.baseUrl = supabaseUrl;

  @override
  Future<TokenValidationResult> validate(String token) async {
    try {
      final response = await _dio.get<dynamic>(
        '/auth/v1/user',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'apikey': _apiKey,
        }),
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['id'] is String) {
        return TokenValid(data['id'] as String);
      }
      return const TokenInvalid('Auth response missing id');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return const TokenInvalid('Token rejected by auth server');
      }
      return TokenInvalid(
          'Auth server error${status != null ? ' ($status)' : ''}: ${e.message}');
    } catch (e) {
      return TokenInvalid('Auth validation failed: $e');
    }
  }
}

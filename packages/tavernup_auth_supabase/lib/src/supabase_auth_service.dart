import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IAuthService].
///
/// Wraps [sb.SupabaseClient] auth and maps Supabase auth state changes
/// to [AuthUser] domain objects. The [sb.SupabaseClient] instance is
/// injected — the caller is responsible for initializing Supabase
/// before constructing this service.
class SupabaseAuthService implements IAuthService {
  final sb.SupabaseClient _client;

  SupabaseAuthService(this._client);

  @override
  Stream<AuthUser?> get currentUser {
    return _client.auth.onAuthStateChange.map((state) {
      final sbUser = state.session?.user;
      if (sbUser == null) return null;
      return AuthUser(id: sbUser.id, email: sbUser.email ?? '');
    });
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

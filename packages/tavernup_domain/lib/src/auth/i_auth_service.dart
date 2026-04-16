import 'auth_user.dart';

/// Abstracts authentication for the TavernUp platform.
///
/// Implementations are infrastructure-specific (e.g. Supabase, Keycloak)
/// and live in dedicated packages such as [tavernup_auth_supabase].
/// The rest of the codebase depends only on this interface.
///
/// [currentUser] emits the authenticated [AuthUser] on login,
/// and null on logout. The stream starts with the current auth state.
///
/// For the full domain [User] object (including nickname, avatar etc.),
/// use [IUserRepository] after obtaining the id from [currentUser].
abstract interface class IAuthService {
  /// Stream of the currently authenticated user, or null if signed out.
  Stream<AuthUser?> get currentUser;

  /// Signs in with email and password.
  ///
  /// Throws if the credentials are invalid or the request fails.
  Future<void> signIn(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();
}

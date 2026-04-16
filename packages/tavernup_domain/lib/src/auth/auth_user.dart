import 'package:equatable/equatable.dart';

/// Represents an authenticated user as seen by the auth layer.
///
/// [AuthUser] is intentionally minimal — it only carries the data
/// available from the authentication provider (id and email).
///
/// It is distinct from [User], which is the full domain object loaded
/// from the repository after authentication. This separation ensures
/// that [IAuthService] has no dependency on repository data.
class AuthUser extends Equatable {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});

  @override
  List<Object?> get props => [id, email];
}

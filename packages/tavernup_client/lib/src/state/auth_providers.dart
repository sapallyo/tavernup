import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

/// Provides the [IAuthService] implementation.
///
/// Must be overridden in [ProviderScope] before use — the default
/// implementation throws to catch missing DI setup early.
final authServiceProvider = Provider<IAuthService>(
  (ref) => throw UnimplementedError('authServiceProvider not overridden'),
);

/// Stream of the currently authenticated user.
///
/// Emits [AuthUser] on login and null on logout.
/// Downstream providers use the [AuthUser.id] to load the full
/// domain [User] via [IUserRepository].
final currentAuthUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).currentUser,
);

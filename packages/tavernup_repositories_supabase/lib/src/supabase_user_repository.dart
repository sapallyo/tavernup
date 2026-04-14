import 'package:supabase/supabase.dart' hide User;
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [IUserRepository].
///
/// Reads and writes to the `users` table in Supabase.
/// [client] is injected — use `Supabase.instance.client` in production
/// or a test client in tests.
class SupabaseUserRepository implements IUserRepository {
  final SupabaseClient _client;

  SupabaseUserRepository(this._client);

  @override
  Future<User?> getOwn() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getById(userId);
  }

  @override
  Future<User?> getById(String userId) async {
    final data =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    return data != null ? User.fromJson(data) : null;
  }

  @override
  Future<User?> findByNickname(String nickname) async {
    final data = await _client
        .from('users')
        .select()
        .eq('nickname', nickname)
        .maybeSingle();
    return data != null ? User.fromJson(data) : null;
  }

  @override
  Future<User> save(User user) async {
    await _client.from('users').upsert(
        user.toJson()..['created_at'] = user.createdAt.toIso8601String());
    return user;
  }

  @override
  Future<String?> uploadAvatar(String userId) async {
    // TODO: implement avatar upload via Supabase Storage
    return null;
  }
}

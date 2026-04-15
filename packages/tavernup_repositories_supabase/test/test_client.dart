import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:supabase/supabase.dart';

SupabaseClient createTestClient() {
  final env = DotEnv()..load(['../../.env.test']);

  final url = env['SUPABASE_URL'] ??
      Platform.environment['SUPABASE_URL'] ??
      (throw Exception('SUPABASE_URL not set'));

  final key = env['SUPABASE_SERVICE_ROLE_KEY'] ??
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      (throw Exception('SUPABASE_SERVICE_ROLE_KEY not set'));

  return SupabaseClient(url, key);
}

SupabaseClient createAnonTestClient() {
  final env = DotEnv()..load(['../../.env.test']);

  final url = env['SUPABASE_URL'] ??
      Platform.environment['SUPABASE_URL'] ??
      (throw Exception('SUPABASE_URL not set'));

  final key = env['SUPABASE_ANON_KEY'] ??
      Platform.environment['SUPABASE_ANON_KEY'] ??
      (throw Exception('SUPABASE_ANON_KEY not set'));

  return SupabaseClient(url, key);
}

final _testRunId = DateTime.now().millisecondsSinceEpoch;

String testEmail(String name) => '$name+$_testRunId@test.local';

Future<String> createTestAuthUser(SupabaseClient client, String email) async {
  final response = await client.auth.admin.createUser(
    AdminUserAttributes(email: email, emailConfirm: true),
  );
  return response.user!.id;
}

Future<void> deleteTestAuthUser(SupabaseClient client, String userId) async {
  await client.auth.admin.deleteUser(userId);
}

Future<void> cleanTestData(SupabaseClient client) async {
  await client
      .from('game_group_memberships')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('invitations')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('game_groups')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('story_node_instances')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('story_nodes')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('characters')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('sessions')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('user_tasks')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
  await client
      .from('users')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

  final authUsers = await client.auth.admin.listUsers();
  for (final user in authUsers) {
    if (user.email?.endsWith('@test.local') == true) {
      await deleteTestAuthUser(client, user.id);
    }
  }
}

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

Future<String> createTestAuthUser(SupabaseClient client, String email) async {
  final response = await client.auth.admin.createUser(
    AdminUserAttributes(email: email, emailConfirm: true),
  );
  return response.user!.id;
}

Future<void> deleteTestAuthUser(SupabaseClient client, String userId) async {
  await client.auth.admin.deleteUser(userId);
}

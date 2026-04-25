/// End-to-end smoke test that exercises the Phase 6 architecture
/// against a running stack:
/// - Supabase (auth + storage + db)
/// - tavernup_server on `TAVERNUP_SERVER_WS`
///
/// Sequence covered:
/// 1. service_role creates a Supabase auth user.
/// 2. anon-key client signs in with that user → access token.
/// 3. WebSocket connects to `tavernup_server`.
/// 4. `auth` frame with the token → expect success and a UserPrincipal.
/// 5. `repo.user.save` (write) and `repo.user.getById` (read) round-trip.
/// 6. `stream-subscribe` on `userTask.watchForAssignee` → service_role
///    inserts a row → expect a `stream-event` frame to arrive.
///
/// Skipped unless the four required env vars are set; the harness
/// boots zero state of its own when skipped, which is what makes this
/// safe to run alongside the unit suite.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart' hide User;
import 'package:test/test.dart';

const _smokeEnabled = bool.fromEnvironment('TAVERNUP_SMOKE_TEST');

String? get _supabaseUrl => Platform.environment['SUPABASE_URL'];
String? get _serviceRoleKey =>
    Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
String? get _anonKey => Platform.environment['SUPABASE_ANON_KEY'];
String? get _serverWs => Platform.environment['TAVERNUP_SERVER_WS'];

bool get _missingEnv =>
    _supabaseUrl == null ||
    _serviceRoleKey == null ||
    _anonKey == null ||
    _serverWs == null;

String _skipReason() {
  if (!_smokeEnabled) {
    return 'Set TAVERNUP_SMOKE_TEST=1 plus SUPABASE_URL / '
        'SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY / '
        'TAVERNUP_SERVER_WS to run.';
  }
  if (_missingEnv) {
    return 'Missing required env var: '
        'SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY / '
        'TAVERNUP_SERVER_WS.';
  }
  return '';
}

void main() {
  final skipReason = _skipReason();
  group('Phase 6 smoke', skip: skipReason.isEmpty ? false : skipReason, () {
    late SupabaseClient admin;
    late SupabaseClient anon;
    late String userId;
    late String accessToken;
    late WebSocket ws;
    final pendingRequests = <String, Completer<Map<String, dynamic>>>{};
    final streamEvents = <String, StreamController<Map<String, dynamic>>>{};

    setUpAll(() async {
      admin = SupabaseClient(_supabaseUrl!, _serviceRoleKey!);
      anon = SupabaseClient(_supabaseUrl!, _anonKey!);

      // Unique e-mail per run.
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'smoke+$stamp@test.local';
      const password = 'smoke-pw-1234567890';

      final created = await admin.auth.admin.createUser(AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
      ));
      userId = created.user!.id;

      await admin.from('users').insert({
        'id': userId,
        'nickname': 'smoke-$stamp',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final session =
          await anon.auth.signInWithPassword(email: email, password: password);
      accessToken = session.session!.accessToken;

      ws = await WebSocket.connect(_serverWs!);
      ws.listen((raw) {
        if (raw is! String) return;
        final msg = jsonDecode(raw) as Map<String, dynamic>;
        final reqId = msg['requestId'] as String?;
        if (reqId != null) {
          final c = pendingRequests.remove(reqId);
          if (c != null && !c.isCompleted) {
            if (msg['success'] == true) {
              c.complete(
                  (msg['data'] as Map<String, dynamic>?) ?? const {});
            } else {
              c.completeError(
                  StateError(msg['error'] as String? ?? 'request error'));
            }
          }
          return;
        }
        final type = msg['type'] as String?;
        if (type == 'stream-event') {
          final payload = msg['payload'] as Map<String, dynamic>;
          final streamId = payload['streamId'] as String;
          streamEvents[streamId]?.add(payload);
        }
      });
    });

    tearDownAll(() async {
      await ws.close();
      await admin.from('user_tasks').delete().eq('assignee', userId);
      await admin.from('users').delete().eq('id', userId);
      await admin.auth.admin.deleteUser(userId);
    });

    int reqCounter = 0;
    Future<Map<String, dynamic>> sendRequest(
        String type, Map<String, dynamic> payload) {
      final id = 'smoke-${reqCounter++}';
      final completer = Completer<Map<String, dynamic>>();
      pendingRequests[id] = completer;
      ws.add(jsonEncode({
        'type': type,
        'requestId': id,
        'payload': payload,
      }));
      return completer.future
          .timeout(const Duration(seconds: 10), onTimeout: () {
        pendingRequests.remove(id);
        throw TimeoutException('Server did not respond to $type');
      });
    }

    test('1. auth frame is accepted and binds a UserPrincipal', () async {
      final result = await sendRequest('auth', {'token': accessToken});
      expect(result['userId'], userId);
    });

    test('2. read over WebSocket — repo.user.getById', () async {
      final result =
          await sendRequest('repo.user.getById', {'userId': userId});
      expect((result['result'] as Map)['id'], userId);
    });

    test('3. write over WebSocket — repo.user.save', () async {
      final result = await sendRequest('repo.user.save', {
        'user': {'id': userId, 'nickname': 'smoke-renamed'},
      });
      expect((result['result'] as Map)['nickname'], 'smoke-renamed');
    });

    test('4. stream emission — userTask.watchForAssignee', () async {
      const streamId = 'smoke-stream-1';
      final events = StreamController<Map<String, dynamic>>();
      streamEvents[streamId] = events;
      addTearDown(() async {
        streamEvents.remove(streamId);
        await events.close();
      });

      await sendRequest('stream-subscribe', {
        'streamId': streamId,
        'repoName': 'userTask',
        'method': 'watchForAssignee',
        'args': {'assigneeId': userId},
      });

      // Trigger an emission via service_role insert. The server's
      // RBA wrapper (currently pass-through) sees it via Supabase
      // Realtime and pushes a stream-event frame.
      final taskId = 'smoke-task-${DateTime.now().millisecondsSinceEpoch}';
      await admin.from('user_tasks').insert({
        'id': taskId,
        'name': 'smoke-task',
        'process_instance_id': 'smoke-pi',
        'assignee': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final received = await events.stream
          .firstWhere((event) {
            final list = event['data'] as List;
            return list.any((m) => m['id'] == taskId);
          })
          .timeout(const Duration(seconds: 10));

      expect((received['data'] as List).single['id'], taskId);
    });
  });
}

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';

import 'package:tavernup_server/src/websocket/message_handler.dart';
import 'package:tavernup_server/src/websocket/websocket_server.dart';
import 'package:tavernup_server/src/webhook/webhook_handler.dart';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
      (throw Exception('SUPABASE_URL not set'));
  final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      (throw Exception('SUPABASE_SERVICE_ROLE_KEY not set'));

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  final userRepository = SupabaseUserRepository(client);
  final userTaskRepository = SupabaseUserTaskRepository(client);

  final messageHandler = MessageHandler(
    userRepository: userRepository,
    userTaskRepository: userTaskRepository,
    completeUserTask: (taskId, variables) async {
      // TODO: wire up CamundaEngineClient
    },
  );

  final wsServer = WebSocketServer(messageHandler);

  final webhookHandler = WebhookHandler(
    userTaskRepository: userTaskRepository,
    onExternalTaskCreated: () {
      // TODO: trigger fetchAndLock on EntityWorker
    },
  );

  final router = Router()
    ..get('/ws', wsServer.handler)
    ..post('/webhook/task-created', webhookHandler.handleTaskCreated);

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  print('Server running on port ${server.port}');
}

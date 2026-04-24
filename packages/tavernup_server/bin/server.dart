import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_process_camunda/tavernup_process_camunda.dart';
import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';

import 'package:tavernup_server/src/webhook/webhook_handler.dart';
import 'package:tavernup_server/src/websocket/message_handler.dart';
import 'package:tavernup_server/src/websocket/websocket_server.dart';
import 'package:tavernup_server/src/workers/entity_worker.dart';
import 'package:tavernup_server/src/workers/worker_runner.dart';

const _externalTaskTopic = 'entity-operation';
const _safetyNetInterval = Duration(seconds: 60);

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
      (throw Exception('SUPABASE_URL not set'));
  final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      (throw Exception('SUPABASE_SERVICE_ROLE_KEY not set'));
  final camundaBaseUrl = Platform.environment['CAMUNDA_BASE_URL'] ??
      (throw Exception('CAMUNDA_BASE_URL not set'));

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  final userRepository = SupabaseUserRepository(supabase);
  final userTaskRepository = SupabaseUserTaskRepository(supabase);
  final invitationRepository = SupabaseInvitationRepository(supabase);
  final gameGroupRepository = SupabaseGameGroupRepository(supabase);

  final registry = EntityRepositoryRegistry()
    ..register(invitationRepository)
    ..register(gameGroupRepository);

  final camunda = CamundaProcessEngine(baseUrl: camundaBaseUrl);

  final workerRunner = WorkerRunner(
    engine: camunda,
    workers: [EntityWorker(registry)],
    topicName: _externalTaskTopic,
    workerId: 'tavernup-server-${pid}-${DateTime.now().millisecondsSinceEpoch}',
  );

  final messageHandler = MessageHandler(
    userRepository: userRepository,
    userTaskRepository: userTaskRepository,
    completeUserTask: (taskId, variables) => camunda.completeUserTask(
      taskId: taskId,
      variables: variables,
    ),
  );

  final wsServer = WebSocketServer(messageHandler);

  final webhookHandler = WebhookHandler(
    userTaskRepository: userTaskRepository,
    onExternalTaskCreated: () => unawaited(workerRunner.runOnce()),
  );

  // Safety-net: catch external tasks whose webhook was missed.
  Timer.periodic(
    _safetyNetInterval,
    (_) => unawaited(workerRunner.runOnce()),
  );

  final router = Router()
    ..get('/ws', wsServer.handler)
    ..post('/webhook/task-created', webhookHandler.handleTaskCreated);

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  print('Server running on port ${server.port}');
  print('Camunda engine: $camundaBaseUrl');
  print('Safety-net interval: ${_safetyNetInterval.inSeconds}s');
}

import 'dart:convert';

import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/rba/rba_repository_bundle.dart';
import 'package:tavernup_server/src/websocket/message_handler.dart';

void main() {
  late MockUserRepository userRepository;
  late MockUserTaskRepository userTaskRepository;
  late RbaRepositoryBundle repos;
  late List<(String, Map<String, Variable>)> completedTasks;
  late MessageHandler handler;

  final testUser = User(
    id: 'user-1',
    nickname: 'Zephyr',
    avatarUrl: null,
    createdAt: DateTime(2025, 1, 1),
  );

  UserTask makeTask({required String id, required String assignee}) => UserTask(
        id: id,
        name: 'accept-invitation',
        processInstanceId: 'proc-1',
        variables: {},
        assignee: assignee,
        created: DateTime(2025, 1, 1),
      );

  setUp(() {
    userRepository = MockUserRepository()..seed([testUser]);
    userTaskRepository = MockUserTaskRepository();
    repos = RbaRepositoryBundle(
      user: userRepository,
      character: MockCharacterRepository(),
      gameGroup: MockGameGroupRepository(),
      invitation: MockInvitationRepository(),
      storyNode: MockStoryNodeRepository(),
      storyNodeInstance: MockStoryNodeInstanceRepository(),
      session: MockSessionRepository(),
      userTask: userTaskRepository,
    );
    completedTasks = [];
    handler = MessageHandler(
      completeUserTask: (taskId, variables) async {
        completedTasks.add((taskId, variables));
      },
    );
  });

  tearDown(() => userTaskRepository.dispose());

  Map<String, dynamic> decode(String response) =>
      jsonDecode(response) as Map<String, dynamic>;

  group('validate-user', () {
    test('returns userId for known nickname', () async {
      final response = decode(await handler.handle(jsonEncode({
        'type': 'validate-user',
        'requestId': 'req-1',
        'payload': {'nickname': 'Zephyr'},
      }), repos));
      expect(response['success'], isTrue);
      expect(response['requestId'], 'req-1');
      expect(response['data']['userId'], 'user-1');
    });

    test('returns error for unknown nickname', () async {
      final response = decode(await handler.handle(jsonEncode({
        'type': 'validate-user',
        'requestId': 'req-2',
        'payload': {'nickname': 'Unknown'},
      }), repos));
      expect(response['success'], isFalse);
      expect(response['error'], contains('not found'));
    });

    test('returns error for missing nickname', () async {
      final response = decode(await handler.handle(jsonEncode({
        'type': 'validate-user',
        'requestId': 'req-3',
        'payload': {},
      }), repos));
      expect(response['success'], isFalse);
      expect(response['error'], contains('Missing nickname'));
    });
  });

  group('complete-task', () {
    test('calls completeUserTask and deletes from repository', () async {
      await userTaskRepository.create(makeTask(id: 't-1', assignee: 'user-1'));

      final response = decode(await handler.handle(jsonEncode({
        'type': 'complete-task',
        'requestId': 'req-4',
        'payload': {
          'taskId': 't-1',
          'variables': {'accepted': 'true'},
        },
      }), repos));

      expect(response['success'], isTrue);
      expect(completedTasks, hasLength(1));
      expect(completedTasks.first.$1, 't-1');
      final tasks = await userTaskRepository.getForAssignee('user-1');
      expect(tasks, isEmpty);
    });

    test('returns error for missing taskId', () async {
      final response = decode(await handler.handle(jsonEncode({
        'type': 'complete-task',
        'requestId': 'req-5',
        'payload': {},
      }), repos));
      expect(response['success'], isFalse);
      expect(response['error'], contains('Missing taskId'));
    });
  });

  group('protocol', () {
    test('returns error for invalid JSON', () async {
      final response = decode(await handler.handle('not json', repos));
      expect(response['success'], isFalse);
      expect(response['error'], contains('Invalid JSON'));
    });

    test('returns error for unknown message type', () async {
      final response = decode(await handler.handle(jsonEncode({
        'type': 'unknown',
        'requestId': 'req-6',
        'payload': {},
      }), repos));
      expect(response['success'], isFalse);
      expect(response['error'], contains('Unknown message type'));
    });

    test('echoes requestId in every response', () async {
      final response = decode(await handler.handle(jsonEncode({
        'type': 'validate-user',
        'requestId': 'my-id-123',
        'payload': {'nickname': 'Zephyr'},
      }), repos));
      expect(response['requestId'], 'my-id-123');
    });
  });
}

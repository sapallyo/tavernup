import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_server/tavernup_server.dart';
import 'package:test/test.dart';

void main() {
  late MockInvitationRepository invitationRepo;
  late MockGameGroupRepository gameGroupRepo;
  late EntityRepositoryRegistry registry;
  late EntityWorker worker;

  setUp(() {
    invitationRepo = MockInvitationRepository();
    gameGroupRepo = MockGameGroupRepository();
    registry = EntityRepositoryRegistry();
    registry.register(invitationRepo);
    registry.register(gameGroupRepo);
    worker = EntityWorker(registry);
  });

  WorkerTask buildTask({
    required String entityType,
    required String operation,
    Map<String, Variable> extraVariables = const {},
  }) {
    return WorkerTask(
      id: 'task-1',
      name: 'entity-operation',
      processInstanceId: 'proc-1',
      topicName: 'entity-operation',
      variables: {
        'entityType': Variable.string(entityType),
        'operation': Variable.string(operation),
        ...extraVariables,
      },
    );
  }

  group('EntityWorker', () {
    group('canHandle', () {
      test('returns true for task with entityType and operation', () {
        expect(
          worker.canHandle(buildTask(
            entityType: 'invitation',
            operation: 'create',
          )),
          isTrue,
        );
      });

      test('returns false when entityType is missing', () {
        final task = WorkerTask(
          id: 'task-1',
          name: 'entity-operation',
          processInstanceId: 'proc-1',
          topicName: 'entity-operation',
          variables: {'operation': Variable.string('create')},
        );
        expect(worker.canHandle(task), isFalse);
      });

      test('returns false when operation is missing', () {
        final task = WorkerTask(
          id: 'task-1',
          name: 'entity-operation',
          processInstanceId: 'proc-1',
          topicName: 'entity-operation',
          variables: {'entityType': Variable.string('invitation')},
        );
        expect(worker.canHandle(task), isFalse);
      });

      test('returns false for UserTask', () {
        final task = UserTask(
          id: 'task-1',
          name: 'entity-operation',
          processInstanceId: 'proc-1',
          assignee: 'user-1',
          created: DateTime.now(),
          variables: {
            'entityType': Variable.string('invitation'),
            'operation': Variable.string('create'),
          },
        );
        expect(worker.canHandle(task), isFalse);
      });
    });

    group('execute — create', () {
      test('creates invitation and returns entityId', () async {
        final task = buildTask(
          entityType: 'invitation',
          operation: 'create',
          extraVariables: {
            'groupId': Variable.string('group-1'),
            'invitedUserId': Variable.string('user-2'),
            'field:gameGroupId': Variable.string(r'$groupId'),
            'field:invitedUserId': Variable.string(r'$invitedUserId'),
            'field:role': Variable.string('player'),
          },
        );
        final result = await worker.execute(task);
        expect(result.containsKey('entityId'), isTrue);
        expect(result['entityId']?.value, isNotEmpty);
      });

      test('creates membership and returns entityId', () async {
        gameGroupRepo.seed([
          GameGroup(
            id: 'group-1',
            name: 'Test Group',
            createdBy: 'user-1',
            createdAt: DateTime.now(),
          ),
        ]);
        final task = buildTask(
          entityType: 'membership',
          operation: 'create',
          extraVariables: {
            'groupId': Variable.string('group-1'),
            'userId': Variable.string('user-2'),
            'field:gameGroupId': Variable.string(r'$groupId'),
            'field:userId': Variable.string(r'$userId'),
            'field:role': Variable.string('player'),
          },
        );
        final result = await worker.execute(task);
        expect(result.containsKey('entityId'), isTrue);
      });
    });

    group('execute — update', () {
      test('updates invitation status', () async {
        final inv = await invitationRepo.createInvitation(
          'group-1',
          GameGroupRole.player,
          'user-2',
        );
        final task = buildTask(
          entityType: 'invitation',
          operation: 'update',
          extraVariables: {
            'field:id': Variable.string(inv.id),
            'field:status': Variable.string('accepted'),
          },
        );
        await worker.execute(task);
        final updated = await invitationRepo.getById(inv.id);
        expect(updated?.status, InvitationStatus.accepted);
      });
    });

    group('execute — delete', () {
      test('deletes invitation', () async {
        final inv = await invitationRepo.createInvitation(
          'group-1',
          GameGroupRole.player,
          'user-2',
        );
        final task = buildTask(
          entityType: 'invitation',
          operation: 'delete',
          extraVariables: {
            'field:id': Variable.string(inv.id),
          },
        );
        await worker.execute(task);
        expect(await invitationRepo.getById(inv.id), isNull);
      });
    });

    group('execute — errors', () {
      test('throws ArgumentError for unknown operation', () {
        final task = buildTask(
          entityType: 'invitation',
          operation: 'unknown',
        );
        expect(() => worker.execute(task), throwsArgumentError);
      });

      test('throws ArgumentError for unknown entityType', () {
        final task = buildTask(
          entityType: 'unknown',
          operation: 'create',
        );
        expect(() => worker.execute(task), throwsArgumentError);
      });

      test('throws ArgumentError for non-WorkerTask', () {
        final task = UserTask(
          id: 'task-1',
          name: 'entity-operation',
          processInstanceId: 'proc-1',
          assignee: 'user-1',
          created: DateTime.now(),
          variables: {
            'entityType': Variable.string('invitation'),
            'operation': Variable.string('create'),
          },
        );
        expect(() => worker.execute(task), throwsArgumentError);
      });
    });

    group('field resolution', () {
      test('resolves process variable references', () async {
        final task = buildTask(
          entityType: 'invitation',
          operation: 'create',
          extraVariables: {
            'groupId': Variable.string('group-1'),
            'invitedUserId': Variable.string('user-2'),
            'field:gameGroupId': Variable.string(r'$groupId'),
            'field:invitedUserId': Variable.string(r'$invitedUserId'),
            'field:role': Variable.string('player'),
          },
        );
        final result = await worker.execute(task);
        final inv = await invitationRepo.getById(
          result['entityId']!.value as String,
        );
        expect(inv?.gameGroupId, 'group-1');
        expect(inv?.invitedUserId, 'user-2');
      });

      test('uses static values directly', () async {
        final task = buildTask(
          entityType: 'invitation',
          operation: 'create',
          extraVariables: {
            'field:gameGroupId': Variable.string('group-1'),
            'field:invitedUserId': Variable.string('user-2'),
            'field:role': Variable.string('gm'),
          },
        );
        final result = await worker.execute(task);
        final inv = await invitationRepo.getById(
          result['entityId']!.value as String,
        );
        expect(inv?.role, GameGroupRole.gm);
      });
    });
  });
}

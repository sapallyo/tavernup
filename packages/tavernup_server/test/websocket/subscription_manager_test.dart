import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:test/test.dart';

import 'package:tavernup_server/src/rba/principal.dart';
import 'package:tavernup_server/src/rba/rba_factory.dart';
import 'package:tavernup_server/src/rba/rba_repository_bundle.dart';
import 'package:tavernup_server/src/websocket/subscription_manager.dart';

class _StubFactory implements RbaFactory {
  final RbaRepositoryBundle _bundle;
  _StubFactory(this._bundle);

  @override
  RbaRepositoryBundle forPrincipal(Principal principal) => _bundle;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

({MockUserTaskRepository userTask, RbaRepositoryBundle bundle, _StubFactory factory})
    _harness() {
  final userTask = MockUserTaskRepository();
  final bundle = RbaRepositoryBundle(
    user: MockUserRepository(),
    character: MockCharacterRepository(),
    gameGroup: MockGameGroupRepository(),
    invitation: MockInvitationRepository(),
    storyNode: MockStoryNodeRepository(),
    storyNodeInstance: MockStoryNodeInstanceRepository(),
    session: MockSessionRepository(),
    userTask: userTask,
  );
  return (userTask: userTask, bundle: bundle, factory: _StubFactory(bundle));
}

UserTask _task(String id, String assignee) => UserTask(
      id: id,
      name: 'accept-invitation',
      processInstanceId: 'pi-1',
      variables: const {},
      assignee: assignee,
      created: DateTime(2026, 4, 24, 12),
    );

void main() {
  test('first subscriber opens an upstream, second under same principal shares it',
      () async {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);
    const principal = UserPrincipal('user-1');

    final eventsA = <Object?>[];
    final eventsB = <Object?>[];

    final unsubA = mgr.subscribe(
      principal: principal,
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'user-1'},
      onEvent: eventsA.add,
    );
    expect(mgr.upstreamCount, 1);

    final unsubB = mgr.subscribe(
      principal: principal,
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'user-1'},
      onEvent: eventsB.add,
    );
    expect(mgr.upstreamCount, 1, reason: 'same args same principal → shared');

    await h.userTask.create(_task('t-1', 'user-1'));
    await Future<void>.delayed(Duration.zero);

    expect(eventsA, hasLength(1));
    expect(eventsB, hasLength(1));

    unsubA();
    unsubB();
    expect(mgr.upstreamCount, 0,
        reason: 'last unsubscribe tears down the upstream');
  });

  test('different principals get independent upstreams', () async {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);

    mgr.subscribe(
      principal: const UserPrincipal('user-1'),
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'user-1'},
      onEvent: (_) {},
    );
    mgr.subscribe(
      principal: const UserPrincipal('user-2'),
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'user-1'},
      onEvent: (_) {},
    );

    expect(mgr.upstreamCount, 2);
  });

  test('different args get independent upstreams', () async {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);
    const principal = UserPrincipal('user-1');

    mgr.subscribe(
      principal: principal,
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'user-1'},
      onEvent: (_) {},
    );
    mgr.subscribe(
      principal: principal,
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'user-2'},
      onEvent: (_) {},
    );

    expect(mgr.upstreamCount, 2);
  });

  test('stream events are serialised via toJson per element', () async {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);
    final received = <Object?>[];

    mgr.subscribe(
      principal: const UserPrincipal('u'),
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'u'},
      onEvent: received.add,
    );

    await h.userTask.create(_task('t-1', 'u'));
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    final list = received.single as List;
    expect(list.single, isA<Map<String, dynamic>>());
    expect((list.single as Map)['id'], 't-1');
    expect((list.single as Map)['assignee'], 'u');
  });

  test('one of two subscribers leaving keeps the upstream alive', () async {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);
    const principal = UserPrincipal('u');

    final eventsA = <Object?>[];
    final eventsB = <Object?>[];

    final unsubA = mgr.subscribe(
      principal: principal,
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'u'},
      onEvent: eventsA.add,
    );
    mgr.subscribe(
      principal: principal,
      repoName: 'userTask',
      method: 'watchForAssignee',
      args: const {'assigneeId': 'u'},
      onEvent: eventsB.add,
    );

    unsubA();
    expect(mgr.upstreamCount, 1);

    await h.userTask.create(_task('t-1', 'u'));
    await Future<void>.delayed(Duration.zero);

    expect(eventsA, isEmpty);
    expect(eventsB, hasLength(1));
  });

  test('unknown stream method throws ArgumentError', () {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);

    expect(
      () => mgr.subscribe(
        principal: const UserPrincipal('u'),
        repoName: 'userTask',
        method: 'flyToTheMoon',
        args: const {},
        onEvent: (_) {},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('args list order does not affect sharing', () async {
    final h = _harness();
    final mgr = SubscriptionManager(h.factory);

    mgr.subscribe(
      principal: const UserPrincipal('u'),
      repoName: 'session',
      method: 'watchByIds',
      args: const {
        'sessionIds': ['a', 'b']
      },
      onEvent: (_) {},
    );
    mgr.subscribe(
      principal: const UserPrincipal('u'),
      repoName: 'session',
      method: 'watchByIds',
      args: const {
        'sessionIds': ['b', 'a']
      },
      onEvent: (_) {},
    );

    expect(mgr.upstreamCount, 1,
        reason: 'list args canonicalise so reorder shares the upstream');
  });
}

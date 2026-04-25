import 'dart:async';

import 'package:tavernup_domain/tavernup_domain.dart';

import '../rba/principal.dart';
import '../rba/rba_factory.dart';
import '../rba/rba_repository_bundle.dart';

/// Multiplexes upstream stream subscriptions across same-principal
/// subscribers and tears them down once the last subscriber leaves.
///
/// Upstream key: `(principal, repoName, method, args)`. Keying by
/// principal preserves correctness when the RBA wrappers later apply
/// principal-specific filter/project to events — different principals
/// must not share an upstream subscription, because they may see
/// different projections of the same row. Multiple subscribers under
/// the **same** principal (e.g. several browser tabs) do share the
/// upstream and ref-count it.
///
/// Stream events are serialised to wire-encodable shapes inside the
/// stream resolver (one model toJson per element of the emitted list).
/// The 5 stream-returning repository methods are mapped explicitly;
/// any other method name throws [ArgumentError].
class SubscriptionManager {
  final RbaFactory _rba;
  final Map<_UpstreamKey, _Upstream> _upstreams = {};

  SubscriptionManager(this._rba);

  /// Subscribes to a stream and forwards each event to [onEvent].
  /// Returns a function the caller invokes to unsubscribe — releases
  /// the subscriber's listener and decrements the upstream ref-count.
  /// When the last subscriber leaves, the upstream subscription is
  /// cancelled and the controller closed.
  ///
  /// [onError] and [onDone] are forwarded from the broadcast stream.
  void Function() subscribe({
    required Principal principal,
    required String repoName,
    required String method,
    required Map<String, dynamic> args,
    required void Function(Object? data) onEvent,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) {
    final key = _UpstreamKey(principal, repoName, method, args);
    final upstream = _upstreams.putIfAbsent(
      key,
      () => _openUpstream(principal, repoName, method, args),
    );
    upstream.refCount++;

    final subscriberSub = upstream.controller.stream.listen(
      onEvent,
      onError: onError ?? (_) {},
      onDone: onDone,
    );

    return () {
      unawaited(subscriberSub.cancel());
      upstream.refCount--;
      if (upstream.refCount <= 0) {
        unawaited(upstream.rawSubscription.cancel());
        unawaited(upstream.controller.close());
        _upstreams.remove(key);
      }
    };
  }

  /// Number of distinct upstream subscriptions currently open.
  /// Useful for tests and for visibility in operational metrics.
  int get upstreamCount => _upstreams.length;

  _Upstream _openUpstream(
    Principal principal,
    String repoName,
    String method,
    Map<String, dynamic> args,
  ) {
    final repos = _rba.forPrincipal(principal);
    final controller = StreamController<Object?>.broadcast();
    final stream = _resolveStream(repos, repoName, method, args);
    final sub = stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    return _Upstream(controller: controller, rawSubscription: sub);
  }

  Stream<Object?> _resolveStream(
    RbaRepositoryBundle repos,
    String repoName,
    String method,
    Map<String, dynamic> args,
  ) {
    final key = '$repoName.$method';
    switch (key) {
      case 'character.watchOwned':
        return repos.character
            .watchOwned(_str(args, 'ownerId'))
            .map((list) => list.map((c) => c.toJson()).toList());
      case 'gameGroup.watchAll':
        return repos.gameGroup
            .watchAll(_str(args, 'userId'))
            .map((list) => list.map((g) => g.toJson()).toList());
      case 'storyNode.watchChildren':
        return repos.storyNode
            .watchChildren(_str(args, 'parentId'))
            .map((list) => list.map((n) => n.toJson()).toList());
      case 'session.watchByIds':
        return repos.session
            .watchByIds(List<String>.from(args['sessionIds'] as List))
            .map((list) => list.map((s) => s.toJson()).toList());
      case 'userTask.watchForAssignee':
        return repos.userTask
            .watchForAssignee(_str(args, 'assigneeId'))
            .map((list) => list.map(_userTaskToJson).toList());
      default:
        throw ArgumentError('Unknown stream method: $key');
    }
  }

  Map<String, dynamic> _userTaskToJson(UserTask task) => {
        'id': task.id,
        'name': task.name,
        'processInstanceId': task.processInstanceId,
        'assignee': task.assignee,
        'created': task.created.toIso8601String(),
        'variables': task.variables.map((k, v) => MapEntry(k, {
              'type': v.type.name,
              'value': v.value,
            })),
      };

  String _str(Map<String, dynamic> args, String key) {
    final v = args[key];
    if (v is! String) {
      throw ArgumentError('Missing or non-string parameter: $key');
    }
    return v;
  }
}

class _Upstream {
  final StreamController<Object?> controller;
  final StreamSubscription<dynamic> rawSubscription;
  int refCount = 0;

  _Upstream({required this.controller, required this.rawSubscription});
}

class _UpstreamKey {
  final Principal principal;
  final String repoName;
  final String method;
  final String _argsKey;

  _UpstreamKey(this.principal, this.repoName, this.method,
      Map<String, dynamic> args)
      : _argsKey = _canonicalise(args);

  static String _canonicalise(Map<String, dynamic> args) {
    final keys = args.keys.toList()..sort();
    final buf = StringBuffer();
    for (final k in keys) {
      final v = args[k];
      buf.write('$k=');
      if (v is List) {
        buf.write('[${(v.toList()..sort((a, b) => '$a'.compareTo('$b'))).join(',')}]');
      } else {
        buf.write('$v');
      }
      buf.write(';');
    }
    return buf.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is _UpstreamKey &&
      other.principal == principal &&
      other.repoName == repoName &&
      other.method == method &&
      other._argsKey == _argsKey;

  @override
  int get hashCode => Object.hash(principal, repoName, method, _argsKey);
}

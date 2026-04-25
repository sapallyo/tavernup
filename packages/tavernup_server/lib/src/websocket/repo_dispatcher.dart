import 'package:tavernup_domain/tavernup_domain.dart';

import '../rba/rba_repository_bundle.dart';

/// Routes a `repo.<repoName>.<method>` WebSocket frame onto the
/// matching method of the connection's [RbaRepositoryBundle].
///
/// Arguments arrive as a JSON object keyed by the method's parameter
/// names; results are returned as a JSON-encodable value (a Map for
/// models, a List for collections, `null` for void/missing).
///
/// Stream-returning methods (`watch*`) are deliberately NOT routed here
/// — they require a separate subscribe/unsubscribe protocol introduced
/// in Phase 5. Calls to those types throw [UnsupportedError]; the
/// MessageHandler turns that into a structured error response.
class RepoDispatcher {
  static const _streamMethodMessage =
      'Stream methods are not routed via repo request frames. '
      'Subscribe via the stream protocol introduced in Phase 5.';

  Future<Object?> dispatch(
    String type,
    Map<String, dynamic> payload,
    RbaRepositoryBundle repos,
  ) async {
    return switch (type) {
      // ── User ──
      'repo.user.getOwn' => (await repos.user.getOwn())?.toJson(),
      'repo.user.getById' => (await repos.user.getById(_str(payload, 'userId')))?.toJson(),
      'repo.user.findByNickname' =>
        (await repos.user.findByNickname(_str(payload, 'nickname')))?.toJson(),
      'repo.user.save' =>
        (await repos.user.save(User.fromJson(_map(payload, 'user')))).toJson(),
      'repo.user.uploadAvatar' => await _uploadAvatar(repos, payload),
      'repo.user.getAvatarSignedUrl' => await repos.user.getAvatarSignedUrl(
          path: _str(payload, 'path'),
          expiresIn: Duration(seconds: _intOr(payload, 'expiresInSeconds', 3600)),
        ),
      'repo.user.createAvatarUploadUrl' => () async {
          final result = await repos.user.createAvatarUploadUrl(
            userId: _str(payload, 'userId'),
            contentType: _str(payload, 'contentType'),
          );
          return {'uploadUrl': result.uploadUrl, 'path': result.path};
        }(),

      // ── Character ──
      'repo.character.getOwned' => (await repos.character.getOwned(_str(payload, 'ownerId')))
          .map((c) => c.toJson())
          .toList(),
      'repo.character.getVisible' => (await repos.character.getVisible(_str(payload, 'userId')))
          .map((c) => c.toJson())
          .toList(),
      'repo.character.getById' =>
        (await repos.character.getById(_str(payload, 'id')))?.toJson(),
      'repo.character.save' => () async {
          await repos.character.save(Character.fromJson(_map(payload, 'character')));
          return null;
        }(),
      'repo.character.delete' => () async {
          await repos.character.delete(_str(payload, 'id'));
          return null;
        }(),
      'repo.character.grantVisibility' => () async {
          await repos.character
              .grantVisibility(_str(payload, 'characterId'), _str(payload, 'userId'));
          return null;
        }(),
      'repo.character.revokeVisibility' => () async {
          await repos.character
              .revokeVisibility(_str(payload, 'characterId'), _str(payload, 'userId'));
          return null;
        }(),

      // ── GameGroup ──
      'repo.gameGroup.getAll' => (await repos.gameGroup.getAll(_str(payload, 'userId')))
          .map((g) => g.toJson())
          .toList(),
      'repo.gameGroup.getById' =>
        (await repos.gameGroup.getById(_str(payload, 'id')))?.toJson(),
      'repo.gameGroup.createGameGroup' => (await repos.gameGroup.createGameGroup(
          _str(payload, 'name'),
          _strOrNull(payload, 'description'),
          _str(payload, 'ruleset'),
        ))
            .toJson(),
      'repo.gameGroup.addMember' => () async {
          await repos.gameGroup.addMember(
            _str(payload, 'gameGroupId'),
            _str(payload, 'userId'),
            _role(payload, 'role'),
          );
          return null;
        }(),
      'repo.gameGroup.removeMember' => () async {
          await repos.gameGroup.removeMember(
            _str(payload, 'gameGroupId'),
            _str(payload, 'userId'),
            _role(payload, 'role'),
          );
          return null;
        }(),
      'repo.gameGroup.getMembers' =>
        (await repos.gameGroup.getMembers(_str(payload, 'gameGroupId')))
            .map((m) => m.toJson())
            .toList(),
      'repo.gameGroup.getMembersWithProfiles' =>
        (await repos.gameGroup.getMembersWithProfiles(_str(payload, 'gameGroupId')))
            .map((pair) => {
                  'membership': pair.$1.toJson(),
                  'user': pair.$2?.toJson(),
                })
            .toList(),
      'repo.gameGroup.getRolesForUser' =>
        (await repos.gameGroup.getRolesForUser(
                _str(payload, 'gameGroupId'), _str(payload, 'userId')))
            .map((r) => r.name)
            .toList(),
      // IEntityRepository methods (gameGroup → 'membership')
      'repo.gameGroup.create' =>
        await repos.gameGroup.create(_map(payload, 'data')),
      'repo.gameGroup.update' => () async {
          await repos.gameGroup
              .update(_str(payload, 'id'), _map(payload, 'data'));
          return null;
        }(),
      'repo.gameGroup.delete' => () async {
          await repos.gameGroup.delete(_str(payload, 'id'));
          return null;
        }(),

      // ── Invitation ──
      'repo.invitation.createInvitation' => (await repos.invitation.createInvitation(
          _str(payload, 'gameGroupId'),
          _role(payload, 'role'),
          _str(payload, 'invitedUserId'),
        ))
            .toJson(),
      'repo.invitation.getById' =>
        (await repos.invitation.getById(_str(payload, 'id')))?.toJson(),
      'repo.invitation.getForUser' =>
        (await repos.invitation.getForUser(_str(payload, 'userId')))
            .map((i) => i.toJson())
            .toList(),
      'repo.invitation.getForGameGroup' =>
        (await repos.invitation.getForGameGroup(_str(payload, 'gameGroupId')))
            .map((i) => i.toJson())
            .toList(),
      // IEntityRepository methods (invitation → 'invitation')
      'repo.invitation.create' =>
        await repos.invitation.create(_map(payload, 'data')),
      'repo.invitation.update' => () async {
          await repos.invitation
              .update(_str(payload, 'id'), _map(payload, 'data'));
          return null;
        }(),
      'repo.invitation.delete' => () async {
          await repos.invitation.delete(_str(payload, 'id'));
          return null;
        }(),

      // ── StoryNode ──
      'repo.storyNode.getRoots' =>
        (await repos.storyNode.getRoots(_str(payload, 'userId')))
            .map((n) => n.toJson())
            .toList(),
      'repo.storyNode.getChildren' =>
        (await repos.storyNode.getChildren(_str(payload, 'parentId')))
            .map((n) => n.toJson())
            .toList(),
      'repo.storyNode.getById' =>
        (await repos.storyNode.getById(_str(payload, 'id')))?.toJson(),
      'repo.storyNode.create' => (await repos.storyNode.create(
          title: _str(payload, 'title'),
          description: _strOrNull(payload, 'description'),
          imageUrl: _strOrNull(payload, 'imageUrl'),
          systemKey: _strOrNull(payload, 'systemKey'),
          parentId: _strOrNull(payload, 'parentId'),
        ))
            .toJson(),
      'repo.storyNode.save' => () async {
          await repos.storyNode.save(StoryNode.fromJson(_map(payload, 'node')));
          return null;
        }(),
      'repo.storyNode.delete' => () async {
          await repos.storyNode.delete(_str(payload, 'id'));
          return null;
        }(),

      // ── StoryNodeInstance ──
      'repo.storyNodeInstance.getById' =>
        (await repos.storyNodeInstance.getById(_str(payload, 'id')))?.toJson(),
      'repo.storyNodeInstance.getForTemplate' =>
        (await repos.storyNodeInstance
                .getForTemplate(_str(payload, 'templateId')))
            .map((i) => i.toJson())
            .toList(),
      'repo.storyNodeInstance.getOrCreate' =>
        (await repos.storyNodeInstance.getOrCreate(_str(payload, 'templateId')))
            .toJson(),
      'repo.storyNodeInstance.updateStatus' => () async {
          await repos.storyNodeInstance.updateStatus(
            _str(payload, 'id'),
            StoryNodeStatus.values.byName(_str(payload, 'status')),
          );
          return null;
        }(),
      'repo.storyNodeInstance.delete' => () async {
          await repos.storyNodeInstance.delete(_str(payload, 'id'));
          return null;
        }(),

      // ── Session ──
      'repo.session.getById' =>
        (await repos.session.getById(_str(payload, 'id')))?.toJson(),
      'repo.session.getByIds' => (await repos.session.getByIds(
              List<String>.from(payload['sessionIds'] as List)))
          .map((s) => s.toJson())
          .toList(),
      'repo.session.create' => (await repos.session.create()).toJson(),
      'repo.session.addInstance' => () async {
          await repos.session.addInstance(
              _str(payload, 'sessionId'), _str(payload, 'instanceId'));
          return null;
        }(),
      'repo.session.removeInstance' => () async {
          await repos.session.removeInstance(
              _str(payload, 'sessionId'), _str(payload, 'instanceId'));
          return null;
        }(),
      'repo.session.addParticipant' => () async {
          await repos.session.addParticipant(
            _str(payload, 'sessionId'),
            AdventureCharacter.fromJson(_map(payload, 'participant')),
          );
          return null;
        }(),
      'repo.session.removeParticipant' => () async {
          await repos.session.removeParticipant(
              _str(payload, 'sessionId'), _str(payload, 'participantId'));
          return null;
        }(),
      'repo.session.delete' => () async {
          await repos.session.delete(_str(payload, 'id'));
          return null;
        }(),

      // ── UserTask ──
      'repo.userTask.getForAssignee' =>
        (await repos.userTask.getForAssignee(_str(payload, 'assigneeId')))
            .map(_userTaskToJson)
            .toList(),
      'repo.userTask.delete' => () async {
          await repos.userTask.delete(_str(payload, 'taskId'));
          return null;
        }(),

      // ── Stream methods (Phase 5) ──
      'repo.character.watchOwned' ||
      'repo.gameGroup.watchAll' ||
      'repo.storyNode.watchChildren' ||
      'repo.session.watchByIds' ||
      'repo.userTask.watchForAssignee' =>
        throw UnsupportedError(_streamMethodMessage),

      _ => throw ArgumentError('Unknown repo method: $type'),
    };
  }

  Future<Object?> _uploadAvatar(
    RbaRepositoryBundle repos,
    Map<String, dynamic> payload,
  ) async {
    // Avatar bytes are not transported in repo frames — see
    // architecture.md "Storage Access". Reject explicitly so a client
    // cannot accidentally tunnel image payloads through this path.
    throw UnsupportedError(
      'Avatar bytes are uploaded directly to Storage via signed URLs, '
      'not via repo request frames.',
    );
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

  String _str(Map<String, dynamic> payload, String key) {
    final v = payload[key];
    if (v is! String) {
      throw ArgumentError('Missing or non-string parameter: $key');
    }
    return v;
  }

  String? _strOrNull(Map<String, dynamic> payload, String key) {
    final v = payload[key];
    if (v == null) return null;
    if (v is! String) {
      throw ArgumentError('Non-string parameter: $key');
    }
    return v;
  }

  Map<String, dynamic> _map(Map<String, dynamic> payload, String key) {
    final v = payload[key];
    if (v is! Map<String, dynamic>) {
      throw ArgumentError('Missing or non-object parameter: $key');
    }
    return v;
  }

  GameGroupRole _role(Map<String, dynamic> payload, String key) {
    return GameGroupRole.values.byName(_str(payload, key));
  }

  int _intOr(Map<String, dynamic> payload, String key, int fallback) {
    final v = payload[key];
    if (v == null) return fallback;
    if (v is int) return v;
    throw ArgumentError('Non-int parameter: $key');
  }
}

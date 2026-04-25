import 'package:http/http.dart' as http;
import 'package:tavernup_domain/tavernup_domain.dart';

import 'remote_character_repository.dart';
import 'remote_game_group_repository.dart';
import 'remote_invitation_repository.dart';
import 'remote_session_repository.dart';
import 'remote_story_node_instance_repository.dart';
import 'remote_story_node_repository.dart';
import 'remote_user_repository.dart';
import 'remote_user_task_repository.dart';

/// Convenience bundle: the eight `IXxxRepository` implementations the
/// Flutter client wires into Riverpod, all sharing the same
/// [IRealtimeTransport]. Use [createRemoteRepositoryBundle] in
/// `main.dart` after [IRealtimeTransport.connect] has resolved.
class RemoteRepositoryBundle {
  final IUserRepository user;
  final ICharacterRepository character;
  final IGameGroupRepository gameGroup;
  final IInvitationRepository invitation;
  final IStoryNodeRepository storyNode;
  final IStoryNodeInstanceRepository storyNodeInstance;
  final ISessionRepository session;
  final IUserTaskRepository userTask;

  const RemoteRepositoryBundle({
    required this.user,
    required this.character,
    required this.gameGroup,
    required this.invitation,
    required this.storyNode,
    required this.storyNodeInstance,
    required this.session,
    required this.userTask,
  });
}

/// Builds a [RemoteRepositoryBundle] backed by [transport].
///
/// [httpClient] is shared with [RemoteUserRepository] for the avatar
/// upload PUT. Pass a custom one in tests.
RemoteRepositoryBundle createRemoteRepositoryBundle(
  IRealtimeTransport transport, {
  http.Client? httpClient,
}) {
  return RemoteRepositoryBundle(
    user: RemoteUserRepository(transport, httpClient: httpClient),
    character: RemoteCharacterRepository(transport),
    gameGroup: RemoteGameGroupRepository(transport),
    invitation: RemoteInvitationRepository(transport),
    storyNode: RemoteStoryNodeRepository(transport),
    storyNodeInstance: RemoteStoryNodeInstanceRepository(transport),
    session: RemoteSessionRepository(transport),
    userTask: RemoteUserTaskRepository(transport),
  );
}

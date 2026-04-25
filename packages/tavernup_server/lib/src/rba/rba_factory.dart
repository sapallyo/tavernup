import 'package:tavernup_repositories_supabase/tavernup_repositories_supabase.dart';

import 'principal.dart';
import 'rba_repository_bundle.dart';
import 'wrappers/character_repository_wrapper.dart';
import 'wrappers/game_group_repository_wrapper.dart';
import 'wrappers/invitation_repository_wrapper.dart';
import 'wrappers/session_repository_wrapper.dart';
import 'wrappers/story_node_instance_repository_wrapper.dart';
import 'wrappers/story_node_repository_wrapper.dart';
import 'wrappers/user_repository_wrapper.dart';
import 'wrappers/user_task_repository_wrapper.dart';

/// The single entry point through which the server obtains repository
/// instances. Owns the only [RawRepositoryBundle] in the process and
/// produces RBA-wrapped repositories on demand for a given [Principal].
///
/// Constructed once during server bootstrap. The `service_role`
/// Supabase client construction happens here (inside
/// [createRawRepositoryBundle]) and the resulting raw repositories
/// never escape this module — the `custom_lint` rule restricting
/// imports of `tavernup_repositories_supabase/src/...` enforces that
/// raw access remains scoped to this file.
class RbaFactory {
  final RawRepositoryBundle _raw;

  RbaFactory._(this._raw);

  factory RbaFactory.fromEnvironment({
    required String supabaseUrl,
    required String serviceRoleKey,
  }) {
    return RbaFactory._(createRawRepositoryBundle(
      supabaseUrl: supabaseUrl,
      serviceRoleKey: serviceRoleKey,
    ));
  }

  /// Returns a fresh bundle of authorizing wrappers bound to [principal].
  /// One wrapper per repository — every call into them carries the
  /// principal forward into filter/project decisions.
  RbaRepositoryBundle forPrincipal(Principal principal) {
    return RbaRepositoryBundle(
      user: UserRepositoryWrapper(_raw.user, principal),
      character: CharacterRepositoryWrapper(_raw.character, principal),
      gameGroup: GameGroupRepositoryWrapper(_raw.gameGroup, principal),
      invitation: InvitationRepositoryWrapper(_raw.invitation, principal),
      storyNode: StoryNodeRepositoryWrapper(_raw.storyNode, principal),
      storyNodeInstance: StoryNodeInstanceRepositoryWrapper(
          _raw.storyNodeInstance, principal),
      session: SessionRepositoryWrapper(_raw.session, principal),
      userTask: UserTaskRepositoryWrapper(_raw.userTask, principal),
    );
  }
}

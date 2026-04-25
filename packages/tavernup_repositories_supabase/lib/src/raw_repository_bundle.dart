import 'package:supabase/supabase.dart' hide User, Session;
import 'package:tavernup_domain/tavernup_domain.dart';

import 'supabase_character_repository.dart';
import 'supabase_game_group_repository.dart';
import 'supabase_invitation_repository.dart';
import 'supabase_session_repository.dart';
import 'supabase_story_node_instance_repository.dart';
import 'supabase_story_node_repository.dart';
import 'supabase_sync_service.dart';
import 'supabase_user_repository.dart';
import 'supabase_user_task_repository.dart';

/// Bundle of raw, unauthorized Supabase repositories plus the sync
/// service. Produced by [createRawRepositoryBundle] and consumed only
/// by the server's RBA layer, which wraps each entry before exposing
/// anything to the rest of the application.
///
/// The fields are typed as the domain interfaces so that wrapping is
/// straightforward; the concrete classes remain private to this package.
class RawRepositoryBundle {
  final IUserRepository user;
  final ICharacterRepository character;
  final IGameGroupRepository gameGroup;
  final IInvitationRepository invitation;
  final IStoryNodeRepository storyNode;
  final IStoryNodeInstanceRepository storyNodeInstance;
  final ISessionRepository session;
  final IUserTaskRepository userTask;
  final ISyncService sync;

  const RawRepositoryBundle({
    required this.user,
    required this.character,
    required this.gameGroup,
    required this.invitation,
    required this.storyNode,
    required this.storyNodeInstance,
    required this.session,
    required this.userTask,
    required this.sync,
  });
}

/// Constructs the raw repository bundle backed by a Supabase client
/// using the `service_role` key.
///
/// This is the **only** public entry point of `tavernup_repositories_supabase`
/// — the concrete `Supabase*Repository` classes are not exported. Inside
/// the server, this function may only be called from the RBA factory; a
/// `custom_lint` rule enforces that boundary, see architecture.md
/// "Authorization Layer (RBA)" → "Structural Enforcement".
RawRepositoryBundle createRawRepositoryBundle({
  required String supabaseUrl,
  required String serviceRoleKey,
}) {
  final client = SupabaseClient(supabaseUrl, serviceRoleKey);
  return RawRepositoryBundle(
    user: SupabaseUserRepository(client),
    character: SupabaseCharacterRepository(client),
    gameGroup: SupabaseGameGroupRepository(client),
    invitation: SupabaseInvitationRepository(client),
    storyNode: SupabaseStoryNodeRepository(client),
    storyNodeInstance: SupabaseStoryNodeInstanceRepository(client),
    session: SupabaseSessionRepository(client),
    userTask: SupabaseUserTaskRepository(client),
    sync: SupabaseSyncService(client),
  );
}

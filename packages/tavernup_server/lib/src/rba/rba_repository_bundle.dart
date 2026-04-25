import 'package:tavernup_domain/tavernup_domain.dart';

/// Bundle of RBA-wrapped repositories produced by [RbaFactory] for a
/// specific [Principal]. Every consumer of repository operations in the
/// server holds one of these; raw repositories are not visible outside
/// the RBA module.
///
/// `ISyncService` is intentionally not part of this bundle yet — it is
/// added when server-side stream multiplexing (Phase 5) introduces the
/// `SubscriptionManager` that owns the upstream subscriptions.
class RbaRepositoryBundle {
  final IUserRepository user;
  final ICharacterRepository character;
  final IGameGroupRepository gameGroup;
  final IInvitationRepository invitation;
  final IStoryNodeRepository storyNode;
  final IStoryNodeInstanceRepository storyNodeInstance;
  final ISessionRepository session;
  final IUserTaskRepository userTask;

  const RbaRepositoryBundle({
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

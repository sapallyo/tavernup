import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavernup_domain/tavernup_domain.dart';
import 'package:tavernup_repositories_remote/tavernup_repositories_remote.dart';

/// The WebSocket transport bound to `tavernup_server`. Overridden once
/// in `main.dart` from the configured URL — never instantiated by
/// downstream provider code.
final realtimeTransportProvider = Provider<IRealtimeTransport>(
  (ref) => throw UnimplementedError(
    'realtimeTransportProvider not overridden — see main.dart',
  ),
);

/// Convenience provider for the eight remote repository implementations,
/// all sharing the connection from [realtimeTransportProvider].
///
/// Connect lifecycle (connect, auth-frame, reconnect on token expiry)
/// is handled by the eventual session wiring around the LoginScreen;
/// the providers below assume the transport is connected and
/// authenticated when reads happen. Calling them before then surfaces
/// the transport's `Transport is not connected` error.
final remoteRepositoryBundleProvider = Provider<RemoteRepositoryBundle>(
  (ref) => createRemoteRepositoryBundle(ref.watch(realtimeTransportProvider)),
);

final userRepositoryProvider = Provider<IUserRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).user,
);

final characterRepositoryProvider = Provider<ICharacterRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).character,
);

final gameGroupRepositoryProvider = Provider<IGameGroupRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).gameGroup,
);

final invitationRepositoryProvider = Provider<IInvitationRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).invitation,
);

final storyNodeRepositoryProvider = Provider<IStoryNodeRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).storyNode,
);

final storyNodeInstanceRepositoryProvider = Provider<IStoryNodeInstanceRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).storyNodeInstance,
);

final sessionRepositoryProvider = Provider<ISessionRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).session,
);

final userTaskRepositoryProvider = Provider<IUserTaskRepository>(
  (ref) => ref.watch(remoteRepositoryBundleProvider).userTask,
);

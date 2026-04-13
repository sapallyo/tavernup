// ── Core models ──────────────────────────────────────────────────────────────
export 'src/models/character.dart';
export 'src/models/game_group.dart';
export 'src/models/game_group_membership.dart';
export 'src/models/user.dart';
export 'src/models/invitation.dart';
export 'src/models/campaign.dart';
export 'src/models/adventure.dart';
export 'src/models/adventure_character.dart';

// ── Process ───────────────────────────────────────────────────────────────────
export 'src/process/variable.dart';
export 'src/process/i_process_task.dart';
export 'src/process/tasks/process_task.dart';
export 'src/process/tasks/user_task.dart';
export 'src/process/tasks/worker_task.dart';
export 'src/process/i_process_engine.dart';
export 'src/process/i_worker.dart';

// ── Repositories ──────────────────────────────────────────────────────────────
export 'src/repositories/i_character_repository.dart';
export 'src/repositories/i_game_group_repository.dart';
export 'src/repositories/i_invitation_repository.dart';
export 'src/repositories/i_user_repository.dart';
export 'src/repositories/i_campaign_repository.dart';
export 'src/repositories/i_adventure_repository.dart';

// ── Realtime ──────────────────────────────────────────────────────────────────
export 'src/realtime/realtime_connection_state.dart';
export 'src/realtime/i_realtime_transport.dart';
export 'src/realtime/services/i_process_event_service.dart';
export 'src/realtime/services/i_sync_service.dart';

// ── SR5 system ────────────────────────────────────────────────────────────────
export 'src/systems/sr5/stat_modifier.dart';
export 'src/systems/sr5/attribute.dart';
export 'src/systems/sr5/initiative.dart';
export 'src/systems/sr5/damage_track.dart';
export 'src/systems/sr5/resource_pool.dart';
export 'src/systems/sr5/skill.dart';
export 'src/systems/sr5/character_type.dart';
export 'src/systems/sr5/character_type_data.dart';
export 'src/systems/sr5/sr5_character.dart';

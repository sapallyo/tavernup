-- Enables Supabase Realtime for tables that clients subscribe to.
--
-- The `supabase_realtime` publication is what the Realtime service
-- subscribes to via logical replication. Tables not in the publication
-- produce no row-change events, so `.stream()` subscriptions stay silent
-- after the initial SELECT.
--
-- `REPLICA IDENTITY FULL` ensures that DELETE events carry all column
-- values, which is required for client-side filter predicates (e.g.
-- `.eq('assignee', userId)`) to match DELETEs — without it, only the
-- primary key is included and filter matching on other columns fails.

ALTER TABLE public.users REPLICA IDENTITY FULL;
ALTER TABLE public.user_tasks REPLICA IDENTITY FULL;
ALTER TABLE public.game_groups REPLICA IDENTITY FULL;
ALTER TABLE public.game_group_memberships REPLICA IDENTITY FULL;
ALTER TABLE public.invitations REPLICA IDENTITY FULL;
ALTER TABLE public.characters REPLICA IDENTITY FULL;
ALTER TABLE public.story_nodes REPLICA IDENTITY FULL;
ALTER TABLE public.story_node_instances REPLICA IDENTITY FULL;
ALTER TABLE public.sessions REPLICA IDENTITY FULL;

ALTER PUBLICATION supabase_realtime ADD TABLE
  public.users,
  public.user_tasks,
  public.game_groups,
  public.game_group_memberships,
  public.invitations,
  public.characters,
  public.story_nodes,
  public.story_node_instances,
  public.sessions;

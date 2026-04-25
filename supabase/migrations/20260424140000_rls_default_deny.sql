-- RLS as safety net for the RBA boundary.
--
-- Enables Row Level Security on all 9 domain tables with no permissive
-- policies for ANON or authenticated roles. service_role bypasses RLS
-- by default in Supabase (it has the BYPASSRLS attribute), so an empty
-- policy set is the cleanest expression of "default-deny for everyone
-- except the server".
--
-- This is NOT the RBAC mechanism. RBAC happens in the server's RBA
-- layer (authorizing repository wrappers). This RLS layer exists only
-- to make the structural assumption "only the server talks to
-- Supabase" physically enforceable: any path that does not go through
-- the RBA layer hits a closed door at the database. See
-- architecture.md, "Authorization Layer (RBA)" → "RLS as Safety Net".
--
-- Auth tables (auth.*) are deliberately untouched — login, token
-- refresh, and password reset must keep working with the public
-- ANON_KEY from the client.

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_group_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_node_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasks ENABLE ROW LEVEL SECURITY;

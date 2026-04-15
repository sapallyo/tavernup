drop policy "game_groups_select" on "public"."game_groups";

drop policy "game_groups_update" on "public"."game_groups";


  create policy "game_groups_select"
  on "public"."game_groups"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.game_group_memberships
  WHERE ((game_group_memberships.game_group_id = game_groups.id) AND (game_group_memberships.user_id = auth.uid())))));



  create policy "game_groups_update"
  on "public"."game_groups"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.game_group_memberships
  WHERE ((game_group_memberships.game_group_id = game_groups.id) AND (game_group_memberships.user_id = auth.uid()) AND (game_group_memberships.role = ANY (ARRAY['admin'::text, 'gm'::text]))))));




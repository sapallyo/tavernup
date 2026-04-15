drop policy "memberships_select" on "public"."game_group_memberships";


  create policy "memberships_select"
  on "public"."game_group_memberships"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.game_group_memberships m2
  WHERE ((m2.game_group_id = game_group_memberships.game_group_id) AND (m2.user_id = auth.uid())))));




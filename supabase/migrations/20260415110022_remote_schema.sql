drop extension if exists "pg_net";


  create table "public"."characters" (
    "id" uuid not null default gen_random_uuid(),
    "owner_id" uuid not null,
    "name" text not null,
    "system_key" text not null default 'generic'::text,
    "default_role" text not null default 'npc'::text,
    "custom_data" jsonb not null default '{}'::jsonb,
    "visible_for" text[] not null default '{}'::text[],
    "image_url" text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."characters" enable row level security;


  create table "public"."game_group_memberships" (
    "id" uuid not null default gen_random_uuid(),
    "game_group_id" uuid not null,
    "user_id" uuid not null,
    "role" text not null default 'player'::text,
    "invited_by" uuid,
    "joined_at" timestamp with time zone not null default now()
      );


alter table "public"."game_group_memberships" enable row level security;


  create table "public"."game_groups" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "created_by" uuid not null,
    "ruleset" text not null default 'generic'::text,
    "image_url" text,
    "session_ids" text[] not null default '{}'::text[],
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."game_groups" enable row level security;


  create table "public"."invitations" (
    "id" uuid not null default gen_random_uuid(),
    "game_group_id" uuid not null,
    "role" text not null default 'player'::text,
    "created_by" uuid not null,
    "invited_user_id" uuid not null,
    "status" text not null default 'pending'::text,
    "expires_at" timestamp with time zone not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."invitations" enable row level security;


  create table "public"."sessions" (
    "id" uuid not null default gen_random_uuid(),
    "instance_ids" text[] not null default '{}'::text[],
    "participants" jsonb not null default '[]'::jsonb,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."sessions" enable row level security;


  create table "public"."story_node_instances" (
    "id" uuid not null default gen_random_uuid(),
    "template_id" uuid not null,
    "status" text not null default 'preparation'::text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."story_node_instances" enable row level security;


  create table "public"."story_nodes" (
    "id" uuid not null default gen_random_uuid(),
    "title" text not null,
    "description" text,
    "image_url" text,
    "system_key" text,
    "parent_id" uuid,
    "child_ids" text[] not null default '{}'::text[],
    "character_ids" text[] not null default '{}'::text[],
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."story_nodes" enable row level security;


  create table "public"."user_tasks" (
    "id" text not null,
    "name" text not null,
    "process_instance_id" text not null,
    "assignee" uuid not null,
    "variables" jsonb not null default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."user_tasks" enable row level security;


  create table "public"."users" (
    "id" uuid not null,
    "nickname" text not null,
    "avatar_url" text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX characters_pkey ON public.characters USING btree (id);

CREATE UNIQUE INDEX game_group_memberships_game_group_id_user_id_key ON public.game_group_memberships USING btree (game_group_id, user_id);

CREATE UNIQUE INDEX game_group_memberships_pkey ON public.game_group_memberships USING btree (id);

CREATE UNIQUE INDEX game_groups_pkey ON public.game_groups USING btree (id);

CREATE UNIQUE INDEX invitations_pkey ON public.invitations USING btree (id);

CREATE UNIQUE INDEX sessions_pkey ON public.sessions USING btree (id);

CREATE UNIQUE INDEX story_node_instances_pkey ON public.story_node_instances USING btree (id);

CREATE UNIQUE INDEX story_nodes_pkey ON public.story_nodes USING btree (id);

CREATE UNIQUE INDEX user_tasks_pkey ON public.user_tasks USING btree (id);

CREATE UNIQUE INDEX users_nickname_key ON public.users USING btree (nickname);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

alter table "public"."characters" add constraint "characters_pkey" PRIMARY KEY using index "characters_pkey";

alter table "public"."game_group_memberships" add constraint "game_group_memberships_pkey" PRIMARY KEY using index "game_group_memberships_pkey";

alter table "public"."game_groups" add constraint "game_groups_pkey" PRIMARY KEY using index "game_groups_pkey";

alter table "public"."invitations" add constraint "invitations_pkey" PRIMARY KEY using index "invitations_pkey";

alter table "public"."sessions" add constraint "sessions_pkey" PRIMARY KEY using index "sessions_pkey";

alter table "public"."story_node_instances" add constraint "story_node_instances_pkey" PRIMARY KEY using index "story_node_instances_pkey";

alter table "public"."story_nodes" add constraint "story_nodes_pkey" PRIMARY KEY using index "story_nodes_pkey";

alter table "public"."user_tasks" add constraint "user_tasks_pkey" PRIMARY KEY using index "user_tasks_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."characters" add constraint "characters_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."characters" validate constraint "characters_owner_id_fkey";

alter table "public"."game_group_memberships" add constraint "game_group_memberships_game_group_id_fkey" FOREIGN KEY (game_group_id) REFERENCES public.game_groups(id) ON DELETE CASCADE not valid;

alter table "public"."game_group_memberships" validate constraint "game_group_memberships_game_group_id_fkey";

alter table "public"."game_group_memberships" add constraint "game_group_memberships_game_group_id_user_id_key" UNIQUE using index "game_group_memberships_game_group_id_user_id_key";

alter table "public"."game_group_memberships" add constraint "game_group_memberships_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES public.users(id) not valid;

alter table "public"."game_group_memberships" validate constraint "game_group_memberships_invited_by_fkey";

alter table "public"."game_group_memberships" add constraint "game_group_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."game_group_memberships" validate constraint "game_group_memberships_user_id_fkey";

alter table "public"."game_groups" add constraint "game_groups_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.users(id) not valid;

alter table "public"."game_groups" validate constraint "game_groups_created_by_fkey";

alter table "public"."invitations" add constraint "invitations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.users(id) not valid;

alter table "public"."invitations" validate constraint "invitations_created_by_fkey";

alter table "public"."invitations" add constraint "invitations_game_group_id_fkey" FOREIGN KEY (game_group_id) REFERENCES public.game_groups(id) ON DELETE CASCADE not valid;

alter table "public"."invitations" validate constraint "invitations_game_group_id_fkey";

alter table "public"."invitations" add constraint "invitations_invited_user_id_fkey" FOREIGN KEY (invited_user_id) REFERENCES public.users(id) not valid;

alter table "public"."invitations" validate constraint "invitations_invited_user_id_fkey";

alter table "public"."sessions" add constraint "sessions_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.users(id) not valid;

alter table "public"."sessions" validate constraint "sessions_created_by_fkey";

alter table "public"."story_node_instances" add constraint "story_node_instances_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.users(id) not valid;

alter table "public"."story_node_instances" validate constraint "story_node_instances_created_by_fkey";

alter table "public"."story_node_instances" add constraint "story_node_instances_template_id_fkey" FOREIGN KEY (template_id) REFERENCES public.story_nodes(id) not valid;

alter table "public"."story_node_instances" validate constraint "story_node_instances_template_id_fkey";

alter table "public"."story_nodes" add constraint "story_nodes_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.users(id) not valid;

alter table "public"."story_nodes" validate constraint "story_nodes_created_by_fkey";

alter table "public"."story_nodes" add constraint "story_nodes_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES public.story_nodes(id) ON DELETE SET NULL not valid;

alter table "public"."story_nodes" validate constraint "story_nodes_parent_id_fkey";

alter table "public"."user_tasks" add constraint "user_tasks_assignee_fkey" FOREIGN KEY (assignee) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_tasks" validate constraint "user_tasks_assignee_fkey";

alter table "public"."users" add constraint "users_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_id_fkey";

alter table "public"."users" add constraint "users_nickname_key" UNIQUE using index "users_nickname_key";

grant delete on table "public"."characters" to "anon";

grant insert on table "public"."characters" to "anon";

grant references on table "public"."characters" to "anon";

grant select on table "public"."characters" to "anon";

grant trigger on table "public"."characters" to "anon";

grant truncate on table "public"."characters" to "anon";

grant update on table "public"."characters" to "anon";

grant delete on table "public"."characters" to "authenticated";

grant insert on table "public"."characters" to "authenticated";

grant references on table "public"."characters" to "authenticated";

grant select on table "public"."characters" to "authenticated";

grant trigger on table "public"."characters" to "authenticated";

grant truncate on table "public"."characters" to "authenticated";

grant update on table "public"."characters" to "authenticated";

grant delete on table "public"."characters" to "service_role";

grant insert on table "public"."characters" to "service_role";

grant references on table "public"."characters" to "service_role";

grant select on table "public"."characters" to "service_role";

grant trigger on table "public"."characters" to "service_role";

grant truncate on table "public"."characters" to "service_role";

grant update on table "public"."characters" to "service_role";

grant delete on table "public"."game_group_memberships" to "anon";

grant insert on table "public"."game_group_memberships" to "anon";

grant references on table "public"."game_group_memberships" to "anon";

grant select on table "public"."game_group_memberships" to "anon";

grant trigger on table "public"."game_group_memberships" to "anon";

grant truncate on table "public"."game_group_memberships" to "anon";

grant update on table "public"."game_group_memberships" to "anon";

grant delete on table "public"."game_group_memberships" to "authenticated";

grant insert on table "public"."game_group_memberships" to "authenticated";

grant references on table "public"."game_group_memberships" to "authenticated";

grant select on table "public"."game_group_memberships" to "authenticated";

grant trigger on table "public"."game_group_memberships" to "authenticated";

grant truncate on table "public"."game_group_memberships" to "authenticated";

grant update on table "public"."game_group_memberships" to "authenticated";

grant delete on table "public"."game_group_memberships" to "service_role";

grant insert on table "public"."game_group_memberships" to "service_role";

grant references on table "public"."game_group_memberships" to "service_role";

grant select on table "public"."game_group_memberships" to "service_role";

grant trigger on table "public"."game_group_memberships" to "service_role";

grant truncate on table "public"."game_group_memberships" to "service_role";

grant update on table "public"."game_group_memberships" to "service_role";

grant delete on table "public"."game_groups" to "anon";

grant insert on table "public"."game_groups" to "anon";

grant references on table "public"."game_groups" to "anon";

grant select on table "public"."game_groups" to "anon";

grant trigger on table "public"."game_groups" to "anon";

grant truncate on table "public"."game_groups" to "anon";

grant update on table "public"."game_groups" to "anon";

grant delete on table "public"."game_groups" to "authenticated";

grant insert on table "public"."game_groups" to "authenticated";

grant references on table "public"."game_groups" to "authenticated";

grant select on table "public"."game_groups" to "authenticated";

grant trigger on table "public"."game_groups" to "authenticated";

grant truncate on table "public"."game_groups" to "authenticated";

grant update on table "public"."game_groups" to "authenticated";

grant delete on table "public"."game_groups" to "service_role";

grant insert on table "public"."game_groups" to "service_role";

grant references on table "public"."game_groups" to "service_role";

grant select on table "public"."game_groups" to "service_role";

grant trigger on table "public"."game_groups" to "service_role";

grant truncate on table "public"."game_groups" to "service_role";

grant update on table "public"."game_groups" to "service_role";

grant delete on table "public"."invitations" to "anon";

grant insert on table "public"."invitations" to "anon";

grant references on table "public"."invitations" to "anon";

grant select on table "public"."invitations" to "anon";

grant trigger on table "public"."invitations" to "anon";

grant truncate on table "public"."invitations" to "anon";

grant update on table "public"."invitations" to "anon";

grant delete on table "public"."invitations" to "authenticated";

grant insert on table "public"."invitations" to "authenticated";

grant references on table "public"."invitations" to "authenticated";

grant select on table "public"."invitations" to "authenticated";

grant trigger on table "public"."invitations" to "authenticated";

grant truncate on table "public"."invitations" to "authenticated";

grant update on table "public"."invitations" to "authenticated";

grant delete on table "public"."invitations" to "service_role";

grant insert on table "public"."invitations" to "service_role";

grant references on table "public"."invitations" to "service_role";

grant select on table "public"."invitations" to "service_role";

grant trigger on table "public"."invitations" to "service_role";

grant truncate on table "public"."invitations" to "service_role";

grant update on table "public"."invitations" to "service_role";

grant delete on table "public"."sessions" to "anon";

grant insert on table "public"."sessions" to "anon";

grant references on table "public"."sessions" to "anon";

grant select on table "public"."sessions" to "anon";

grant trigger on table "public"."sessions" to "anon";

grant truncate on table "public"."sessions" to "anon";

grant update on table "public"."sessions" to "anon";

grant delete on table "public"."sessions" to "authenticated";

grant insert on table "public"."sessions" to "authenticated";

grant references on table "public"."sessions" to "authenticated";

grant select on table "public"."sessions" to "authenticated";

grant trigger on table "public"."sessions" to "authenticated";

grant truncate on table "public"."sessions" to "authenticated";

grant update on table "public"."sessions" to "authenticated";

grant delete on table "public"."sessions" to "service_role";

grant insert on table "public"."sessions" to "service_role";

grant references on table "public"."sessions" to "service_role";

grant select on table "public"."sessions" to "service_role";

grant trigger on table "public"."sessions" to "service_role";

grant truncate on table "public"."sessions" to "service_role";

grant update on table "public"."sessions" to "service_role";

grant delete on table "public"."story_node_instances" to "anon";

grant insert on table "public"."story_node_instances" to "anon";

grant references on table "public"."story_node_instances" to "anon";

grant select on table "public"."story_node_instances" to "anon";

grant trigger on table "public"."story_node_instances" to "anon";

grant truncate on table "public"."story_node_instances" to "anon";

grant update on table "public"."story_node_instances" to "anon";

grant delete on table "public"."story_node_instances" to "authenticated";

grant insert on table "public"."story_node_instances" to "authenticated";

grant references on table "public"."story_node_instances" to "authenticated";

grant select on table "public"."story_node_instances" to "authenticated";

grant trigger on table "public"."story_node_instances" to "authenticated";

grant truncate on table "public"."story_node_instances" to "authenticated";

grant update on table "public"."story_node_instances" to "authenticated";

grant delete on table "public"."story_node_instances" to "service_role";

grant insert on table "public"."story_node_instances" to "service_role";

grant references on table "public"."story_node_instances" to "service_role";

grant select on table "public"."story_node_instances" to "service_role";

grant trigger on table "public"."story_node_instances" to "service_role";

grant truncate on table "public"."story_node_instances" to "service_role";

grant update on table "public"."story_node_instances" to "service_role";

grant delete on table "public"."story_nodes" to "anon";

grant insert on table "public"."story_nodes" to "anon";

grant references on table "public"."story_nodes" to "anon";

grant select on table "public"."story_nodes" to "anon";

grant trigger on table "public"."story_nodes" to "anon";

grant truncate on table "public"."story_nodes" to "anon";

grant update on table "public"."story_nodes" to "anon";

grant delete on table "public"."story_nodes" to "authenticated";

grant insert on table "public"."story_nodes" to "authenticated";

grant references on table "public"."story_nodes" to "authenticated";

grant select on table "public"."story_nodes" to "authenticated";

grant trigger on table "public"."story_nodes" to "authenticated";

grant truncate on table "public"."story_nodes" to "authenticated";

grant update on table "public"."story_nodes" to "authenticated";

grant delete on table "public"."story_nodes" to "service_role";

grant insert on table "public"."story_nodes" to "service_role";

grant references on table "public"."story_nodes" to "service_role";

grant select on table "public"."story_nodes" to "service_role";

grant trigger on table "public"."story_nodes" to "service_role";

grant truncate on table "public"."story_nodes" to "service_role";

grant update on table "public"."story_nodes" to "service_role";

grant delete on table "public"."user_tasks" to "anon";

grant insert on table "public"."user_tasks" to "anon";

grant references on table "public"."user_tasks" to "anon";

grant select on table "public"."user_tasks" to "anon";

grant trigger on table "public"."user_tasks" to "anon";

grant truncate on table "public"."user_tasks" to "anon";

grant update on table "public"."user_tasks" to "anon";

grant delete on table "public"."user_tasks" to "authenticated";

grant insert on table "public"."user_tasks" to "authenticated";

grant references on table "public"."user_tasks" to "authenticated";

grant select on table "public"."user_tasks" to "authenticated";

grant trigger on table "public"."user_tasks" to "authenticated";

grant truncate on table "public"."user_tasks" to "authenticated";

grant update on table "public"."user_tasks" to "authenticated";

grant delete on table "public"."user_tasks" to "service_role";

grant insert on table "public"."user_tasks" to "service_role";

grant references on table "public"."user_tasks" to "service_role";

grant select on table "public"."user_tasks" to "service_role";

grant trigger on table "public"."user_tasks" to "service_role";

grant truncate on table "public"."user_tasks" to "service_role";

grant update on table "public"."user_tasks" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";


  create policy "characters_insert"
  on "public"."characters"
  as permissive
  for insert
  to public
with check ((auth.uid() = owner_id));



  create policy "characters_select"
  on "public"."characters"
  as permissive
  for select
  to public
using (((owner_id = auth.uid()) OR ((auth.uid())::text = ANY (visible_for))));



  create policy "characters_update"
  on "public"."characters"
  as permissive
  for update
  to public
using ((auth.uid() = owner_id));



  create policy "memberships_select"
  on "public"."game_group_memberships"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.game_group_memberships m2
  WHERE ((m2.game_group_id = m2.game_group_id) AND (m2.user_id = auth.uid())))));



  create policy "game_groups_insert"
  on "public"."game_groups"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "game_groups_select"
  on "public"."game_groups"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.game_group_memberships
  WHERE ((game_group_memberships.game_group_id = game_group_memberships.id) AND (game_group_memberships.user_id = auth.uid())))));



  create policy "game_groups_update"
  on "public"."game_groups"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.game_group_memberships
  WHERE ((game_group_memberships.game_group_id = game_group_memberships.id) AND (game_group_memberships.user_id = auth.uid()) AND (game_group_memberships.role = ANY (ARRAY['admin'::text, 'gm'::text]))))));



  create policy "invitations_select"
  on "public"."invitations"
  as permissive
  for select
  to public
using (((invited_user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.game_group_memberships
  WHERE ((game_group_memberships.game_group_id = invitations.game_group_id) AND (game_group_memberships.user_id = auth.uid()) AND (game_group_memberships.role = ANY (ARRAY['admin'::text, 'gm'::text])))))));



  create policy "sessions_insert"
  on "public"."sessions"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "sessions_select"
  on "public"."sessions"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "story_node_instances_insert"
  on "public"."story_node_instances"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "story_node_instances_select"
  on "public"."story_node_instances"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "story_nodes_insert"
  on "public"."story_nodes"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "story_nodes_select"
  on "public"."story_nodes"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "user_tasks_select"
  on "public"."user_tasks"
  as permissive
  for select
  to public
using ((assignee = auth.uid()));



  create policy "users_insert"
  on "public"."users"
  as permissive
  for insert
  to public
with check ((auth.uid() = id));



  create policy "users_select"
  on "public"."users"
  as permissive
  for select
  to public
using (true);



  create policy "users_update"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = id));




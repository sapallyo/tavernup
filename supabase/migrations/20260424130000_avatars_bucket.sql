-- Creates a private storage bucket for user avatars and the minimal RLS
-- policies that allow direct client uploads + reads via signed URLs.
--
-- Path convention: {userId}/avatar
--   - storage.foldername(name)[1] is the userId, used to scope writes
--   - Subsequent uploads for the same user overwrite the previous avatar
--   - Single file per user — no orphan cleanup needed
--
-- The SELECT policy currently grants every authenticated user the right
-- to read any avatar. This is broader than what the final RBAC concept
-- will allow (e.g. "only members of the same game group"). It is the
-- minimum that makes the feature work today; tighten it as part of the
-- RBAC backlog item before the client goes live.

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Authenticated users can upload an avatar in their own folder.
CREATE POLICY "Users upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Same constraint for overwrites.
CREATE POLICY "Users update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Same constraint for deletions.
CREATE POLICY "Users delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Any authenticated user can read any avatar.
-- TODO(rbac): restrict to relationship-based visibility (e.g. shared
-- game group, shared organisation in TeamUp).
CREATE POLICY "Authenticated users read avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'avatars');

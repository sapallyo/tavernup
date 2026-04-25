/// Public API of `tavernup_repositories_supabase`.
///
/// Intentionally minimal: only the raw-bundle factory is exported.
/// The concrete `Supabase*Repository` classes and `SupabaseSyncService`
/// remain in `lib/src/` and are not part of the public surface.
///
/// Consumers outside this package may only obtain a [RawRepositoryBundle]
/// via [createRawRepositoryBundle], and only the server's RBA factory
/// is permitted to call it (enforced by `custom_lint` + CODEOWNERS).
/// Every other code path receives RBA-wrapped repositories from the
/// server's `RbaFactory`, never raw ones.
export 'src/raw_repository_bundle.dart';

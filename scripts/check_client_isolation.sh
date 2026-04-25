#!/usr/bin/env bash
#
# Verifies the structural constraint set up in the RBA migration: the
# Flutter client must not have a data-side path to Supabase. Anything
# the client can see of `tavernup_repositories_supabase` would re-open
# the back door RLS closes at the database — see architecture.md
# "Authorization Layer (RBA)" → "Structural Enforcement".
#
# Exits non-zero on the first violation; intended for CI.

set -euo pipefail

cd "$(dirname "$0")/.."

PUBSPEC=packages/tavernup_client/pubspec.yaml
LOCK=packages/tavernup_client/pubspec.lock

violations=0

# Rule 1: pubspec.yaml must not declare tavernup_repositories_supabase.
if grep -q '^\s*tavernup_repositories_supabase:' "$PUBSPEC"; then
  echo "FAIL: $PUBSPEC declares tavernup_repositories_supabase" >&2
  violations=$((violations + 1))
fi

# Rule 2: pubspec.yaml must not declare the bare `supabase` data SDK.
# (The Flutter client uses supabase_flutter for *auth only*, transitively
# through tavernup_auth_supabase.)
if grep -qE '^\s*supabase:\s' "$PUBSPEC"; then
  echo "FAIL: $PUBSPEC declares the supabase data SDK directly" >&2
  violations=$((violations + 1))
fi

# Rule 3: if the lockfile exists, neither package may appear there
# either — covers transitive sneaks via dev_dependencies and similar.
if [ -f "$LOCK" ]; then
  if grep -q '^\s*tavernup_repositories_supabase:' "$LOCK"; then
    echo "FAIL: $LOCK resolves tavernup_repositories_supabase" >&2
    violations=$((violations + 1))
  fi
fi

if [ "$violations" -eq 0 ]; then
  echo "OK: tavernup_client cannot resolve a Supabase data path."
  exit 0
fi

echo "" >&2
echo "$violations violation(s) of the client/data isolation rule." >&2
exit 1

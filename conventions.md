# TavernUp – Conventions

## Language

| Context | Language |
|---|---|
| Code (variables, functions, classes, files) | English |
| Code comments | English |
| GUI strings (labels, buttons, messages) | German |
| Documentation (MD files, this file) | English |
| Claude responses | German |

---

## Dart / Flutter

- Flutter 3.41.6 / Dart 3.11.4 (pinned via `fvm`, siehe `.fvmrc`)
- State management: **Riverpod**
- Routing: **go_router**
- No unnecessary comments on self-explanatory code
- Follow standard Dart style (`dart format`, `dart analyze` clean)
- Repository implementations always depend on interfaces, never on concrete types

---

## Architecture Patterns

- **Program against interfaces** — never against concrete implementations
- **Replaceability first** — every infrastructure dependency (Supabase, Camunda) sits behind an interface
- **Registry pattern** — `EntityRepositoryRegistry` for repository lookup
- **requestId pattern** — WebSocket request/response correlation for synchronous calls
- Mock repositories mirror the interface exactly; no logic beyond what tests require

---

## Diagram Conventions (SVG / HTML artifacts)

| Element | Style |
|---|---|
| Standalone entities | Colored boxes, class `c-purple` |
| Junction / relation classes | Small gray pills, class `c-gray`, `rx=9` |
| Ownership / 1:n arrows | Green, `stroke="#1D9E75"` |
| Reference / knows relations | Gray dashed line |
| Line routing | L-shaped paths — no diagonal lines, no box overlaps |

Color classes available: `c-purple`, `c-teal`, `c-amber`, `c-blue`, `c-gray`

Reference file: `tavernup_architecture_v14.html` (in project files)

---

## File & Folder Structure

```
tavernup/
└── packages/
    ├── tavernup_domain/
    │   ├── lib/
    │   │   ├── src/
    │   │   │   ├── mock/
    │   │   │   ├── models/
    │   │   │   ├── process/
    │   │   │   ├── realtime/
    │   │   │   ├── repositories/
    │   │   │   ├── systems/
    │   │   │   └── auth/          # IAuthService
    │   │   └── tavernup_domain.dart
    │   └── test/
    ├── tavernup_auth_supabase/
    │   ├── lib/
    │   │   ├── src/
    │   │   │   └── supabase_auth_service.dart
    │   │   └── tavernup_auth_supabase.dart
    │   └── pubspec.yaml
    ├── tavernup_repositories_supabase/
    │   ├── lib/
    │   │   ├── src/
    │   │   └── tavernup_repositories_supabase.dart
    │   └── test/
    ├── tavernup_server/
    │   ├── bin/
    │   │   └── server.dart
    │   ├── lib/
    │   │   └── src/
    │   │       ├── webhook/
    │   │       ├── websocket/
    │   │       └── workers/
    │   └── test/
    └── tavernup_client/
        ├── lib/
        │   ├── src/
        │   │   ├── infrastructure/  # WebSocketRealtimeTransport
        │   │   ├── services/        # ProcessEventService, SyncService
        │   │   ├── state/           # Riverpod providers
        │   │   └── ui/
        │   │       ├── screens/
        │   │       └── widgets/
        │   └── main.dart            # DI-Setup, nur hier konkrete Typen
        └── test/
```
---

## Server

- Port: `8080`
- Credentials via environment variables only (never hardcoded)
- Start: `export $(cat .env | xargs) && dart run bin/server.dart`
- Required env vars: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

---

## Testing

- All domain tests must stay green before any commit
- Mock repositories used exclusively in unit tests
- Integration tests for Supabase repositories: pending (see open_tasks.md)

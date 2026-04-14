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

- Dart 3.6.2, Flutter 3.27.4 (pinned)
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
├── tavernup_domain/         # Domain models, interfaces, mocks
│   └── lib/
│       ├── models/          # Core domain models
│       ├── sr5/             # SR5 system models
│       ├── repositories/    # Repository interfaces
│       └── process/         # IUserTaskRepository, realtime interfaces
├── tavernup_server/         # WebSocket server, EntityWorker, handlers
│   └── bin/
│       └── server.dart      # Entry point
├── tavernup_repositories_supabase/  # Supabase implementations
└── tavernup_client/         # Flutter app (empty)
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

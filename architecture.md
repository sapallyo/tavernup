# TavernUp – Architecture

## Repository

Mono-repo. Packages liegen unter `packages/`.

| Package | Language | Status |
|---|---|---|
| `tavernup_domain` | Dart | ✅ Complete, all tests green |
| `tavernup_auth_supabase` | Dart | 🔲 Neu anlegen |
| `tavernup_repositories_supabase` | Dart | ✅ All 8 implementations done |
| `tavernup_server` | Dart | ✅ Complete, all tests green |
| `tavernup_client` | Flutter 3.41.6 / Dart 3.11.4 | 🔲 In Arbeit |

Flutter-Version per `fvm` im Repo gepinnt (siehe `.fvmrc`). Primäre Entwicklungsumgebung: Linux VM (Ubuntu 24.04 arm64).

---

## Infrastructure

### Supabase
- Project: `tavernup`, EU Frankfurt
- ID: `xrmwdfuqeaoredwnerau`
- RLS + Policies active on all tables
- Realtime active on `user_tasks`
- Server uses `service_role` key (bypasses RLS)
- Start env: `export $(cat .env | xargs) && dart run bin/server.dart`
- Env vars: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

### Supabase Schema
| Table | Notes |
|---|---|
| `users` | |
| `game_groups` | |
| `game_group_memberships` | |
| `invitations` | |
| `characters` | |
| `story_nodes` | |
| `story_node_instances` | |
| `sessions` | `participants` = jsonb array of AdventureCharacter (no own repo) |
| `user_tasks` | `id` is `text` (Camunda task IDs); Realtime active |

> ⚠️ Known constraint: Camunda `ACT_` tables landed in `public` schema — Supabase pooler prevents schema-level isolation. Revisit when moving to dedicated DB for TeamUp.

### Camunda
- Version: 7.21.0 via Docker Compose on Rancher Desktop
- Custom Docker image required (Java TaskListener, see Open Tasks)

---

## Architecture Layers

```
tavernup_client (Flutter)
│  WebSocket (requestId pattern) — Process-Events + fachliche Aktionen
│  Supabase direkt — Reads + einfache Preference-Writes
tavernup_server (Dart)
│  fetchAndLock (External Tasks)
│  Webhook receiver (/webhook/task-created)
│  UserTask push → WebSocket → Client
Camunda 7
│  PostgreSQL tables (ACT_*)
Supabase (PostgreSQL + Realtime)
```

### Client–Server Responsibility Split

**Client** is responsible for UI rendering, navigation, local UI state,
and basic UX validation (e.g. required fields).

**Server** is responsible for all business logic, authorization checks,
and orchestration via Camunda. Multiple client platforms (web, tablet,
mobile) share the same server-side logic — no duplication across clients.

### Data Access Principles

- **Reads** — always direct via `tavernup_repositories_supabase` interfaces.
  No server roundtrip for read operations.
- **Preference writes** — direct via repository (nickname, avatar, UI settings).
  No business logic involved, no server needed.
- **Business writes** — via WebSocket to server, decided case-by-case.
  Applies when validation, authorization, or process triggers are involved
  (e.g. creating a group, assigning a character to a session).
- **Process events** — always via WebSocket (UserTask push, complete-task).

This is a deliberate pragmatic split, not a strict rule. The decision is
made per feature. The interface boundaries ensure the split can evolve
without rearchitecting.

### Shared Repository Layer

`tavernup_repositories_supabase` is used by both server and client —
it is the single implementation of all domain repository interfaces.
Neither server nor client has its own data access code.
Replacing Supabase (e.g. for TeamUp's German hosting requirements)
means replacing one package, not touching server and client separately.

### Communication Flow
- Client ↔ Server via **WebSocket** (requestId pattern for synchronous calls)
- Camunda **TaskListener** (create-event) fires HTTP POST to
  `/webhook/task-created` for both UserTasks and ExternalTasks
- UserTasks → stored in `user_tasks` (Supabase), then pushed via
  WebSocket to the assigned client
- ExternalTasks → triggers `fetchAndLock` in `EntityWorker`
- Safety-net poll ~60s as fallback (no primary poll timer)
- On WebSocket connect: server delivers all pending UserTasks for
  the authenticated user

### Realtime Abstraction
- Layer 1: `IRealtimeTransport` — WebSocket transport to tavernup_server
- Layer 2: `IProcessEventService` — UserTask push + completion via WebSocket
- Layer 3: `ISyncService` — domain data streams via Supabase directly
- Supabase is encapsulated in `tavernup_repositories_supabase` →
  swappable for TeamUp without touching client or server code
  
---

## Domain Models (`tavernup_domain`)

### Core Entities
| Model | Key Fields |
|---|---|
| `User` | |
| `GameGroup` | `sessionIds` |
| `GameGroupMembership` | junction: User ↔ GameGroup |
| `Invitation` | |
| `Character` | `systemKey`, `customData` |
| `StoryNode` | recursive: `parentId`, `childIds`, `characterIds` |
| `StoryNodeInstance` | |
| `Session` | `instanceIds`, `participants` |
| `AdventureCharacter` | `userId` + `characterId` pair (jsonb in sessions) |

### SR5 System Models
`Sr5Character`, `Attribute`, `Initiative`, `DamageTrack`, `ResourcePool`, `StatModifier`, `Skill`, `Sr5CharacterType`, `Sr5CharacterTypeData`

---

## Repository Interfaces (`tavernup_domain`)

Base: `IEntityRepository` → `entityType`, `create(Map)`, `update(id, Map)`, `delete(id)`

| Interface | entityType |
|---|---|
| `IUserRepository` | — |
| `ICharacterRepository` | — |
| `IGameGroupRepository` | `membership` |
| `IInvitationRepository` | `invitation` |
| `IStoryNodeRepository` | — |
| `IStoryNodeInstanceRepository` | — |
| `ISessionRepository` | — |
| `IUserTaskRepository` | — |

Registry: `EntityRepositoryRegistry` in `tavernup_domain`

Realtime interfaces: `IRealtimeTransport`, `IProcessEventService`, `ISyncService`

Mock repositories: all present, including `MockUserTaskRepository`

---

## tavernup_server

| Component | Status | Notes |
|---|---|---|
| `EntityWorker` | ✅ | Processes Camunda External Tasks via fetchAndLock |
| `WebSocketServer` | ✅ | Port 8080 |
| `MessageHandler` | ✅ | `validate-user`, `complete-task` via requestId pattern |
| `WebhookHandler` | ✅ | Receives Camunda webhook, routes userTask / externalTask |

---

## BPMN: Invitation Process

```
Start({groupId, invitedBy})
  → UserTask: choose-user          (output: nickname)
  → WorkerTask: entity-operation   (validate → create-invitation)
  → UserTask: accept-invitation    (output: accepted)
  → Gateway
  → WorkerTask: entity-operation   (create-membership)
  → End
```

> `validate-user` is a WebSocket endpoint on the server, not a BPMN step.

---

## Replaceability Principle

All backend services and infrastructure are abstracted behind interfaces. This enables swapping Supabase for ISO 27001-compliant German hosting (TeamUp) without rearchitecting.

---

## TeamUp Context

TavernUp is the POC for **TeamUp** — an orchestration platform for school assistance coordination in the German social sector.

TeamUp requirements: ISO 27001 German hosting, BSI TR-03161, §203 StGB, no US SaaS, offline capability, RBAC. Stack: similar (Camunda/Flowable, BPMN).

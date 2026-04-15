# TavernUp – Architecture

## Repository

Mono-repo: `/Users/juergendissinger/PrivateProjects/tavernup`

Packages liegen unter `packages/`.

| Package | Language | Status |
|---|---|---|
| `tavernup_domain` | Dart | ✅ Complete, all tests green |
| `tavernup_auth_supabase` | Dart | 🔲 Neu anlegen |
| `tavernup_repositories_supabase` | Dart | ✅ All 8 implementations done |
| `tavernup_server` | Dart | ✅ Complete, all tests green |
| `tavernup_client` | Flutter 3.27.4 / Dart 3.6.2 | 🔲 In Arbeit |

Flutter SDK: `/Users/juergendissinger/flutter` (pinned — macOS Ventura 13.7.8 incompatibility with newer versions)

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
       │  WebSocket (requestId pattern)
tavernup_server (Dart)
       │  fetchAndLock (External Tasks)
       │  Webhook receiver (/webhook/task-created)
    Camunda 7
       │  PostgreSQL tables (ACT_*)
    Supabase (PostgreSQL + Realtime)
```

### Communication Flow
- Client ↔ Server via **WebSocket** (requestId pattern for synchronous calls)
- Camunda **TaskListener** (create-event) fires HTTP POST to `/webhook/task-created` for both UserTasks and ExternalTasks
- UserTasks → stored in `pending_user_tasks`, forwarded to client via Realtime
- ExternalTasks → triggers `fetchAndLock` in `EntityWorker`
- Safety-net poll ~60s as fallback (no primary poll timer)

### Realtime Abstraction
- Layer 1: `IRealtimeTransport` — transport abstraction (WebSocket / Supabase Realtime)
- Layer 2: `IProcessEventService` / `ISyncService` — semantic services
- Supabase Realtime is fully hidden behind `IRealtimeTransport` → swappable for TeamUp

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

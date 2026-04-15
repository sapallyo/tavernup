# TavernUp – Open Tasks

## Priority Order

1. ~~**Camunda Docker Image**~~ ✅ Done
2. **Flutter Client** (Final layer)
3. ~~**Integration Tests** (Supabase repositories)~~ ✅ Done

---

## 1. Camunda Docker Image with Java TaskListener

**Status**: ✅ Done

### Goal
Custom Camunda 7.21.0 Docker image that fires an HTTP POST to the TavernUp server whenever a task is created — for both UserTasks and ExternalTasks.

### Behavior
- Event: `create` on any task (UserTask + ExternalTask)
- Target: `POST /webhook/task-created` on `tavernup_server` (port 8080)
- Payload must include: `taskId`, `taskType` (`userTask` | `externalTask`), `processInstanceId`, `taskDefinitionKey`

### Server side (already implemented)
- `WebhookHandler` receives and routes the webhook
- UserTasks → stored in `user_tasks` table (Supabase), forwarded via Realtime
- ExternalTasks → triggers `fetchAndLock` in `EntityWorker`

---

## 2. Flutter Client

**Status**: 🔲 Scaffolded, empty  
**Depends on**: ~~Task 1 (Camunda webhook)~~ ✅ resolved

### Goal
Flutter client implementing the user-facing side of TavernUp process flows.

### Key interfaces to implement (from `tavernup_domain`)
- `IRealtimeTransport` — WebSocket connection to `tavernup_server`
- `IProcessEventService` — semantic process events (task pending, task completed)
- `ISyncService` — state sync across devices

### First screens to build (suggested order)
1. Login / Auth (Supabase Auth)
2. Game Group overview
3. Invitation flow (first complete BPMN process end-to-end)
4. Session / Character views

### State management
- Riverpod throughout
- Routing: go_router

---

## 3. Integration Tests – Supabase Repositories

**Status**: ✅ Done  
**Package**: `tavernup_repositories_supabase`

### Notes
- Tests run against local Supabase instance (Docker)
- Service-role key used throughout — RLS bypassed
- RLS policies currently disabled — see RBAC backlog item
- `user_tasks.id` is `text` — Camunda task ID roundtrip verified
- `dart_test.yaml` sets `concurrency: 1` — required for DB isolation

---

## Backlog / Known Issues

| Item | Notes |
|---|---|
| Camunda `ACT_` tables in `public` schema | Supabase pooler prevents dedicated `camunda` schema. Accepted for now, revisit for TeamUp with dedicated DB. |
| Notifications after invitation accept/reject | Inviting user currently receives no notification. Needs process extension or separate Realtime subscription. |
| RBAC / Access Control | All RLS policies removed temporarily. Dedicated RBAC concept required — role-based, covering both TavernUp and TeamUp (incl. §203 StGB implications). To be designed before Flutter client goes live. |

---

## Backlog / Future Ideas

### SR5 Combat Simulator

Two distinct components with different characteristics:

**Runtime Component** — supports real play sessions: tracks state of all participants across an entire combat, calculates dice pool composition and difficulty for player actions, applies results automatically, optionally auto-rolls for NPCs.

**Statistics Component** — fully automated simulation mode for playtesting house rules: runs a defined combat scenario N times across various configurations, aggregates results to assess rule balancing.

### Architecture Notes
- The statistics component has no human actors, no wait states, no persistent inter-step state — a process engine (Camunda/BPMN) makes no sense here. Pure computation.
- The runtime component involves human decisions and sequential phases — BPMN may be worth exploring as a learning exercise, to understand where it adds value and where it becomes a constraint.
- Both components share the same rule logic. A clean separation into a **C++ microservice** is worth considering:
  - Stateless from the network perspective: receives combat state + action, returns new state + result
  - Communicates with `tavernup_server` via HTTP or WebSocket
  - No FFI/JNI — separate process with a well-defined API boundary
  - Statistics component reuses the exact same rule engine as the runtime component
  - Side benefit: practical experience with cross-language service integration
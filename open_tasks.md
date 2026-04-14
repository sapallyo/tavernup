# TavernUp – Open Tasks

## Priority Order

1. **Camunda Docker Image** (Blocker for end-to-end flow)
2. **Flutter Client** (Final layer)
3. **Integration Tests** (Supabase repositories)

---

## 1. Camunda Docker Image with Java TaskListener

**Status**: 🔲 Not started  
**Blocks**: End-to-end process flow, client development

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

### What needs to be built
- Java `TaskListener` implementing `org.camunda.bpm.engine.delegate.TaskListener`
- Registered for `create` event on all tasks in `processes.xml` or via engine plugin
- HTTP POST using plain Java (no external dependencies preferred)
- Dockerfile extending `camunda/camunda-bpm-platform:7.21.0`
- Updated `docker-compose.yml`

---

## 2. Flutter Client

**Status**: 🔲 Scaffolded, empty  
**Depends on**: Task 1 (Camunda webhook) for meaningful end-to-end testing

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

**Status**: 🔲 Not started  
**Package**: `tavernup_repositories_supabase`

### Goal
Verify all 8 Supabase repository implementations against a real (or test) Supabase instance.

### Repositories to cover
`SupabaseUserRepository`, `SupabaseGameGroupRepository`, `SupabaseInvitationRepository`, `SupabaseCharacterRepository`, `SupabaseSessionRepository`, `SupabaseStoryNodeRepository`, `SupabaseStoryNodeInstanceRepository`, `SupabaseUserTaskRepository`

### Notes
- Tests require live Supabase connection (use `.env` credentials)
- RLS policies must be tested explicitly (service_role vs. user token)
- `user_tasks.id` is `text` — verify Camunda task ID roundtrip

---

## Backlog / Known Issues

| Item | Notes |
|---|---|
| Camunda `ACT_` tables in `public` schema | Supabase pooler prevents dedicated `camunda` schema. Accepted for now, revisit for TeamUp with dedicated DB. |
| Notifications after invitation accept/reject | Inviting user currently receives no notification. Needs process extension or separate Realtime subscription. |

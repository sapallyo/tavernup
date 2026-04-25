# TavernUp – Open Tasks

## Priority Order

1. ~~**Camunda Docker Image**~~ ✅ Done
2. **Authorization Layer (RBA) + Data Flow Migration**
3. **Flutter Client** (Final layer)
4. ~~**Integration Tests** (Supabase repositories)~~ ✅ Done

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

## 2. Authorization Layer (RBA) + Data Flow Migration

**Status**: 🔲 Not started  
**Depends on**: nothing (can start immediately)  
**Blocks**: Flutter client work past current Phase 2 state

### Goal
Implement the target data access architecture described in
`architecture.md` — all client traffic over WebSocket, all data access
through authorizing repository wrappers, no direct client-to-Supabase
path.

### Scope

**Server side**
- [ ] Create RBA layer module in `tavernup_server` —
      authorizing wrapper for each `IXxxRepository`
- [ ] Move `service_role` Supabase client construction into the RBA
      layer factory; remove all other access paths
- [ ] Restrict `tavernup_repositories_supabase` public API to the
      factory; raw repos in `lib/src/` only
- [ ] Add custom lint rule forbidding cross-package `src/` imports
      from outside the RBA layer
- [ ] Add CODEOWNERS for the RBA layer and the raw repos package
- [ ] Extend WebSocket protocol to carry repository requests
      (read, write, stream subscribe/unsubscribe)
- [ ] Route incoming repository requests through the RBA wrappers
- [ ] Server-side stream multiplexing: subscribe to Supabase Realtime
      once per stream, apply per-user filtering, fan out to clients
      over WebSocket

**Client side**
- [ ] Create `tavernup_repositories_remote` package — implements
      `IXxxRepository` interfaces by sending WebSocket requests
- [ ] Migrate `SupabaseSyncService` consumption to the new
      WebSocket-based stream subscription
- [ ] Remove `tavernup_repositories_supabase` and any direct Supabase
      client from client dependencies
- [ ] Verify the client `pubspec.yaml` cannot resolve a Supabase data
      client (only the auth client remains)

### Concrete role/permission catalog
Tracked separately. Architecture only fixes the mechanism. The role
catalog (member rights: Spieler / SL / Admin; per-session roles
gameMaster / player; character ownership; obvious-vs-detailed
projections; NSC handling) is filled in as features are implemented.

---

## 3. Flutter Client

**Status**: 🔲 In Arbeit  
**Depends on**: ~~Task 1 (Camunda webhook)~~ ✅ resolved

### Wiederverwendung aus altem Client (sr5_tool)
- **Direkt**: DomainTile-Hierarchie, TileGrid, UserAvatar, SectionHeader,
  LoginScreen, Riverpod-Setup, go_router + AuthGate
- **Struktur übernehmen, Logik ersetzen**: LobbyScreen, GameGroupDetailScreen,
  CharacterDetailScreen — Layout gut, Provider-Calls auf Interfaces umstellen
- **Neu schreiben**: InviteFlow-Screens, InvitationMarker/InviteDialog
  (war link-basiert, jetzt BPMN UserTask über IUserTaskRepository + WebSocket)
- **Nicht kopieren**: Models + Repositories — bereits in tavernup_domain
  und tavernup_repositories_supabase

### Phasen

**Phase 1 — Fundament** ✅
- [x] `IAuthService` in `tavernup_domain` definieren
- [x] `tavernup_auth_supabase` Package anlegen, `SupabaseAuthService` implementieren
- [x] `architecture.md` aktualisieren (neues Package eintragen)
- [x] `pubspec.yaml` mit allen Dependencies
- [x] `main.dart` + Riverpod-Setup mit Interface-basierter Provider-Injection

**Phase 2 — Transport-Layer** ✅
- [x] `WebSocketRealtimeTransport` implementiert `IRealtimeTransport` (`tavernup_client/infrastructure/`)
- [x] `ProcessEventService` implementiert `IProcessEventService` (`tavernup_client/services/`)
- [x] `SupabaseSyncService` implementiert `ISyncService` (`tavernup_repositories_supabase`)

**Phase 3 — Direkt wiederverwendbare UI** 🔲 blockiert (sr5_tool-Code nicht verfügbar)
- [ ] DomainTile-Hierarchie + TileGrid übernehmen
- [ ] UserAvatar, SectionHeader übernehmen
- [ ] LoginScreen übernehmen (Imports anpassen)
- [ ] go_router-Struktur + AuthGate übernehmen

**Phase 4 — Screens mit Logik-Refactoring** 🔲 blockiert (sr5_tool-Code nicht verfügbar)
- [ ] LobbyScreen: Layout übernehmen, Provider auf Interfaces umstellen
- [ ] GameGroupDetailScreen: Layout übernehmen, Einladungslogik entfernen
- [ ] CharacterDetailScreen: Layout übernehmen, ICharacterRepository einbinden

**Phase 5 — Neu schreiben** 🔲
- [ ] InviteFlow-Screens (BPMN UserTask-getrieben via WebSocket)
- [ ] InvitationMarker + InviteDialog (IUserTaskRepository + Pending-Badge)

### Key interfaces to implement (from `tavernup_domain`)
- `IAuthService` — Authentifizierung (signIn, signOut, currentUser)
- `IRealtimeTransport` — WebSocket-Verbindung zu tavernup_server
- `IProcessEventService` — UserTask push + completion
- `ISyncService` — Domain-Daten als Streams

---

## 4. Integration Tests – Supabase Repositories

**Status**: ✅ Done  
**Package**: `tavernup_repositories_supabase`

### Notes
- Tests run against local Supabase instance (Docker)
- Service-role key used throughout — RLS bypassed
- RLS policies currently disabled — see RBAC backlog item
- `user_tasks.id` is `text` — Camunda task ID roundtrip verified
- `dart_test.yaml` sets `concurrency: 1` — required for DB isolation

---

## 4. Camunda Integration

**Status**: ✅ Wired (unit-tested); 🔲 not yet verified end-to-end

### Done
- `tavernup_process_camunda` package with `CamundaProcessEngine` (Dio over `/engine-rest`)
- `WorkerRunner` in `tavernup_server` — fetchAndLock → IWorker.execute → complete/fail
- `server.dart`: completeUserTask + onExternalTaskCreated wired; safety-net `Timer.periodic(60s)`
- `CAMUNDA_BASE_URL` env var required at server start
- Dockerfile updated (Dart 3.11, all packages copied)
- 12 unit tests for CamundaProcessEngine (fake Dio adapter)
- 5 tests for WorkerRunner (MockProcessEngine)

### Open — blocking end-to-end verification
- [ ] Invitation BPMN (`invitation-process.bpmn`) auf der VM verfügbar machen —
      liegt aktuell auf dem alten Mac mit der UI
- [ ] Camunda + Camunda-DB hochfahren: `docker compose up -d camunda-db camunda`
- [ ] BPMN in Camunda deployen (via `CamundaProcessEngine.deploy` oder Web-UI)
- [ ] Einen Invitation-Prozess starten und durch alle Schritte laufen lassen
- [ ] Ggf. BPMN-Anpassung: UserTask `assignee` muss die Supabase-User-ID tragen
      (nicht Nickname) — die `validate-user`-WebSocket-Response kann benutzt werden

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
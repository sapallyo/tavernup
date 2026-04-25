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

### Branching
Work happens on a dedicated branch off `main`. Phase 1 deliberately
makes the existing client non-functional — it must not land on `main`
until Phase 6 restores client functionality through the new path.

### Phase 1 — RLS default-deny + smoke-test (forcing function)
- [ ] Migration: enable RLS on all 9 domain tables with a single
      `service_role only` policy. ANON and `authenticated` roles
      blocked. Auth tables untouched.
- [ ] Smoke-test: the existing client's direct-Supabase data path
      must fail after this migration. That failure is the positive
      proof that the safety net works; the next phases lift the
      client back to functional state via the new path.

### Phase 2 — Server structures (no behaviour change)
- [ ] `Principal` model in `tavernup_server/lib/src/rba/principal.dart`
      (`UserPrincipal(userId)`, `SystemPrincipal.instance`).
- [ ] `custom_lint` rule restricting where
      `SystemPrincipal.instance` may be referenced.
- [ ] Restrict `tavernup_repositories_supabase` public API to a
      factory; raw repos remain in `lib/src/`.
- [ ] `custom_lint` rule forbidding
      `package:tavernup_repositories_supabase/src/...` imports outside
      the RBA module.
- [ ] CODEOWNERS for the RBA module, the raw repositories package,
      and the allowed `SystemPrincipal.instance` call sites.
- [ ] RBA wrapper skeletons (one per `IXxxRepository`), accepting
      `Principal` in the constructor; first iteration is pass-through
      with placeholder filter/project logic.
- [ ] `service_role` Supabase client construction moved into the RBA
      factory; no other access path remains in the server.
- [ ] `EntityRepositoryRegistry` populated with RBA wrappers using
      `SystemPrincipal.instance`.
- [ ] Existing 299 server/domain tests stay green (verifies no
      behaviour change).

### Phase 3 — Connection authentication + DDoS mitigations
- [ ] Auth-frame protocol: first frame after WebSocket connect must
      be an `auth` frame with a Supabase Auth token; everything else
      is rejected before successful auth.
- [ ] Token validation against Supabase Auth; prefer local public-key
      validation if supported.
- [ ] Connection state holds `principal: Principal?`, transitions to
      `UserPrincipal(userId)` on success.
- [ ] Token expiry mid-connection: server closes the connection;
      client reconnects.
- [ ] DDoS mitigations (mandatory, part of the auth mechanism):
      - Auth timeout per connection (close after a few seconds without
        auth frame).
      - Bounded `awaitingAuth` pool (reject new connects when full;
        authenticated connections unaffected).
      - Per-IP rate limit on connect attempts.
- [ ] `MessageHandler.validate-user` and `complete-task` use the
      connection's `UserPrincipal` to construct the right RBA wrappers.

### Phase 4 — Repository request routing over WebSocket
- [ ] Wire-protocol extension: `repo.<repoName>.<method>` request
      type with serialised arguments.
- [ ] Dispatcher in `MessageHandler`: looks up the RBA wrapper for
      the connection's principal, calls the requested method,
      serialises the result.
- [ ] Synchronous read and write methods first; streams in Phase 5.

### Phase 5 — Stream multiplexing (largest single phase)
- [ ] `SubscriptionManager` in the server with reference-counted
      upstream subscriptions to Supabase Realtime.
- [ ] Per-principal filter/project applied in the RBA wrapper to
      every event before fan-out.
- [ ] Client frames `subscribe` / `unsubscribe` with stream-id;
      server frames `stream-event` with stream-id and payload.
- [ ] Connection close releases all of its subscriptions; last
      unsubscribe tears down the upstream subscription.

### Phase 6 — Client migration
- [ ] New package `tavernup_repositories_remote` —
      `IXxxRepository` implementations that send WebSocket requests;
      stream methods (`watchById`, `watchWhere`, `watchForAssignee`)
      implemented as WebSocket `subscribe` calls.
- [ ] Avatar upload migrated to the signed-URL flow:
      client requests permission → RBA decides → server returns a
      short-lived signed upload URL → client uploads to Storage
      directly → client reports completion → server records the path
      on the user record through the RBA wrapper.
- [ ] Avatar download integrated into the User read projection:
      RBA wrapper substitutes the storage path with a freshly signed
      download URL when the requester may see it; otherwise the
      field is omitted.
- [ ] Client `pubspec.yaml`: remove `tavernup_repositories_supabase`;
      `supabase_flutter` remains only as transitive dep of
      `tavernup_auth_supabase`.
- [ ] Client `main.dart`: provider overrides on Remote repos.
- [ ] `SupabaseSyncService` no longer used from the client.

### Phase 7 — Constraint confirmation + merge back
- [ ] CI check: `tavernup_client/pubspec.yaml` cannot list
      `tavernup_repositories_supabase`.
- [ ] All `custom_lint` rules at error severity; remaining violations
      resolved.
- [ ] Smoke-tests: client login, one read over WebSocket, one write,
      one stream emission.
- [ ] Branch merges back to `main`.

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
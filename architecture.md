# TavernUp – Architecture

## Repository

Mono-repo. Packages liegen unter `packages/`.

| Package | Language | Status |
|---|---|---|
| `tavernup_domain` | Dart | ✅ Complete, all tests green |
| `tavernup_auth_supabase` | Dart | ✅ Phase 1 foundation |
| `tavernup_repositories_supabase` | Dart | ✅ 8 repos + SupabaseSyncService |
| `tavernup_process_camunda` | Dart | ✅ CamundaProcessEngine (Camunda 7 REST) |
| `tavernup_server` | Dart | ✅ Complete, Camunda wired, all tests green |
| `tavernup_client` | Flutter 3.41.6 / Dart 3.11.4 | 🔲 In Arbeit (Phase 2 done) |

Flutter-Version per `fvm` im Repo gepinnt (siehe `.fvmrc`). Primäre Entwicklungsumgebung: Linux VM (Ubuntu 24.04 arm64).

> ⚠️ The Data Access model and Authorization Layer described below
> represent the **target architecture**. Phase 2 was implemented against
> the previous BaaS model (client → Supabase direct). Migrating
> `SupabaseSyncService` to server-mediated streams is tracked in
> `open_tasks.md`.

---

## Infrastructure

### Supabase
- Project: `tavernup`, EU Frankfurt
- ID: `xrmwdfuqeaoredwnerau`
- RLS active with default-deny policy: only `service_role` is permitted
  on all 9 domain tables; ANON and authenticated roles are blocked.
  Authorization (RBAC) happens in the server's RBA layer
  (see Authorization Layer section). The RLS policy exists solely to
  make the structural assumption "only the server talks to Supabase"
  physically enforceable; it is not the RBAC mechanism.
- Realtime active on all 9 domain tables (see `supabase/migrations/20260424120000_enable_realtime.sql`)
- `service_role` key lives **only** in `tavernup_server` (in the RBA layer)
- Start env: `export $(cat .env | xargs) && dart run bin/server.dart`
- Env vars: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CAMUNDA_BASE_URL`

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
| `user_tasks` | `id` is `text` (Camunda task IDs) |

> ⚠️ Known constraint: Camunda `ACT_` tables landed in `public` schema — Supabase pooler prevents schema-level isolation. Revisit when moving to dedicated DB for TeamUp.

### Camunda
- Version: 7.21.0 via Docker Compose on Rancher Desktop
- Custom Docker image required (Java TaskListener, see Open Tasks)

---

## Architecture Layers

tavernup_client (Flutter)
│  WebSocket only — all reads, writes, streams, and process events
tavernup_server (Dart)
│  Authorization Layer (RBA)
│    └─ Authorizing repository wrappers (the only path to data)
│    └─ Stream filtering and projection
│  MessageHandler / WebhookHandler / WorkerRunner
│  Supabase repositories (raw, service_role, restricted access)
│  Camunda integration (fetchAndLock, complete-task)
Camunda 7
│  PostgreSQL tables (ACT_*)
Supabase (PostgreSQL + Realtime)

### Client–Server Responsibility Split

**Client** is responsible for UI rendering, navigation, local UI state,
and basic UX validation (e.g. required fields). The client never speaks
to Supabase directly — it only knows the WebSocket protocol to the server.

**Server** is responsible for all business logic, **all authorization
decisions**, and orchestration via Camunda. The server is the single
trusted gateway to all persistent data. Multiple client platforms (web,
tablet, mobile) share the same server-side logic — no duplication across
clients.

### Data Access Principles

All access to domain data — reads, writes, and realtime streams — flows
through `tavernup_server`. The client has no Supabase credentials and
no direct path to the database. Supabase is an implementation detail of
the server's persistence layer.

This is a deliberate departure from the BaaS model. The reasoning:

- **Authorization must be unbypassable.** The only way to guarantee that
  every data access is checked is to route every access through code we
  control. Direct client-to-database paths cannot be retrofitted with
  authorization without re-introducing the same problem.
- **§203 StGB and TeamUp.** The platform that TavernUp prepares for
  cannot expose unfiltered database streams to clients. Building TavernUp
  the same way means the architecture transfers without rework.
- **Replaceability becomes real.** With the client unaware of Supabase,
  swapping the backend for ISO 27001-compliant German hosting affects
  exactly one package (`tavernup_repositories_supabase`), not the client.

The cost — every read incurs a server hop — is acceptable for the
expected concurrency and is the right trade-off for the security
posture.

### Communication Flow

- **All client → server traffic** runs over WebSocket using the
  `requestId` pattern for synchronous request/response correlation.
- **Reads** — client sends a repository request, server's RBA layer
  loads from Supabase, filters and projects, returns the result.
- **Writes** — client sends a write request, server's RBA layer checks
  the operation and either executes it or rejects it.
- **Realtime streams** — server subscribes to Supabase Realtime, applies
  per-user filtering and projection in the RBA layer, and forwards the
  authorized stream to the client over WebSocket.
- **Process events** — Camunda TaskListener (create-event) fires
  HTTP POST to `/webhook/task-created` for both UserTasks and
  ExternalTasks. UserTasks are pushed to the assigned client over
  WebSocket; ExternalTasks trigger `WorkerRunner.runOnce()`.
- **Safety-net** — `Timer.periodic(60s)` in `server.dart` re-runs the
  worker cycle to catch external tasks whose webhook was lost.

---

## Authorization Layer (RBA)

The RBA layer is the structural first layer of the server. Every access
to domain data passes through it. There is no path around it.

### Default-Deny

Authorization is relationship-based. Access is granted only when an
explicit relationship between the authenticated user and the target
object permits it. There are no global roles and no implicit access:
if no rule grants access, access is denied.

Roles are **contextual** — they describe a relationship between a user
and a domain object (e.g. "member of group X", "game master of session
Y", "owner of character Z"), not a global property of the user. The
concrete role and permission catalog is a separate body of work and
lives outside this document; the architecture only fixes the
*mechanism*, not the rule contents.

### Principal Model

Every call into an RBA wrapper carries a `Principal`. There are exactly
two variants:

- `UserPrincipal(userId)` — the authenticated identity behind a client
  request, established when a WebSocket connection completes auth.
- `SystemPrincipal` — used by server-internal code paths that act on
  behalf of the platform itself rather than any user: Camunda
  `WorkerRunner`, webhook routing, and the server bootstrap that
  populates the repository registry. Single instance,
  `SystemPrincipal.instance`.

`SystemPrincipal` is itself a guarded resource. There is no documented
bypass around the RBA — `SystemPrincipal` does not bypass the wrappers,
it flows _through_ them, and the wrappers see it explicitly. Its use
is restricted to the small, named set of call sites above. Enforcement
mirrors the rest of the RBA boundary: a custom analyzer rule
(`custom_lint`) restricts where `SystemPrincipal.instance` may be
referenced, and CODEOWNERS gates any change to those allowed sites.

For wrappers the rule is simple: when the principal is
`SystemPrincipal`, the wrapper delegates to the raw repository
unfiltered. Every other principal goes through the full filter and
projection logic.

### Form: Authorizing Repository Wrappers

The RBA layer is **not** a separate service that other code queries
("may user X do Y?"). Querying invites bypass — any caller might forget
to ask. Instead, the RBA layer **is** the implementation of the domain
repository interfaces that the rest of the server code uses.

For every `IXxxRepository` interface in `tavernup_domain`, there are
two implementations:

- A **raw** implementation in `tavernup_repositories_supabase` that
  talks to Supabase with the `service_role` key. No authorization logic.
- An **authorizing wrapper** in the server's RBA layer that delegates
  to the raw implementation, applying access checks on writes and
  filtering plus projection on reads.

The server code (`MessageHandler`, `WorkerRunner`, etc.) only ever sees
the authorizing wrappers. The raw implementations are not visible
outside the RBA layer.

For reads, the wrapper:
- decides which records the user may see at all (filtering),
- decides which fields and which level of detail of each record the
  user may see (projection).

For writes, the wrapper checks the operation against the user's
relationship to the target object and either executes or rejects.

For realtime streams, the wrapper subscribes to the raw stream and
applies the same filter/project logic to each event before forwarding.

### Connection Authentication

A WebSocket connection becomes useful only after authentication. The
first frame after connect must be an `auth` frame carrying a Supabase
Auth token; all other frames before successful auth are rejected.
On success the server binds a `UserPrincipal` to the connection; on
token expiry during the connection the server closes the socket and
the client reconnects. Refresh frames are deliberately not part of
the protocol at this stage — they can be added later without
architectural change.

Three DDoS mitigations are part of the authentication mechanism, not
optional add-ons: an auth timeout per connection (closed if no auth
frame arrives within a few seconds), a bounded `awaitingAuth` pool
(authenticated connections are unaffected when it is full), and a
per-IP rate limit on connect attempts. Together they neutralise the
marginal structural disadvantage of auth-as-first-frame compared to
auth-in-handshake.

### Structural Enforcement

The unbypassability of the RBA layer rests on three mechanisms,
combined:

- **Package boundary.** `tavernup_repositories_supabase` exports only a
  factory that produces authorizing wrappers. Raw repository classes
  remain in `lib/src/` and are not part of the public API.
- **Lint rules.** A custom analyzer rule forbids imports of
  `package:tavernup_repositories_supabase/src/...` from anywhere other
  than the RBA layer module. Violations break the build.
- **CODEOWNERS.** The RBA layer module and the raw repository package
  require review by a designated owner group for any change. Routine
  application work cannot modify them without explicit review.
- **Credential isolation.** The `service_role` key is read from the
  environment exclusively by the RBA layer's factory. No other code
  has a path to it.

In Dart these mechanisms are conventions enforced by tooling rather
than by the language itself. The TeamUp Java/Quarkus stack will be
able to express the same boundary as a Java module with explicit
exports — strengthening the guarantee at the language level without
changing the architecture.

### RLS as Safety Net

The four mechanisms above prevent code in this repository from
bypassing the RBA layer. They do not prevent a third party from
extracting the published `ANON_KEY` out of the Flutter bundle and
talking to Supabase directly. Without RLS, Supabase would happily
return every row to that caller — making the "only the server talks
to Supabase" assumption a code convention with no physical backing.

Therefore RLS is enabled on all 9 domain tables with a single
default-deny policy: **only `service_role` is permitted**. ANON and
authenticated roles cannot read, insert, update, or delete on these
tables. The `service_role` key lives only inside the server (in the
RBA layer's Supabase client construction); no other process can present
it.

This is **not** RBAC. There is exactly one policy per table, with
identical contents, and it does not consult the user identity. RBAC
remains in the authorizing repository wrappers, where it has access
to the full domain context. RLS exists only to make the structural
boundary physically real: any path that does not go through the RBA
layer hits a closed door at the database.

Auth-related operations (login, token refresh, password reset) are
unaffected — they target Supabase Auth endpoints, not the domain
tables, and continue to work with the public `ANON_KEY` from the
client.

### Storage Access

Some domain data (avatars, future attachments) lives in object storage
rather than in the database. The RBA principle still holds: **every
access decision is made in the RBA layer of the server**. Storage is
treated as an opaque byte container that only honours short-lived,
server-signed URLs; its own access policy is "deny all except signed
requests" and it does not encode any domain-level permission.

This is a deliberate choice over Storage RLS policies that would
mirror RBA. Two sources of truth for the same authorisation decisions
are an invariant violation waiting to happen — every rule change would
need to be made twice and kept in sync. With server-signed URLs there
is exactly one source of truth (the RBA wrapper); the signature is
the receipt that the RBA said yes.

In operation:

- **Upload.** Client requests permission via WebSocket; the RBA
  wrapper decides; on yes the server returns a short-lived signed
  upload URL for a deterministic path; the client uploads bytes
  directly to storage; the client reports completion and the server
  records the path on the domain record through the same RBA wrapper.
- **Download.** When a record is read through an RBA wrapper, the
  wrapper decides whether the requester may see the attached asset.
  If yes, the projection includes a freshly signed download URL in
  place of the raw storage path. If no, the attachment field is
  omitted from the projection.

Bytes flow client ↔ storage directly, never through the WebSocket
data channel. The server stays on the control path. Transport
security (TLS) is assumed throughout. End-to-end encryption is out of
scope for TavernUp and will be a separate concept for TeamUp
(KMS/HSM territory).

### Realtime Abstraction
- Layer 1: `IRealtimeTransport` — WebSocket transport to tavernup_server
- Layer 2: `IProcessEventService` — UserTask push + completion via WebSocket
- Layer 3: `ISyncService` — domain data streams; on the server the streams
  originate from Supabase Realtime and are filtered/projected by the RBA
  layer; the client consumes them via WebSocket without knowing the source.

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

Mocks (in `tavernup_domain/lib/src/mock/`): all repositories,
`MockRealtimeTransport`, `MockProcessEngine`.

---

## Shared Repository Layer

`tavernup_repositories_supabase` is a **server-only** package. It
contains the raw repository implementations and the `service_role`-based
Supabase client. The Flutter client does not depend on this package.

The client gets its repository implementations from a separate package
(working name `tavernup_repositories_remote`) whose implementations
serialize each call as a WebSocket request to the server. The server
then routes the request through the RBA layer.

This split is what makes the data flow constraint enforceable: the
client physically cannot reach Supabase because it has no code that
can.

---

## tavernup_server

| Component | Status | Notes |
|---|---|---|
| `EntityWorker` | ✅ | Handles WorkerTasks via `IEntityRepository` registry (`invitation`, `membership`) |
| `WorkerRunner` | ✅ | Ties `IProcessEngine.fetchAndLock` → `IWorker.execute` → complete/fail; serialized |
| `WebSocketServer` | ✅ | Port 8080 |
| `MessageHandler` | ✅ | `validate-user`, `complete-task` via requestId pattern; routes completions to Camunda |
| `WebhookHandler` | ✅ | Receives Camunda webhook, routes userTask / externalTask |
| Safety-net Timer | ✅ | `Timer.periodic(60s)` in `server.dart` → `workerRunner.runOnce()` |
| RBA Layer | 🔲 | To be implemented (see open_tasks.md) |
| Repository request router | 🔲 | Routes WebSocket repository calls into RBA wrappers |

---

## tavernup_process_camunda

| Component | Status | Notes |
|---|---|---|
| `CamundaProcessEngine` | ✅ | REST adapter for `IProcessEngine` (`dio` over `/engine-rest`) |

Variable mapping Camunda ↔ `Variable`: `String`↔`string`, `Integer/Long`↔`integer`,
`Double/Float`↔`double`, `Boolean`↔`boolean`, `Json` (stringified)↔`json`.
404 on specific resources → `ArgumentError`; other error responses → `StateError`
with the server-provided message.

---

## BPMN: Invitation Process

Start({groupId, invitedBy})
→ UserTask: choose-user          (output: nickname)
→ WorkerTask: entity-operation   (validate → create-invitation)
→ UserTask: accept-invitation    (output: accepted)
→ Gateway
→ WorkerTask: entity-operation   (create-membership)
→ End

> `validate-user` is a WebSocket endpoint on the server, not a BPMN step.

---

## Replaceability Principle

All backend services and infrastructure are abstracted behind interfaces. This enables swapping Supabase for ISO 27001-compliant German hosting (TeamUp) without rearchitecting.

---

## TeamUp Context

TavernUp is the POC for **TeamUp** — an orchestration platform for school assistance coordination in the German social sector.

TeamUp requirements: ISO 27001 German hosting, BSI TR-03161, §203 StGB, no US SaaS, offline capability, RBAC. Stack: similar (Camunda/Flowable, BPMN).

> Note: NSCs (non-player characters) are not covered by the relationship-based
> authorization model as currently outlined. NSC visibility is a game master
> decision (controlled, per-session reveals) rather than a structural property
> of the user-object relationship. The RBA model needs to be revisited before
> NSC features are implemented.

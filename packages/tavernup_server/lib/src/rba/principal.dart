/// Identity carried by every call into an RBA wrapper.
///
/// Sealed because the wrappers may want to switch on the variant; a
/// future addition (e.g. service-account principals) should force every
/// wrapper to be revisited.
sealed class Principal {
  const Principal();
}

/// The authenticated end-user behind a client request. Established when
/// a WebSocket connection completes auth and bound to that connection's
/// lifetime.
class UserPrincipal extends Principal {
  final String userId;
  const UserPrincipal(this.userId);

  @override
  bool operator ==(Object other) =>
      other is UserPrincipal && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'UserPrincipal($userId)';
}

/// Server-internal principal for code paths that act on behalf of the
/// platform itself rather than any user. Wrappers receiving this
/// principal delegate to the raw repository unfiltered.
///
/// Use is restricted to a small set of named call sites: server
/// bootstrap (registry population), `WorkerRunner` (Camunda external
/// task processing), and `WebhookHandler` (incoming webhook routing).
/// Enforcement is via `custom_lint` plus CODEOWNERS — not a code
/// comment. See architecture.md, "Authorization Layer (RBA)" →
/// "Principal Model".
///
/// Single instance: [SystemPrincipal.instance]. The constructor is
/// private so no other code can fabricate one.
class SystemPrincipal extends Principal {
  const SystemPrincipal._();

  static const SystemPrincipal instance = SystemPrincipal._();

  @override
  String toString() => 'SystemPrincipal';
}

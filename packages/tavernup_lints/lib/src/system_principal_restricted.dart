import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule: `SystemPrincipal.instance` may only be referenced from a
/// small allow-list of named call sites — server bootstrap, the worker
/// runner module, and the webhook handler module. Anywhere else it is a
/// path around the RBA's user-context, see architecture.md
/// "Authorization Layer (RBA)" → "Principal Model".
class SystemPrincipalRestricted extends DartLintRule {
  const SystemPrincipalRestricted() : super(code: _code);

  static const _code = LintCode(
    name: 'rba_system_principal_restricted',
    problemMessage:
        'SystemPrincipal.instance may only be referenced from server bootstrap, '
        'the worker runner, or the webhook handler.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path;
    if (_isAllowed(filePath)) return;

    // Match either `SystemPrincipal.instance` or just `instance` accessed
    // on a `SystemPrincipal` target. The simplest safe heuristic is the
    // identifier name in a property access expression.
    context.registry.addPrefixedIdentifier((node) {
      if (node.identifier.name == 'instance' &&
          node.prefix.name == 'SystemPrincipal') {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isAllowed(String filePath) {
    // Server bootstrap.
    if (filePath.endsWith('/tavernup_server/bin/server.dart')) return true;
    // RBA module itself (defines SystemPrincipal).
    if (filePath.contains('/tavernup_server/lib/src/rba/')) return true;
    // Worker runner: dispatches BPMN external tasks under system context.
    if (filePath.contains('/tavernup_server/lib/src/workers/')) return true;
    // Webhook handler: Camunda is the caller, no end-user is on the line.
    if (filePath.contains('/tavernup_server/lib/src/webhook/')) return true;
    // Tests across packages may reference SystemPrincipal to set up
    // wrappers under a known principal.
    if (filePath.contains('/test/')) return true;
    return false;
  }
}

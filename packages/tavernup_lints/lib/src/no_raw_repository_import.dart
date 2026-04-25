import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule: raw Supabase repositories may only be imported from
/// inside the RBA module of `tavernup_server` (or from the package's
/// own tests). Any other site that imports
/// `package:tavernup_repositories_supabase/src/...` is bypassing the
/// authorizing wrappers — see architecture.md, "Authorization Layer
/// (RBA)" → "Structural Enforcement".
class NoRawRepositoryImport extends DartLintRule {
  const NoRawRepositoryImport() : super(code: _code);

  static const _code = LintCode(
    name: 'rba_no_raw_repository_import',
    problemMessage:
        'Raw Supabase repositories may only be imported from the RBA module. '
        'Use RbaFactory to obtain authorizing wrappers instead.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  static const _forbiddenPrefix =
      'package:tavernup_repositories_supabase/src/';

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path;
    if (_isAllowed(filePath)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      if (uri.startsWith(_forbiddenPrefix)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isAllowed(String filePath) {
    // Inside the RBA module — the one place authorizing wrappers live.
    if (filePath.contains('/tavernup_server/lib/src/rba/')) return true;
    // Inside the repositories-supabase package itself (its own lib and
    // tests need access to its own `src/` files).
    if (filePath.contains('/tavernup_repositories_supabase/lib/')) return true;
    if (filePath.contains('/tavernup_repositories_supabase/test/')) return true;
    return false;
  }
}

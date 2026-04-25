import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/no_raw_repository_import.dart';
import 'src/system_principal_restricted.dart';

PluginBase createPlugin() => _TavernupLintsPlugin();

class _TavernupLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        NoRawRepositoryImport(),
        SystemPrincipalRestricted(),
      ];
}

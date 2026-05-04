# Codex Entry Point

This file is the entry point for Codex in this repository.

## Source of Truth

The canonical coding rules for this project live in:

- `./.cursor/rules/`

Start with:

- `./.cursor/rules/rules_index.mdc`

Use that index to route to the correct rule file instead of duplicating or
reinterpreting rules from memory.

## Rule Categories

### Global

- `./.cursor/rules/global_guardrails.mdc`
- `./.cursor/rules/rules_authoring.mdc`

### Universal

Use these as language-agnostic guidance:

- `./.cursor/rules/general_rules.mdc`
- `./.cursor/rules/clean_architecture.mdc`
- `./.cursor/rules/solid_principles.mdc`
- `./.cursor/rules/testing.mdc`

### Dart and Flutter

Use these only for Dart/Flutter code:

- `./.cursor/rules/coding_style.mdc`
- `./.cursor/rules/null_safety.mdc`
- `./.cursor/rules/flutter_widgets.mdc`
- `./.cursor/rules/ui_ux_design.mdc`
- `./.cursor/rules/testing_dart_flutter.mdc`

### Project-Specific

Use these for repository-specific decisions:

- `./.cursor/rules/project_specifics.mdc`
- `./.cursor/rules/project_product_scope.mdc`
- `./.cursor/rules/project_architecture.mdc`
- `./.cursor/rules/project_platform_dependencies.mdc`
- `./.cursor/rules/project_data_domain.mdc`
- `./.cursor/rules/project_agent_sql.mdc`
- `./.cursor/rules/project_shared_components.mdc`
- `./.cursor/rules/project_conventions.mdc`

## Usage Rules

- Do not rewrite the rules from `./.cursor/rules` here
- Use `./.cursor/rules/rules_index.mdc` to route each topic to its owning file
- Treat `./.cursor/rules/project_specifics.mdc` as the entry point for
  repository-specific conventions
- Keep this file concise and defer detailed policy to the owning rule file

## Notes

- The correct folder is `./.cursor/rules`, not `./.cursor/roles`
- Plug hub API summaries (markdown, not rules): `./docs/plug_server_docs_index_for_colmeia.md`, `./docs/bridge_agent_sql_api_options.md`

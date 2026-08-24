# Changelog

## 0.2.8

- Refresh the runtime for MoonBit 0.10.10 and remove deprecated builder APIs.
- Add policy, cache, redaction, source-boundary, and readiness-report tests.
- Keep project documentation focused on application use, reproducible checks, and license scope.

## [0.2.7] - 2026-08-18

- Add production runtime modules for contexts, bundles, caching, batch rendering, schemas, localization, safe HTML/JSON/Markdown output, reporting, and release policies.
- Expand boundary coverage across wasm-gc, JavaScript, and native targets.
- Add deterministic policy, cache, diagnostics, and adapter tests for production workflows.

## [0.2.6] - 2026-08-16

- Migrate the CLI package to the current stable `pkgtype` configuration.
- Add explicit wasm-gc, JavaScript, and native CI checks and tests.
- Refresh local quality scripts and documentation for the current toolchain.

## [0.2.5] - 2026-08-11
### Added
- Non-nesting `{# ... #}` comments and ASCII whitespace-control markers.
- Parameterized `replace`, Unicode-safe `truncate`, and blank-aware `default`
  filters with constrained string/integer arguments.
- Source-aware `DiagnosticKind`/`Diagnostic` APIs and strict rendering.
- CLI `--diagnostics text|json` output with stable machine-readable fields.
- Template inspection, context audits, bounded rendering metrics, and typed
  output/iteration/depth failures.
- Unicode-safe utility filters, extended CLI workflows, and a 14-case
  deterministic benchmark catalog with stable JSON evidence.

### Changed
- Added parser position tracking without changing the public `Token` or
  `Node::Variable(String, Array[String])` shapes.
- Expanded CI and native smoke coverage for the new syntax and diagnostics.

## [0.2.4] - 2026-08-11
### Added
- Security-oriented built-in filters: `escape_html`, `escape_json`, and `slugify`.
- A tracked CLI example and native CI checks for file-based rendering.
- A tracked native CLI benchmark workload with Linux and Windows runners.
- Real filter pipeline parsing and execution with built-in `trim`, `uppercase`, and `lowercase` filters.
- A native CLI that renders template files or inline templates with repeated `--var key=value` arguments.
- Repository quality assets: workflow gates, project health checks, source-attribution notes, and reproducible benchmark evidence.

### Changed
- Upgraded the quality gate to modern MoonBit checks: `moon fmt --check`, `moon info`, `moon check --deny-warn`, and `moon test --deny-warn`.
- Reworked parser control-flow handling to support `{% else %}` and stricter block termination validation.
- Cleaned repository hygiene by removing generated `_build` artifacts from version control and tracking the public API with `pkg.generated.mbti`.

### Fixed
- Fixed asynchronous template-file reading and error propagation in the native CLI.
- Rejected conflicting `--file`/`--template` inputs and unknown arguments after an inline template.
- Removed deprecated MoonBit APIs and syntax that triggered warnings on the latest toolchain.
- Corrected garbled UTF-8 documentation and submission material text.

## [1.0.0] - 2026-07-05
### Added
- Complete AST parsing and compilation pipeline.
- Full support for `{% if %}` and `{% for %}` control flows.
- Extensible filter engine (`{{ var | filter }}`).
- Gitea CI workflow configuration for automated testing on compatible Git hosts.
- Comprehensive `README.md` and documentation overhaul.

### Fixed
- Migrated code and configurations (`moon.mod`, `moon.pkg`) to align with the MoonBit 0.1.20260624 toolchain.

## [0.1.0] - Initial release
- Initial release of MoonTemplate with basic Lexer, Parser, and Engine support.

# Changelog

## [0.2.3] - 2026-08-11
### Added
- A tracked CLI example and native CI checks for file-based rendering.
- A tracked native CLI benchmark workload with Linux and Windows runners.
- Real filter pipeline parsing and execution with built-in `trim`, `uppercase`, and `lowercase` filters.
- A native CLI that renders template files or inline templates with repeated `--var key=value` arguments.
- Acceptance self-check assets: workflow gates, compliance scripts, source-attribution notes, and official requirement tracking.

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
- Gitea CI workflow configuration for automated testing on GitLink.
- Comprehensive `README.md` and documentation overhaul.

### Fixed
- Migrated code and configurations (`moon.mod`, `moon.pkg`) to align with the MoonBit 0.1.20260624 toolchain.

## [0.1.0] - Initial release
- Initial release of MoonTemplate with basic Lexer, Parser, and Engine support.

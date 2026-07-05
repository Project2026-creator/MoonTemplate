# Changelog

## [0.2.0] - 2026-07-05
### Added
- Complete AST parsing and compilation pipeline.
- Full support for `{% if %}` and `{% for %}` control flows.
- Extensible filter engine (`{{ var | filter }}`).
- Gitea CI workflow configuration for automated testing on GitLink.
- Comprehensive `README.md` and documentation overhaul.

### Fixed
- Migrated code and configurations (`moon.mod`, `moon.pkg`) to 100% align with MoonBit 0.1.20260624 toolchain.

## [0.1.0] - Initial release
- Initial release of MoonTemplate with basic Lexer, Parser and Engine.
- Added variable interpolation `{{ var }}`.
- Added control flow `{% if cond %}`.
- Added Filter system architecture.

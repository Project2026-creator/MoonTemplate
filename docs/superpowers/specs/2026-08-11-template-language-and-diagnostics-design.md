# MoonTemplate 0.2.5 Design: Template Language and Diagnostics

## Goals

- Add practical template-language features without breaking existing callers.
- Keep the public `Node::Variable(String, Array[String])` representation unchanged.
- Add structured diagnostics that retain a stable text compatibility path.
- Exercise the new behavior through library tests, native CLI examples, and CI.
- Increase real MoonBit source and test scope to approximately 1350–1450 lines.

## Syntax

- `{# ... #}` is a non-nesting comment and produces no output.
- `{{-` and `{%-` trim trailing ASCII whitespace from the preceding text node.
- `-}}` and `-%}` trim leading ASCII whitespace from the following text node.
- Filters accept `replace("old", "new")`, `truncate(20)`, and
  `default("fallback")`. Arguments are quoted strings or signed decimal
  integers; string arguments support `\\` and `\"` escapes.

## Compatibility boundary

- Existing `Token` and `Node` constructors remain available and unchanged.
- Legacy filter names remain stored as plain strings.
- Parameterized filter calls use a private encoding inside the existing filter
  string array; consumers do not depend on that encoding.
- `Engine::new` and `Engine::render` preserve their signatures and legacy
  behavior. Strict behavior is opt-in through new APIs.

## Diagnostics

- `DiagnosticKind` distinguishes lexical, syntax, and filter failures.
- `Diagnostic` exposes kind, message, 1-based line and column, and source line.
- `Parser::parse_with_diagnostics`, `Engine::new_with_diagnostics`, and
  `Engine::render_strict` return structured diagnostics.
- Runtime failures without a source span use line and column zero.

## CLI and JSON

- `--diagnostics text|json` selects the error presentation; text remains the
  default.
- JSON errors contain `code`, `kind`, `message`, `line`, `column`, and
  `source_line` fields.
- Existing successful commands and default text errors remain unchanged.

## Verification

- Add red-green tests for comments, whitespace controls, nested blocks,
  parameterized filters, invalid arguments, diagnostics, and CLI JSON output.
- Run formatting, API snapshot, build, strict checks, normal/native tests,
  coverage, smoke examples, and the native benchmark on CI.
- Keep both repository mirrors synchronized and publish version 0.2.5 only
  after the GitHub quality workflow is green.

# MoonTemplate API

## Core Types

### `Engine`

The main entry point for parsing and rendering templates.

```moonbit
import "Project2026-creator/moontemplate/src/moontemplate" @moontemplate

let engine = @moontemplate.Engine::new("Hello {{ name }}").unwrap()
```

Available methods:

- `Engine::new(template)` parses a template string into an executable engine.
- `Engine::new_with_diagnostics(template)` returns source-aware diagnostics.
- `Engine::register_filter(name, fn)` registers or overrides a filter.
- `Engine::render(context)` renders the parsed AST using a `Map[String, String]`.
- `Engine::render_strict(context)` rejects unknown filters with structured
  runtime diagnostics.
- `Engine::stats()` returns node, filter, depth, and literal-character counts.
- `Engine::required_variables()` and `Engine::filter_names()` expose stable
  first-use dependency lists.
- `Engine::audit_context(context)` reports missing and unused context keys.
- `Engine::render_with_limits(context, limits)` returns a `RenderReport` with
  output and runtime metrics, or `RenderFailure` when a budget is exceeded.

`inspect_template(template, known_filters)` combines parsing, statistics,
dependency collection, and lint issues into one preflight result. `LintSeverity`
and `TemplateLintIssue` are intended for editor and CI integrations.

`Parser::parse_with_diagnostics` is available for callers that already have
tokens. `Diagnostic` exposes `kind`, `message`, `line`, `column`, `source_line`,
and stable `code` values (`TMPL_LEX`, `TMPL_PARSE`, and `TMPL_FILTER`).

### Built-in filters

- `trim`
- `uppercase`
- `lowercase`
- `escape_html`
- `escape_json`
- `slugify`
- `length`
- `collapse_whitespace`
- `capitalize`
- `newline_to_br`
- `replace("old", "new")`
- `truncate(limit)`
- `default("fallback")`
- `prefix("text")` and `suffix("text")`
- `pad_left(width, "fill")` and `pad_right(width, "fill")`
- `slice(start, length)` using Unicode character indexes

## Resource limits and benchmark evidence

`RenderLimits::new(max_output_chars, max_iterations, max_depth)` prevents
unbounded output, loop expansion, or recursive control-flow traversal.
`RenderMetrics` records output characters, visited nodes, loop iterations,
maximum depth, resolved variables, and missing variables. The deterministic
benchmark catalog is available through `benchmark_cases()` and
`run_benchmark_suite()`; `benchmark_report_json()` is suitable for CI artifacts.

## Rendering contract

- Missing variables render as an empty string.
- `if` conditions treat `""`, `"0"`, and `"false"` as false.
- `for` loops read comma-separated values from the context map.
- Empty loop items are ignored after trimming whitespace.

## Public API snapshot

Run `moon info` to refresh [`src/moontemplate/pkg.generated.mbti`](../src/moontemplate/pkg.generated.mbti) whenever exported APIs change. CI checks that the committed snapshot is current.

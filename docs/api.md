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
- `replace("old", "new")`
- `truncate(limit)`
- `default("fallback")`

## Rendering contract

- Missing variables render as an empty string.
- `if` conditions treat `""`, `"0"`, and `"false"` as false.
- `for` loops read comma-separated values from the context map.
- Empty loop items are ignored after trimming whitespace.

## Public API snapshot

Run `moon info` to refresh [`src/moontemplate/pkg.generated.mbti`](../src/moontemplate/pkg.generated.mbti) whenever exported APIs change. CI checks that the committed snapshot is current.

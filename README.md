# MoonTemplate

MoonTemplate is a MoonBit-native text template engine for generating HTML, emails, configuration files, prompts, and code snippets from simple declarative templates.

[![MoonBit](https://img.shields.io/badge/MoonBit-current%20stable-orange?style=flat-square)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=flat-square)](LICENSE)
[![GitHub CI](https://img.shields.io/badge/CI-GitHub%20Actions-success?style=flat-square)](.github/workflows/ci.yml)
[![GitLink CI](https://img.shields.io/badge/CI-Gitea%20Actions-success?style=flat-square)](.gitea/workflows/ci.yml)

## Why This Project

MoonTemplate generates structured text from data for practical MoonBit tooling
and application workflows.

MoonTemplate targets the common “generate structured text from data” problem in the MoonBit ecosystem:

- static page generators
- CLI report generation
- config and manifest synthesis
- email and notification rendering
- code scaffolding and boilerplate generation

The implementation is intentionally small, readable, and reviewable, but it already covers the core engineering surface expected from an OSC2026 acceptance repository: public source, reproducible checks, real tests, CI, a CLI entry point, API snapshots, and source-attribution documentation.

## Feature Set

- Variable interpolation: `{{ name }}`
- Non-nesting comments: `{# internal note #}`
- ASCII whitespace control: `{{- name -}}` and `{%- if ok -%}`
- Filter pipelines: `{{ name | trim | uppercase }}`
- Parameterized filters: `replace("old", "new")`, `truncate(20)`, `default("fallback")`, `prefix`, `suffix`, `pad_left`, `pad_right`, and Unicode `slice`
- Built-in filters: `trim`, `uppercase`, `lowercase`, `escape_html`, `escape_json`, `slugify`, `length`, `collapse_whitespace`, `capitalize`, and `newline_to_br`
- Custom filters via `Engine::register_filter`
- Conditional rendering with `if` / `else`
- Loop rendering with `{% for item in list %}`
- Preflight inspection: AST statistics, required context keys, filter dependencies, lint issues, and context audits
- Bounded rendering with output, iteration, and nesting budgets plus reproducible metrics
- A deterministic benchmark catalog covering web, documentation, data, security, Unicode, and boundary workloads
- Native CLI for file-based or inline rendering
- Structured lexical, syntax, and filter diagnostics
- Public API snapshot tracked in [`src/moontemplate/pkg.generated.mbti`](src/moontemplate/pkg.generated.mbti)

## Template Syntax

```text
Hello, {{ user | trim }}!

{% if is_admin %}
Role: ADMIN
{% else %}
Role: USER
{% endif %}

Members:
{% for member in users %}
- {{ member | trim }}
{% endfor %}
```

Loop variables are read from comma-separated strings in the input context. Empty items are ignored.

More syntax examples live in [`docs/syntax.md`](docs/syntax.md).

## Quick Start

### Add the library

```bash
moon add Project2026-creator/moontemplate
```

### Render from MoonBit

```moonbit
import "Project2026-creator/moontemplate/src/moontemplate" @moontemplate

let template =
  #|Hello, {{ user | trim }}!
  #|{% if admin %}Welcome back, admin.{% else %}Welcome back.{% endif %}

let engine = @moontemplate.Engine::new(template).unwrap()
let ctx = Map([], capacity=2)
ctx.set("user", " MoonBit ")
ctx.set("admin", "true")

let output = engine.render(ctx)
println(output)
```

### Register a custom filter

```moonbit
import "Project2026-creator/moontemplate/src/moontemplate" @moontemplate

let engine = @moontemplate.Engine::new("{{ name | suffix }}").unwrap()
engine.register_filter("suffix", fn(value) { value + "!" })
```

### Safe output helpers

Use `escape_html` when interpolating untrusted text into HTML, `escape_json`
when producing a JSON string value, and `slugify` when deriving a stable
ASCII-oriented identifier:

```text
<h1 id="{{ title | slugify }}">{{ title | escape_html }}</h1>
{{ payload | escape_json }}
```

The tracked [`examples/secure-output.txt`](examples/secure-output.txt) file
demonstrates the HTML use case end to end.

### Parameterized filters and whitespace control

```text
{# comments are removed before rendering #}
{{ title | replace("Moon", "Star") | truncate(20) | default("Untitled") }}
{%- if enabled -%}
enabled
{%- endif -%}
```

Arguments are limited to double-quoted strings (with `\\` and `\"` escapes)
and signed decimal integers. Calls remain encoded in the compatible
`Node::Variable(String, Array[String])` representation.

### Inspection and bounded rendering

Use `inspect_template` before accepting templates from users or CI. It reports
node counts, literal character counts, referenced context keys, filter
dependencies, and lint issues. For untrusted input, use
`RenderLimits::new(output_chars, iterations, depth)` and inspect the returned
`RenderReport.metrics()` counters. Limits count Unicode characters rather than
UTF-8 bytes.

## CLI Usage

The CLI package targets `native`, so it needs a system C compiler when you run it locally.

```bash
moon run src/cli --target native -- --file examples/welcome.txt --var name=MoonBit
moon run src/cli --target native -- --template "Hello {{ name | uppercase }}" --var name=moonbit
moon run src/cli --target native -- --file examples/secure-output.txt --var "title=MoonBit & Templates" --var "body=<strong>safe</strong>"
moon run src/cli --target native -- --diagnostics json --template "{{ name | truncate(\"five\") }}"
moon run src/cli --target native -- --check --template "Hello {{ name | trim }}"
moon run src/cli --target native -- --stats --template "{% for item in items %}{{ item }}{% endfor %}"
moon run src/cli --target native -- --max-output 1000 --max-iterations 50 --max-depth 8 --template "{{ name }}" --var name=MoonBit
```

The first command reads the tracked example file [`examples/welcome.txt`](examples/welcome.txt), so it can be copied and run immediately after cloning.

Supported options:

- `--file <path>` or positional file path
- `--template <inline-template>`
- `--var key=value` (repeatable)
- `--vars-file <path>` for `key=value` entries; blank lines and `#` comments are ignored
- `--diagnostics text|json` (text is the default)
- `--check` to parse and lint without rendering
- `--stats` to emit stable template statistics JSON
- `--max-output <N>`, `--max-iterations <N>`, and `--max-depth <N>` for bounded rendering
- `--help`

`--file` and `--template` are mutually exclusive. A missing file, malformed
variable assignment, parser error, or unknown option is reported as a CLI error.
JSON diagnostics use the stable fields `code`, `kind`, `message`, `line`,
`column`, and `source_line`; runtime-only filter failures use line and column
zero.

For a larger, repeatable native workload, run
[`scripts/benchmark.ps1`](scripts/benchmark.ps1) on Windows or
[`scripts/benchmark.sh`](scripts/benchmark.sh) on Linux/macOS. The same
10-iteration benchmark runs in both CI workflows and reports total and average
milliseconds in the job log; it is an end-to-end CLI baseline, not a hardware
independent performance promise.

The library also contains a 14-case deterministic workload catalog and a
machine-readable report API (`run_benchmark_suite` and
`benchmark_report_json`) for CI evidence.

## Quality Gates

CI installs the current stable MoonBit toolchain from the official installer.
The organizer feedback originally cited MoonBit `0.10.3`; current stable
toolchains use `pkgtype(kind: "executable")` in `moon.pkg`. CI prints the exact
installed version and checks the committed API snapshot.

Local verification:

```bash
moon fmt --check
moon info
moon build
moon check --deny-warn
moon test --deny-warn
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon check --target js --deny-warn
moon test --target js --deny-warn
moon check --target native --deny-warn
moon test --target native --deny-warn
moon test --deny-warn --enable-coverage
moon coverage report -f summary
```

The library is checked and tested on wasm-gc, JavaScript, and native. The CLI
is intentionally native-only because it uses process arguments and filesystem
I/O. Native commands require a C compiler (`build-essential` on the CI runner).

Repository acceptance helpers:

- [`docs/official-requirements.md`](docs/official-requirements.md)
- [`docs/acceptance-checklist.md`](docs/acceptance-checklist.md)
- [`docs/source-attribution.md`](docs/source-attribution.md)
- [`docs/performance.md`](docs/performance.md)
- [`docs/benchmark-evidence.md`](docs/benchmark-evidence.md)
- [`scripts/verify_acceptance.ps1`](scripts/verify_acceptance.ps1)
- [`scripts/check_repo_compliance.py`](scripts/check_repo_compliance.py)

## Repository Links

- GitHub: <https://github.com/Project2026-creator/MoonTemplate>
- GitLink: <https://gitlink.org.cn/Hero001/moontemplate>
- Mooncakes package name: `Project2026-creator/moontemplate`

## License

MoonTemplate is released under the Apache 2.0 License. See [`LICENSE`](LICENSE).

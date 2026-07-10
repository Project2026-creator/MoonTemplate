# MoonTemplate

MoonTemplate is a MoonBit-native text template engine for generating HTML, emails, configuration files, prompts, and code snippets from simple declarative templates.

[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20260703-orange?style=flat-square)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=flat-square)](LICENSE)
[![GitHub CI](https://img.shields.io/badge/CI-GitHub%20Actions-success?style=flat-square)](.github/workflows/ci.yml)
[![GitLink CI](https://img.shields.io/badge/CI-Gitea%20Actions-success?style=flat-square)](.gitea/workflows/ci.yml)

## Why This Project

MoonTemplate targets the common “generate structured text from data” problem in the MoonBit ecosystem:

- static page generators
- CLI report generation
- config and manifest synthesis
- email and notification rendering
- code scaffolding and boilerplate generation

The implementation is intentionally small, readable, and reviewable, but it already covers the core engineering surface expected from an OSC2026 acceptance repository: public source, reproducible checks, real tests, CI, a CLI entry point, API snapshots, and source-attribution documentation.

## Feature Set

- Variable interpolation: `{{ name }}`
- Filter pipelines: `{{ name | trim | uppercase }}`
- Built-in filters: `trim`, `uppercase`, `lowercase`
- Custom filters via `Engine::register_filter`
- Conditional rendering with `if` / `else`
- Loop rendering with `{% for item in list %}`
- Native CLI for file-based or inline rendering
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
let template =
  #|Hello, {{ user | trim }}!
  #|{% if admin %}Welcome back, admin.{% else %}Welcome back.{% endif %}

let engine = Engine::new(template).unwrap()
let ctx = Map([], capacity=2)
ctx.set("user", " MoonBit ")
ctx.set("admin", "true")

let output = engine.render(ctx)
println(output)
```

### Register a custom filter

```moonbit
let engine = Engine::new("{{ name | suffix }}").unwrap()
engine.register_filter("suffix", fn(value) { value + "!" })
```

## CLI Usage

The CLI package targets `native`, so it needs a system C compiler when you run it locally.

```bash
moon run src/cli --target native -- --file template.txt --var name=MoonBit
moon run src/cli --target native -- --template "Hello {{ name | uppercase }}" --var name=moonbit
```

Supported options:

- `--file <path>` or positional file path
- `--template <inline-template>`
- `--var key=value` (repeatable)
- `--help`

## Quality Gates

MoonTemplate is maintained against the latest locally installable MoonBit toolchain available in this workspace. As of July 10, 2026, that is `moon 0.1.20260703`; the older `0.10.3` wording seen in organizer feedback does not match the current installer output here.

Local verification:

```bash
moon fmt --check
moon info
moon check --deny-warn
moon test --deny-warn
```

Repository acceptance helpers:

- [`docs/official-requirements.md`](docs/official-requirements.md)
- [`docs/acceptance-checklist.md`](docs/acceptance-checklist.md)
- [`docs/source-attribution.md`](docs/source-attribution.md)
- [`scripts/verify_acceptance.ps1`](scripts/verify_acceptance.ps1)
- [`scripts/check_repo_compliance.py`](scripts/check_repo_compliance.py)

## Repository Links

- GitHub: <https://github.com/Project2026-creator/MoonTemplate>
- GitLink: <https://gitlink.org.cn/Hero001/moontemplate>
- Mooncakes package name: `Project2026-creator/moontemplate`

## License

MoonTemplate is released under the Apache 2.0 License. See [`LICENSE`](LICENSE).

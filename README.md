# MoonTemplate

MoonTemplate is a MoonBit-native text template engine for generating HTML, emails, configuration files, prompts, and code snippets from simple declarative templates.

[![MoonBit](https://img.shields.io/badge/MoonBit-current%20stable-orange?style=flat-square)](https://www.moonbitlang.com/)
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

## CLI Usage

The CLI package targets `native`, so it needs a system C compiler when you run it locally.

```bash
moon run src/cli --target native -- --file examples/welcome.txt --var name=MoonBit
moon run src/cli --target native -- --template "Hello {{ name | uppercase }}" --var name=moonbit
```

The first command reads the tracked example file [`examples/welcome.txt`](examples/welcome.txt), so it can be copied and run immediately after cloning.

Supported options:

- `--file <path>` or positional file path
- `--template <inline-template>`
- `--var key=value` (repeatable)
- `--help`

`--file` and `--template` are mutually exclusive. A missing file, malformed
variable assignment, parser error, or unknown option is reported as a CLI error.

For a larger, repeatable native workload, run
[`scripts/benchmark.ps1`](scripts/benchmark.ps1) on Windows or
[`scripts/benchmark.sh`](scripts/benchmark.sh) on Linux/macOS. The same
10-iteration benchmark runs in both CI workflows and reports total and average
milliseconds in the job log; it is an end-to-end CLI baseline, not a hardware
independent performance promise.

## Quality Gates

CI installs the current stable MoonBit toolchain from the official installer. The repository is checked with the current toolchain available at validation time; this validation used `moonc 0.10.4`, which is newer than the `0.10.3` version mentioned in the organizer feedback.

Local verification:

```bash
moon fmt --check
moon info
moon build
moon check --deny-warn
moon test --deny-warn
moon check --target native --deny-warn
moon test --target native --deny-warn
```

The native commands require a C compiler (`build-essential` on the CI runner).

Repository acceptance helpers:

- [`docs/official-requirements.md`](docs/official-requirements.md)
- [`docs/acceptance-checklist.md`](docs/acceptance-checklist.md)
- [`docs/source-attribution.md`](docs/source-attribution.md)
- [`docs/performance.md`](docs/performance.md)
- [`scripts/verify_acceptance.ps1`](scripts/verify_acceptance.ps1)
- [`scripts/check_repo_compliance.py`](scripts/check_repo_compliance.py)

## Repository Links

- GitHub: <https://github.com/Project2026-creator/MoonTemplate>
- GitLink: <https://gitlink.org.cn/Hero001/moontemplate>
- Mooncakes package name: `Project2026-creator/moontemplate`

## License

MoonTemplate is released under the Apache 2.0 License. See [`LICENSE`](LICENSE).

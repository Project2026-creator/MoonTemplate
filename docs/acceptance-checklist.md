# MoonTemplate Acceptance Checklist

Status updated on August 11, 2026.

| Item | Status | Notes |
| --- | --- | --- |
| Public repository | Ready | GitHub and GitLink mirrors are configured for the same project identity. |
| Default branch | Ready | `main` is the canonical branch on GitHub. |
| README | Ready | Overview, syntax, CLI, quality gates, and acceptance docs are linked from the root README. |
| License | Ready | Apache 2.0 full text is included in `LICENSE`. |
| Commit history | Ready | Public post-acceptance commits are present and reviewable; run the self-check script for the current count. |
| MoonBit as main language | Ready | Core implementation lives under `src/moontemplate` and the CLI under `src/cli`. |
| Source规模 | Ready | Current `src/**/*.mbt` source and test footprint is several hundred lines and still growing with docs and scripts. |
| Filters | Ready | Parser and engine both support filter pipelines; built-in and custom filters are covered by tests. |
| Control-flow edges | Ready | `if` / `else` / `for` plus missing-block error handling are covered by tests. |
| CLI | Ready | Native CLI accepts `--file`, `--template`, and repeated `--var key=value`. |
| CI | Ready | GitHub and Gitea workflows include `moon fmt --check`, `moon info`, `moon build`, `moon check --deny-warn`, and `moon test --deny-warn`. |
| Coverage and performance evidence | Ready | CI emits coverage summaries and runs the tracked 10-iteration native workload; complexity and reproduction steps are documented in `docs/performance.md`. |
| Build artifact hygiene | Ready | `_build/` and temporary outputs are excluded from version control. |
| Public API snapshot | Ready | `src/moontemplate/pkg.generated.mbti` is tracked and checked in CI. |
| Source attribution | Ready | See `docs/source-attribution.md`. |
| Self-check automation | Ready | See `scripts/verify_acceptance.ps1` and `scripts/check_repo_compliance.py`. |

## Local verification commands

The current implementation adds comments, whitespace control, parameterized
filters, Unicode boundary tests, structured diagnostics, and CLI JSON smoke
coverage. The tracked source/test footprint is approximately 1.8k functional
MoonBit lines; CI also runs native CLI and benchmark evidence.

```bash
moon fmt --check
moon info
moon check --deny-warn
moon test --deny-warn
python scripts/check_repo_compliance.py
pwsh scripts/verify_acceptance.ps1
```

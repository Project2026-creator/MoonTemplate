# MoonTemplate Practical Engineering Expansion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task with verification checkpoints.

**Goal:** Extend MoonTemplate with practical analysis, linting, bounded rendering, richer safe filters, and reproducible CLI workflows while keeping existing templates and `Engine::new`/`Engine::render` compatible; raise functional MoonBit source and test scope above 3500 lines locally.

**Architecture:** Keep the existing lexer/parser/AST and legacy rendering path intact. Add analysis and bounded-rendering modules that consume the existing `Node` tree, add private helpers rather than changing `Node::Variable(String, Array[String])`, and expose only small value-object APIs. The CLI remains native-only and gains opt-in `--check`, `--stats`, `--strict`, and `--var-file` behavior while its default output remains unchanged.

**Tech Stack:** MoonBit 0.10.x, `moon fmt`, `moon info`, `moon build`, `moon check`, `moon test`, native CLI, GitHub/Gitea CI, tracked examples and benchmark fixtures.

---

### Task 1: Baseline audit and plan evidence

**Files:**
- Create: `docs/superpowers/plans/2026-08-12-practical-engineering-expansion.md`
- Inspect: `README.md`, `LICENSE`, `CONTRIBUTING.md`, `docs/*.md`, `.github/workflows/ci.yml`, `.gitea/workflows/ci.yml`, `scripts/*`, `src/**/*.mbt`

- [x] Record current branch, commit authors, default branch, source count, tests, tracked artifacts, and forbidden-name scan in the working notes.
- [x] Preserve both isolated worktrees and do not push any remote during this plan.
- [ ] Re-run the full local verification after implementation and compare every acceptance item with evidence.

### Task 2: Template analysis and lint API (TDD)

**Files:**
- Create: `src/moontemplate/analysis.mbt`
- Create: `src/moontemplate/analysis_test.mbt`
- Modify: `src/moontemplate/engine.mbt`
- Modify: `src/moontemplate/pkg.generated.mbti`
- Mirror the same changes in the GitLink worktree.

- [ ] Add failing tests for `TemplateStats`, `TemplateLintIssue`, required-variable collection, filter collection, maximum nesting depth, and linting unknown filters.
- [ ] Implement:
  - `pub(all) enum LintSeverity { Info Warning Error }`.
  - `pub struct TemplateStats` with methods `node_count`, `text_nodes`, `variable_nodes`, `if_nodes`, `for_nodes`, `filter_count`, `max_depth`, `literal_chars`.
  - `pub struct TemplateLintIssue` with methods `severity`, `code`, `message`, `line`, `column`, `source_line`.
  - `pub fn Engine::stats(self : Engine) -> TemplateStats`.
  - `pub fn Engine::required_variables(self : Engine) -> Array[String]`.
  - `pub fn Engine::filter_names(self : Engine) -> Array[String]`.
  - `pub fn lint_template(template : String, known_filters : Array[String]) -> Result[Array[TemplateLintIssue], Array[Diagnostic]]`.
  - Stable lint codes `TMPL_UNUSED_CONTEXT`, `TMPL_UNKNOWN_FILTER`, `TMPL_EMPTY_TEMPLATE`, and `TMPL_DEEP_NESTING`.
- [ ] Keep collection order deterministic and deduplicate names without changing render behavior.
- [ ] Run `moon fmt`, `moon check --deny-warn`, and targeted analysis tests.

### Task 3: Bounded rendering and metrics (TDD)

**Files:**
- Create: `src/moontemplate/limits.mbt`
- Create: `src/moontemplate/limits_test.mbt`
- Modify: `src/moontemplate/engine.mbt`
- Modify: `src/moontemplate/diagnostics.mbt`
- Mirror the same changes in the GitLink worktree.

- [ ] Add failing tests for output limits, loop-item limits, filter-application metrics, nested-branch accounting, and compatibility of unbounded `render`.
- [ ] Implement `pub struct RenderLimits` with default values and builders for `max_output_chars`, `max_loop_items`, `max_depth`, and `max_context_entries`.
- [ ] Implement `pub struct RenderMetrics` with `output_chars`, `node_visits`, `loop_iterations`, and `filter_applications` accessors.
- [ ] Implement `pub struct RenderReport { output : String, metrics : RenderMetrics }` and `Engine::render_with_limits(context, limits) -> Result[RenderReport, Array[Diagnostic]]`.
- [ ] Enforce limits before appending output or entering a loop; use line/column zero for runtime resource diagnostics and code `TMPL_LIMIT`.
- [ ] Keep `Engine::render` as the existing permissive API and avoid changing `Node` constructors.
- [ ] Run targeted limits tests and native/static checks.

### Task 4: Practical safe filters (TDD)

**Files:**
- Modify: `src/moontemplate/filters.mbt`
- Modify: `src/moontemplate/filters_test.mbt`
- Modify: `docs/syntax.md`, `docs/api.md`, `README.md`
- Mirror the same changes in the GitLink worktree.

- [ ] Add failing tests for URL percent encoding, CSV quoting, indentation, line-ending normalization, and Unicode-safe word/character counts.
- [ ] Implement and register `url_encode`, `csv_quote`, `indent(width)`, `normalize_newlines`, `word_count`, and `char_count` with deterministic behavior and no external dependencies.
- [ ] Extend the restricted argument parser only with the minimum required string/integer calls; reject malformed and negative indentation arguments with filter diagnostics.
- [ ] Document security boundaries: escaping is explicit, URL encoding is component-oriented, and filters do not sanitize arbitrary HTML policies.

### Task 5: CLI project workflows (TDD)

**Files:**
- Modify: `src/cli/main.mbt`
- Modify: `src/cli/main_test.mbt` or the existing CLI test section
- Create: `examples/variables.env`
- Create: `examples/catalog-report.txt`
- Modify: `scripts/benchmark.sh`, `scripts/benchmark.ps1`
- Mirror the same changes in the GitLink worktree.

- [ ] Add failing tests for `--var-file`, comments/blank lines in variable files, duplicate keys, `--check`, `--stats`, and `--strict` unknown-filter behavior.
- [ ] Implement `--var-file <path>` with UTF-8 `key=value` lines, blank/comment skipping, and deterministic last-value-wins merging before inline `--var` overrides.
- [ ] Implement `--check` to parse/lint and print a stable summary without rendering; implement `--stats` to print deterministic stats; implement `--strict` to select strict rendering.
- [ ] Preserve default text errors and successful command output when none of the new flags are used.
- [ ] Add native smoke commands for catalog rendering, variable files, check mode, stats mode, and JSON diagnostics.

### Task 6: Acceptance documentation and evidence

**Files:**
- Modify: `README.md`, `docs/api.md`, `docs/syntax.md`, `docs/performance.md`, `docs/acceptance-checklist.md`, `docs/official-requirements.md`, `OSC2026_Submission.md`, `CHANGELOG.md`
- Modify: `.github/workflows/ci.yml`, `.gitea/workflows/ci.yml`
- Create: `docs/benchmarks/catalog-baseline.md`
- Mirror all repository-level changes in the GitLink worktree.

- [ ] Document concrete catalog/report use cases, input format, output examples, CLI modes, limits, stats, lint codes, and expected failure behavior.
- [ ] Add a real benchmark fixture with 25+ records and report reproducible command, iterations, toolchain, and measured output shape; do not claim hardware-independent timing.
- [ ] Add CI steps for `moon info` snapshot, coverage summary, native smoke, CLI check/stats/var-file, and benchmark.
- [ ] Update acceptance checklist with exact source/test counts only after fresh measurement.
- [ ] Confirm README, license, contribution rules, source attribution, and repository links are consistent and contain no unrelated template-engine references.

### Task 7: Full local verification and handoff

**Files:**
- Modify: generated API snapshots only through `moon info` output.

- [ ] Run in both worktrees: `moon fmt --check`, `moon info`, `moon build`, `moon check --deny-warn`, `moon check --target native --deny-warn`, `moon test --deny-warn`.
- [ ] Run native CLI smoke and benchmark where the local C compiler supports it; record any local-only native limitation without weakening CI.
- [ ] Run `python scripts/check_repo_compliance.py`, `git diff --check`, forbidden-name scan, tracked-artifact scan, and source/test line count.
- [ ] Verify both worktrees are clean after local commits, with no remote push or Mooncakes publication performed.

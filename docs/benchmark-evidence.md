# Deterministic Benchmark Evidence

MoonTemplate includes a small, checked-in workload catalog rather than
publishing machine-specific timing claims. `benchmark_cases()` defines 14
readable cases and `run_benchmark_suite()` executes them through the same
bounded renderer used by applications.

| Category | Evidence |
| --- | --- |
| Basic/web | greeting, product-card |
| Documentation | release-notes, markdown-heading |
| Data/operations | csv-row, audit-log |
| Composition/control flow | semicolon-list, conditional-banner |
| Security | secure-output with HTML escaping |
| Unicode/i18n | localization-cn, unicode-slice |
| Boundaries | empty-values, short-summary |
| Stress | dense-catalog with iteration budget |

Every result checks exact output and records `output_chars`, `expected_chars`,
`nodes_visited`, `iterations`, `unicode_chars`, and `missing_variables`.
`benchmark_report_json(results)` emits stable JSON without timestamps or host
paths, making it suitable for a CI artifact or an acceptance screenshot.

Run the library evidence locally:

```bash
moon test --deny-warn
```

Run the native CLI timing baseline when a C compiler is available:

```bash
bash scripts/benchmark.sh 10
# Windows PowerShell:
pwsh scripts/benchmark.ps1 10
```

The timing script is an end-to-end smoke baseline only. It must not be used to
compare different hosts or to imply a universal latency guarantee.

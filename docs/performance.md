# Boundary and Performance Notes

## Boundary coverage

The test suite covers empty contexts, missing variables, empty iterables,
whitespace-only iterable entries, false conditions, filter pipelines, missing
`endif`/`endfor` terminators, a filter pipe without a filter name, escaping and
slug normalization, and invalid CLI input combinations. These cases protect
the parser, renderer, CLI, diagnostics, and command line boundary behavior most
likely to change during feature work. This includes malformed filter arguments,
Unicode truncation, comments, whitespace control, and strict unknown-filter
handling.

Run the complete checks with:

```bash
moon test --deny-warn
moon test --deny-warn --enable-coverage
moon coverage report -f summary
moon coverage analyze
```

The repository currently contains 54 library, diagnostic, inspection, bounded
render, filter, CLI, and benchmark tests; CLI tests are also compiled in the
native package. Coverage is reported by CI and recorded as a summary rather than
used as a brittle threshold while the parser is still growing.

## Performance model and reproducibility

The renderer walks the parsed AST once. For a template with `n` nodes and
`m` comma-separated loop items, rendering is `O(n + m * b)`, where `b` is the
number of nodes in the loop body. A loop copies the context for each item, so
its memory cost is proportional to the context size and loop nesting.

The native CLI smoke test in both CI workflows confirms that the production
path can compile and execute with the runner's C toolchain. For a reproducible
end-to-end native benchmark, run the tracked workload after installing a native
C compiler:

```bash
bash scripts/benchmark.sh 10
```

The workload renders `examples/benchmark.txt`, which exercises file loading,
filters, conditionals, loops, whitespace trimming, and seven realistic template
items. CI runs ten iterations and records the toolchain, runner, total time, and
average time in its job log. Use `scripts/benchmark.ps1 10` for the equivalent
Windows command. This keeps performance claims reproducible and tied to a
stated MoonBit toolchain and host instead of publishing a non-comparable local
timing.

The library benchmark catalog runs 14 deterministic cases directly through the
engine. It verifies exact output for product cards, release notes, localization,
CSV rows, logs, Markdown, secure output, empty values, dense loops, Unicode
slicing, truncation, and conditionals. Each result records output characters,
expected characters, visited nodes, loop iterations, Unicode characters, and
missing variables. `benchmark_report_json` emits these fields without timestamps
or host-specific values, so CI artifacts remain diffable.

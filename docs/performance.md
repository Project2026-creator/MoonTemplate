# Boundary and Performance Notes

## Boundary coverage

The test suite covers empty contexts, missing variables, empty iterables,
whitespace-only iterable entries, false conditions, filter pipelines, missing
`endif`/`endfor` terminators, a filter pipe without a filter name, escaping and
slug normalization, and invalid CLI input combinations. These cases protect
the parser, renderer, and command line boundary behavior most likely to change
during feature work.

Run the complete checks with:

```bash
moon test --deny-warn
moon test --deny-warn --enable-coverage
moon coverage report -f summary
moon coverage analyze
```

The current non-native validation run reports 16 passing tests and 225/254 covered lines
(88.6%) for the implementation packages. Coverage is reported by the CI jobs
but is not used as a brittle minimum threshold while the parser is still
growing.

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

# Boundary and Performance Notes

## Boundary coverage

The test suite covers empty contexts, missing variables, empty iterables,
whitespace-only iterable entries, false conditions, filter pipelines, missing
`endif`/`endfor` terminators, and a filter pipe without a filter name. These
cases protect the parser and renderer behavior at the edges most likely to
change during feature work.

Run the complete checks with:

```bash
moon test --deny-warn
moon test --deny-warn --enable-coverage
moon coverage report -f summary
moon coverage analyze
```

The current validation run reports 16 passing tests and 225/254 covered lines
(88.6%) for the implementation packages. Coverage is reported by the CI jobs
but is not used as a brittle minimum threshold while the parser is still
growing.

## Performance model and reproducibility

The renderer walks the parsed AST once. For a template with `n` nodes and
`m` comma-separated loop items, rendering is `O(n + m * b)`, where `b` is the
number of nodes in the loop body. A loop copies the context for each item, so
its memory cost is proportional to the context size and loop nesting.

The native CLI smoke test in both CI workflows confirms that the production
path can compile and execute with the runner's C toolchain. For a machine-level
benchmark, run the following after installing a native C compiler and record
the command output with the toolchain version:

```bash
time moon run src/cli --target native -- \
  --template '{{ name | trim | uppercase }}' --var name=' MoonBit '
```

This keeps performance claims reproducible and tied to a stated MoonBit
toolchain and host instead of publishing a non-comparable local timing.

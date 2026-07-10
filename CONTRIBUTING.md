# Contributing to MoonTemplate

MoonTemplate is maintained as a competition-quality MoonBit library, so every change should keep the public repository easy to review, test, and accept.

1. Fork the repository and branch from `main`.
2. Add or update tests whenever parser, engine, CLI, or docs behavior changes.
3. Run the local acceptance gate before opening a pull request:
   `moon fmt --check`
   `moon info`
   `moon check --deny-warn`
   `moon test --deny-warn`
4. If you change exported APIs, commit the refreshed [`pkg.generated.mbti`](src/moontemplate/pkg.generated.mbti).
5. Keep `_build/`, local binaries, and ad hoc output files out of version control.
6. Open a pull request with a short summary, test evidence, and any compatibility notes.

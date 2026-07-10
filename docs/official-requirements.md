# OSC2026 Official Requirements Notes

Verified on July 10, 2026 against:

- <https://moonbitlang.github.io/OSC2026/>
- <https://www.gitlink.org.cn/competitions/track1_2026MoonBit>
- the public site source shipped from the official OSC2026 site bundle

## Acceptance-facing signals explicitly visible in the official source

- The repository must be public.
- MoonBit must be the primary implementation language.
- The project should provide a clear `README`.
- The repository should expose source code, commit history, and an OSI-approved license.
- Acceptance checks look at public repository data, `README`, CI, tests, license, and commit history.
- The project should provide runnable examples or a minimal demo path.
- `mooncakes.io` publication is part of the acceptance expectation.
- If the project is original, ported, or references existing open source, the source relationship and license scope must be documented clearly.
- Continued-maintenance projects can participate, but only work after April 29, 2026 counts toward this contest cycle.

## What this means for MoonTemplate

- The repo must stay clean and reviewable without relying on private files.
- CI cannot stop at `build/test`; it needs explicit formatting, API generation, strict warning checks, and tests.
- Generated build caches must not be committed.
- The submission material and README must match the actual codebase.
- Source attribution must be documented even for an original project, because the official rules explicitly ask participants to explain upstream relationships and licenses.

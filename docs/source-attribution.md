# Source Attribution

## Project origin

MoonTemplate is an original MoonBit project created for the OSC2026 competition track. The parser, lexer, AST design, rendering flow, tests, CLI entry point, CI configuration, and repository engineering assets in this repository are maintained directly in this repo.

## What this project is not

- It is not a direct port of an existing Rust, Go, Python, JavaScript, or OCaml template engine.
- It does not vendor third-party template-engine source files into the repository.
- It does not include private, closed-source, or commercially licensed code.

## External dependencies and references

- MoonBit toolchain and standard ecosystem packages used through normal package imports.
- `moonbitlang/async` is used for the native CLI package to access file-system support.
- The repository follows the competition's public-development and acceptance expectations documented by the official OSC2026 site and GitLink competition page.

## License scope

This repository is released under Apache 2.0. External package dependencies keep their own upstream licenses and are not copied into this source tree as local vendored code.

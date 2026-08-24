# Source Attribution

## Project origin

MoonTemplate is an original MoonBit project created for the August MoonBit Hackathon. The parser, lexer, AST design, rendering flow, tests, CLI entry point, CI configuration, and repository engineering assets in this repository are maintained directly in this repo.

## What this project is not

- It is not a direct port of an existing Rust, Go, Python, JavaScript, or OCaml template engine.
- It does not vendor third-party template-engine source files into the repository.
- It does not include private, closed-source, or commercially licensed code.

## External dependencies and references

- MoonBit toolchain and standard ecosystem packages used through normal package imports.
- `moonbitlang/async` is used for the native CLI package to access file-system support.
- The repository follows standard open-source development practices and documents its external dependencies and license scope explicitly.

## License scope

This repository is released under Apache 2.0. External package dependencies keep their own upstream licenses and are not copied into this source tree as local vendored code.

<div align="center">
  <h1>馃寱 MoonTemplate</h1>
  <p>A lightweight, flexible, and extensible text template engine designed exclusively for <b>MoonBit</b>.</p>
</div>

## 馃摉 Introduction
MoonTemplate is a highly extensible text templating engine built from scratch in MoonBit. It provides developers with a robust tool to generate dynamic content, ranging from HTML pages and emails to source code generation.

## 鉁?Key Features
- **馃殌 Zero Dependencies**: Pure MoonBit implementation.
- **馃洝锔?Robust Parsing**: Custom-built Lexer and AST (Abstract Syntax Tree) Parser ensuring safety and speed.
- **馃挕 Variable Interpolation**: Easily inject data into templates using {{ variable }}.
- **馃攢 Control Flow (If/Else)**: Conditional rendering logic with {% if cond %}.
- **馃攧 Iteration (For Loops)**: Support for rendering lists and arrays using {% for item in iterable %}.
- **馃毎 Filter System**: Extensible architecture via pipes {{ name | uppercase }}.
- **馃捇 CLI Ready**: Includes a scaffolding for a Command Line Interface.

## 馃摝 Architecture
MoonTemplate is divided into 4 core modules to maintain high cohesion and low coupling:
1. lexer: Tokenizes the raw template string into a stream of semantic tokens.
2. parser: Consumes the token stream to build an Abstract Syntax Tree (AST).
3. st: Defines the node structures (Text, Variable, If, For).
4. engine: The rendering runtime that traverses the AST and interpolates context data.

## 馃殌 Quick Start
### 1. Basic Variable Rendering
`moonbit
let template = "Hello, {{ user }}! Welcome to MoonBit."
let engine = Engine::new(template).unwrap()
let ctx = Map::new()
ctx.set("user", "Hero001")

let output = engine.render(ctx)
println(output) // Hello, Hero001! Welcome to MoonBit.
`

### 2. Using Conditionals
`moonbit
let template = "{% if is_admin %}Admin Panel{% endif %}"
let engine = Engine::new(template).unwrap()
let ctx = Map::new()
ctx.set("is_admin", "true")
println(engine.render(ctx)) // Admin Panel
`

### 3. Filters
`moonbit
let template = "Current status: {{ status | uppercase }}"
let engine = Engine::new(template).unwrap()
engine.register_filter("uppercase", fn(s) { s.to_upper() })
// ... render with ctx
`

## 馃洜锔?CLI Usage
MoonTemplate includes a CLI tool for rendering templates directly from your terminal.
`ash
moon run src/cli -- template.txt
`

## 馃 Contributing
Please see CONTRIBUTING.md for details on how to contribute, build, and test the project.

## 馃搫 License
This project is licensed under the Apache 2.0 License - see the LICENSE file for details.

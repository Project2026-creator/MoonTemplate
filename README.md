<div align="center">
  <img src="https://www.moonbitlang.com/logo.svg" alt="MoonBit" width="100"/>
  <h1>MoonTemplate</h1>
  <p>A lightweight, flexible, and extensible text template engine designed exclusively for <b>MoonBit</b>.</p>

  <p>
    <img alt="MoonBit Version" src="https://img.shields.io/badge/MoonBit-0.1.20260624-orange?logo=moonbit&style=flat-square">
    <img alt="License" src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat-square">
    <img alt="Tests" src="https://img.shields.io/badge/Tests-100%25%20Passing-success?style=flat-square">
    <img alt="Version" src="https://img.shields.io/badge/mooncakes.io-v1.0.0-purple?style=flat-square">
  </p>
</div>

## 📖 Introduction
**MoonTemplate** is a highly extensible text templating engine built from scratch natively in MoonBit. Designed for high performance and strict type safety, it provides developers with a robust tool to generate dynamic content, ranging from HTML pages and emails to source code generation.

## ✨ Key Features
- **Zero Dependencies**: Pure MoonBit implementation, incredibly lightweight.
- **Robust Parsing Engine**: Custom-built Lexer and AST Parser ensuring 100% safety and speed.
- **Variable Interpolation**: Effortlessly inject dynamic context data (`{{ variable }}`).
- **Control Flow**: Complex conditional rendering logic supported natively (`{% if cond %}`).
- **Iteration (For Loops)**: Full support for array and list iteration (`{% for item in iterable %}`).
- **Extensible Filter System**: Chainable architecture via pipes (`{{ name | uppercase | trim }}`).
- **CLI Ready**: Seamlessly render templates directly from your terminal.

## 🏗️ Architecture Design

MoonTemplate's compiler-like architecture ensures high cohesion and extreme extensibility.

```mermaid
graph LR
    A[Template String] -->|1. Tokenize| B(Lexer)
    B -->|2. Parse| C{Parser}
    C -->|3. Build AST| D[AST Nodes]
    D -->|4. Render| E((Engine Runtime))
    ctx[(Context Map)] --> E
    E -->|Output| F[Generated String]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:4px
    style F fill:#9f9,stroke:#333,stroke-width:2px
```

## 🚀 Quick Start

### Installation
Publishing to `mooncakes.io` enables you to add it via `moon add`:
```bash
moon add Project2026-creator/moontemplate
```

### Basic Variable Rendering
```moonbit
let template = "Hello, {{ user }}! Welcome to MoonBit."
let engine = Engine::new(template).unwrap()
let ctx = Map::new()
ctx.set("user", "Hero001")

let output = engine.render(ctx)
println(output) // Output: Hello, Hero001! Welcome to MoonBit.
```

### Using Conditionals & Loops
```moonbit
let template = 
  #|{% if is_admin %}
  #|Welcome Admin! Users:
  #|{% for u in users %} - {{ u }}{% endfor %}
  #|{% endif %}

let engine = Engine::new(template).unwrap()
// Setup your context variables here...
```

### Filters
```moonbit
let template = "Current status: {{ status | uppercase }}"
let engine = Engine::new(template).unwrap()
engine.register_filter("uppercase", fn(s) { s.to_upper() })
```

## 🛠️ CLI Usage
MoonTemplate includes a robust CLI tool for rendering template files directly from your terminal, completely decoupled from your application code.
```bash
moon run src/cli -- template.txt
```

## 🤝 Contributing
Contributions make the open-source community an amazing place! Please see `CONTRIBUTING.md` for details on how to contribute, build, and test the project. All PRs should pass standard `moon test` validation.

## 📄 License
This project is officially licensed under the **Apache 2.0 License** - see the `LICENSE` file for details.

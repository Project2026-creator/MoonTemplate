# MoonTemplate

MoonTemplate is a lightweight, flexible, and extensible text template engine designed for the MoonBit language.

## Features
- **Variable Interpolation**: Easily inject variables `{{ name }}`
- **Control Flow**: Conditionals support `{% if cond %} ... {% endif %}`
- **Extensible Filters**: Custom text transformation logic
- **Robust Parsing**: Hand-written Lexer and Parser for MoonBit AST

## Usage
```moonbit
let template = "Hello {{ name }}!"
let engine = Engine::new(template).unwrap()

let ctx = Map::new()
ctx.set("name", "World")

let result = engine.render(ctx)
println(result)
```

## License
Apache-2.0

# MoonTemplate API

The core API for MoonTemplate involves creating an `Engine` and calling `render`.

```moonbit
let engine = Engine::new("template string").unwrap()
let ctx = Map::new()
let result = engine.render(ctx)
```

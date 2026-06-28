
test "engine render variable" {
  let engine = Engine::new("Hello, {{ user }}!").unwrap()
  let ctx = Map::new()
  ctx.set("user", "MoonBit")
  let result = engine.render(ctx)
  assert_eq!(result, "Hello, MoonBit!")
}

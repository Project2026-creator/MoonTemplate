///|
test "built-in filters escape markup and JSON strings" {
  let engine = Engine::new(
    "{{ value | escape_html }}|{{ value | escape_json }}",
  ).unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("value", "<MoonBit & \"templates\">")
  assert_eq(
    engine.render(ctx),
    "&lt;MoonBit &amp; &quot;templates&quot;&gt;|\"<MoonBit & \\\"templates\\\">\"",
  )
}

///|
test "slugify normalizes separators and casing" {
  let engine = Engine::new("{{ title | slugify }}").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("title", "  MoonBit -- Template Engine! ")
  assert_eq(engine.render(ctx), "moonbit-template-engine")
}

///|
test "built-in filters preserve empty values" {
  let engine = Engine::new(
    "{{ missing | escape_html }}{{ missing | escape_json }}{{ missing | slugify }}",
  ).unwrap()
  let ctx : Map[String, String] = Map([])
  assert_eq(engine.render(ctx), "\"\"")
}

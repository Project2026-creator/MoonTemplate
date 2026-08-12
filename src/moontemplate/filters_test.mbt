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

///|
test "text utility filters support Unicode and whitespace" {
  let engine = Engine::new(
    "{{ title | length }}|{{ messy | collapse_whitespace }}|{{ title | capitalize }}|{{ body | newline_to_br }}",
  ).unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("title", "月亮模板")
  ctx.set("messy", "  MoonBit\n\tTemplate  ")
  ctx.set("body", "one\ntwo")
  assert_eq(engine.render(ctx), "4|MoonBit Template|月亮模板|one<br>two")
}

///|
test "parameterized prefix suffix and padding filters" {
  let engine = Engine::new(
    "{{ id | prefix(\"ID-\") }}|{{ id | suffix(\"-ok\") }}|{{ id | pad_left(5, \"0\") }}|{{ id | pad_right(5, \".\") }}",
  ).unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("id", "42")
  assert_eq(engine.render(ctx), "ID-42|42-ok|00042|42...")
}

///|
test "slice filter uses Unicode character indexes" {
  let engine = Engine::new("{{ value | slice(1, 2) }}").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("value", "模板引擎")
  assert_eq(engine.render(ctx), "板引")
}

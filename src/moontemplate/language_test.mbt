///|
test "comments disappear without changing surrounding text" {
  let engine = Engine::new("Hello {# secret #}{{ name }}!").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("name", "MoonBit")
  assert_eq(engine.render(ctx), "Hello MoonBit!")
}

///|
test "variable trim markers remove adjacent ASCII whitespace" {
  let engine = Engine::new("A  {{- name -}}  B").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("name", "MoonBit")
  assert_eq(engine.render(ctx), "AMoonBitB")
}

///|
test "block trim markers preserve meaningful body text" {
  let engine = Engine::new("A \n{%- if show -%}\n yes\n{%- endif -%}\nB").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("show", "true")
  assert_eq(engine.render(ctx), "AyesB")
}

///|
test "replace filter accepts quoted arguments" {
  let engine = Engine::new("{{ name | replace(\"Moon\",\"Bit\") }}").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("name", "MoonTemplate")
  assert_eq(engine.render(ctx), "BitTemplate")
}

///|
test "truncate filter uses a Unicode character limit" {
  let engine = Engine::new("{{ value | truncate(5) }}").unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("value", "MoonBitTemplate")
  assert_eq(engine.render(ctx), "MoonB")
}

///|
test "default filter handles missing and blank values" {
  let engine = Engine::new(
    "{{ missing | default(\"fallback\") }}|{{ blank | default(\"fallback\") }}",
  ).unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("blank", "   ")
  assert_eq(engine.render(ctx), "fallback|fallback")
}

///|
test "nested control flow remains compatible" {
  let engine = Engine::new(
    "{% if outer %}{% if inner %}yes{% else %}inner-no{% endif %}{% else %}outer-no{% endif %}",
  ).unwrap()
  let ctx : Map[String, String] = Map([])
  ctx.set("outer", "true")
  ctx.set("inner", "true")
  assert_eq(engine.render(ctx), "yes")
}

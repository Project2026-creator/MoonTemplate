///|
test "full template rendering" {
  let tpl = "Hello, {{ user | trim }}! {% if admin %}You are an admin.{% else %}You are a guest.{% endif %}"
  let engine = Engine::new(tpl).unwrap()

  let ctx1 = Map([], capacity=2)
  ctx1.set("user", " Alice ")
  ctx1.set("admin", "true")
  assert_eq(engine.render(ctx1), "Hello, Alice! You are an admin.")

  let ctx2 = Map([], capacity=2)
  ctx2.set("user", "Bob")
  ctx2.set("admin", "false")
  assert_eq(engine.render(ctx2), "Hello, Bob! You are a guest.")
}

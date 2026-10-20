///|
test "engine render variable" {
  match @moontemplate.Engine::new("Hello, {{ user }}!") {
    Ok(engine) => {
      let ctx : Map[String, String] = Map([])
      ctx.set("user", "MoonBit")
      let result = engine.render(ctx)
      assert_eq(result, "Hello, MoonBit!")
    }
    Err(_) => fail("Failed to parse template")
  }
}

///|
test "engine render if condition" {
  match
    @moontemplate.Engine::new(
      "Start {% if show %}VISIBLE{% else %}HIDDEN{% endif %} End",
    ) {
    Ok(engine) => {
      let ctx : Map[String, String] = Map([])
      ctx.set("show", "true")
      let result = engine.render(ctx)
      assert_eq(result, "Start VISIBLE End")
    }
    Err(_) => fail("Failed to parse template")
  }
}

///|
test "engine render for loop" {
  match
    @moontemplate.Engine::new(
      "Items: {% for item in list %}{{ item }} {% endfor %}",
    ) {
    Ok(engine) => {
      let ctx : Map[String, String] = Map([])
      ctx.set("list", "apple, banana, cherry")
      let result = engine.render(ctx)
      assert_eq(result, "Items: apple banana cherry ")
    }
    Err(_) => fail("Failed to parse template")
  }
}

///|
test "engine render filter pipeline and custom filters" {
  match
    @moontemplate.Engine::new("Hello, {{ user | trim | uppercase | suffix }}!") {
    Ok(engine) => {
      engine.register_filter("suffix", fn(value) { value + "!" })
      let ctx : Map[String, String] = Map([])
      ctx.set("user", "  MoonBit  ")
      let result = engine.render(ctx)
      assert_eq(result, "Hello, MOONBIT!!")
    }
    Err(_) => fail("Failed to parse template")
  }
}

///|
test "engine false branch and empty iterable" {
  match
    @moontemplate.Engine::new(
      "{% if show %}yes{% else %}no{% endif %} {% for item in list %}{{ item }}{% endfor %}",
    ) {
    Ok(engine) => {
      let ctx : Map[String, String] = Map([])
      ctx.set("show", "0")
      ctx.set("list", "   ")
      let result = engine.render(ctx)
      assert_eq(result, "no ")
    }
    Err(_) => fail("Failed to parse template")
  }
}

///|
test "engine missing variables render as empty" {
  let engine = @moontemplate.Engine::new("A{{ missing }}B").unwrap()
  let ctx : Map[String, String] = Map([])
  assert_eq(engine.render(ctx), "AB")
}

///|
test "engine filters preserve empty input" {
  let engine = @moontemplate.Engine::new("{{ missing | trim | uppercase }}").unwrap()
  let ctx : Map[String, String] = Map([])
  assert_eq(engine.render(ctx), "")
}

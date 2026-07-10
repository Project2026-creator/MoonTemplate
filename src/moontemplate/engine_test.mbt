///|
test "engine render variable" {
  match Engine::new("Hello, {{ user }}!") {
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
    Engine::new("Start {% if show %}VISIBLE{% else %}HIDDEN{% endif %} End") {
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
  match Engine::new("Items: {% for item in list %}{{ item }} {% endfor %}") {
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
  match Engine::new("Hello, {{ user | trim | uppercase | suffix }}!") {
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
    Engine::new(
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


test "engine render variable" {
  match Engine::new("Hello, {{ user }}!") {
    Ok(engine) => {
      let ctx : Map[String, String] = {}
      ctx.set("user", "MoonBit")
      let result = engine.render(ctx)
      assert_eq!(result, "Hello, MoonBit!")
    }
    Err(_) => fail!("Failed to parse template")
  }
}

test "engine render if condition" {
  match Engine::new("Start {% if show %}VISIBLE{% endif %} End") {
    Ok(engine) => {
      let ctx : Map[String, String] = {}
      ctx.set("show", "true")
      let result = engine.render(ctx)
      assert_eq!(result, "Start VISIBLE End")
    }
    Err(_) => fail!("Failed to parse template")
  }
}

test "engine render for loop" {
  match Engine::new("Items: {% for item in list %}{{ item }} {% endfor %}") {
    Ok(engine) => {
      let ctx : Map[String, String] = {}
      ctx.set("list", "apple,banana,cherry")
      let result = engine.render(ctx)
      assert_eq!(result, "Items: apple banana cherry ")
    }
    Err(_) => fail!("Failed to parse template")
  }
}

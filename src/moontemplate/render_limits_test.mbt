///|
test "bounded render returns output and useful metrics" {
  let engine = Engine::new(
    "Hi {{ name }} {% for item in items %}[{{ item }}]{% endfor %}",
  ).unwrap()
  let context : Map[String, String] = Map([])
  context.set("name", "MoonBit")
  context.set("items", "a,b,c")
  let limits = RenderLimits::new(100, 10, 4)
  let report = engine.render_with_limits(context, limits).unwrap()
  assert_eq(report.output(), "Hi MoonBit [a][b][c]")
  assert_eq(report.metrics().iterations(), 3)
  assert_eq(report.metrics().nodes_visited(), 13)
  assert_eq(report.metrics().variables_resolved(), 5)
  assert_eq(report.metrics().missing_variables(), 0)
  assert_eq(report.metrics().max_depth(), 1)
}

///|
test "bounded render counts Unicode output characters" {
  let engine = Engine::new("{{ title }}").unwrap()
  let context : Map[String, String] = Map([])
  context.set("title", "月亮")
  let report = engine.render_with_limits(context, RenderLimits::new(1, 1, 1))
  match report {
    Err(OutputLimitExceeded(limit, actual)) => {
      assert_eq(limit, 1)
      assert_eq(actual, 0)
    }
    Ok(_) => fail("Expected Unicode output limit")
    Err(_) => fail("Expected an output limit failure")
  }
}

///|
test "bounded render rejects excessive loop iterations" {
  let engine = Engine::new("{% for item in items %}{{ item }}{% endfor %}").unwrap()
  let context : Map[String, String] = Map([])
  context.set("items", "one,two,three")
  match engine.render_with_limits(context, RenderLimits::new(100, 2, 2)) {
    Err(IterationLimitExceeded(limit)) => assert_eq(limit, 2)
    Ok(_) => fail("Expected iteration limit")
    Err(_) => fail("Expected an iteration limit failure")
  }
}

///|
test "bounded render rejects excessive nesting" {
  let engine = Engine::new(
    "{% if outer %}{% if inner %}value{% endif %}{% endif %}",
  ).unwrap()
  let context : Map[String, String] = Map([])
  context.set("outer", "true")
  context.set("inner", "true")
  match engine.render_with_limits(context, RenderLimits::new(100, 2, 0)) {
    Err(DepthLimitExceeded(limit)) => assert_eq(limit, 0)
    Ok(_) => fail("Expected depth limit")
    Err(_) => fail("Expected a depth limit failure")
  }
}

///|
test "bounded render records missing variables without failing" {
  let engine = Engine::new("{{ present }}|{{ missing }}").unwrap()
  let context : Map[String, String] = Map([])
  context.set("present", "yes")
  let report = engine
    .render_with_limits(context, RenderLimits::new(100, 1, 1))
    .unwrap()
  assert_eq(report.output(), "yes|")
  assert_eq(report.metrics().variables_resolved(), 1)
  assert_eq(report.metrics().missing_variables(), 1)
}

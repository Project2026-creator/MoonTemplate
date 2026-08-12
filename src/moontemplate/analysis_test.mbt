///|
test "template stats describe nested rendering structure" {
  let engine = Engine::new(
    "Hello {{ name | trim }}{% if active %}Y{% else %}N{% endif %}{% for item in items %}{{ item }}{% endfor %}",
  ).unwrap()
  let stats = engine.stats()
  assert_eq(stats.node_count(), 7)
  assert_eq(stats.text_nodes(), 3)
  assert_eq(stats.variable_nodes(), 2)
  assert_eq(stats.if_nodes(), 1)
  assert_eq(stats.for_nodes(), 1)
  assert_eq(stats.filter_count(), 1)
  assert_eq(stats.max_depth(), 1)
  assert_eq(stats.literal_chars(), 8)
}

///|
test "template dependencies exclude loop locals" {
  let engine = Engine::new(
    "{{ title }}{% for item in items %}{{ item }}{% endfor %}",
  ).unwrap()
  let required = engine.required_variables()
  assert_eq(required.length(), 2)
  assert_eq(required[0], "title")
  assert_eq(required[1], "items")
  assert_true(engine.filter_names().length() == 0)
}

///|
test "lint reports unknown filters with stable code" {
  let issues = lint_template("{{ name | missing }}", ["trim"]).unwrap()
  assert_eq(issues.length(), 1)
  assert_true(issues[0].severity() == Warning)
  assert_eq(issues[0].code(), "TMPL_UNKNOWN_FILTER")
  assert_eq(issues[0].line(), 1)
  assert_true(issues[0].message().contains("missing"))
}

///|
test "lint reports empty templates as informational" {
  let issues = lint_template("", []).unwrap()
  assert_eq(issues.length(), 1)
  assert_true(issues[0].severity() == Info)
  assert_eq(issues[0].code(), "TMPL_EMPTY_TEMPLATE")
}

///|
test "lint preserves parser diagnostics for malformed templates" {
  match lint_template("{% if enabled %}unfinished", []) {
    Err(diagnostics) => assert_true(diagnostics[0].kind() == Syntax)
    Ok(_) => fail("Expected malformed template diagnostics")
  }
}

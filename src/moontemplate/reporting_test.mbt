///|
test "reporting renders stable operator output" {
  assert_eq(report_status("ci", true), "[ci: PASS]")
  assert_true(
    report_checks([("fmt", true), ("test", false)]).contains("[test: FAIL]"),
  )
  assert_true(report_counts([("a", 1)]).contains("| a | 1 |"))
  assert_true(report_key_value("version", "1.0").contains("1.0"))
}

///|
test "report engine dependencies and filters" {
  let engine = Engine::new("{{ name | trim }}").unwrap()
  assert_true(report_engine(engine).contains("variables"))
  assert_true(report_template_dependencies(engine).contains("name"))
  assert_true(report_template_filters(engine).contains("trim"))
}

///|
test "report security schema and audit" {
  let registry = TemplateRegistry::new(1)
  let _ = registry.register("a", "A")
  assert_true(report_audit(registry).contains("PASS"))
  assert_true(
    report_security(SecurityPolicy::default(), "{{ x }}").contains("PASS"),
  )
  assert_true(
    report_schema(ContextSchema::new().require("x"), Context::new()).contains(
      "Missing",
    ),
  )
}

///|
test "report locale and diff" {
  let catalog = LocaleCatalog::new("en").add(
    "en",
    Context::new().set("title", "Hello"),
  )
  assert_true(report_locale_fallback(catalog, "fr").contains("Hello"))
  let lines = report_diff_lines(
    Context::new().set("a", "1"),
    Context::new().set("a", "2"),
  )
  assert_eq(lines.length(), 1)
  assert_true(lines[0].contains("a"))
  assert_true(report_file_name("a/b").contains("a_b"))
}

///|
test "reporting renders stable operator output" {
  assert_eq(@moontemplate.report_status("ci", true), "[ci: PASS]")
  assert_true(
    @moontemplate.report_checks([("fmt", true), ("test", false)]).contains(
      "[test: FAIL]",
    ),
  )
  assert_true(@moontemplate.report_counts([("a", 1)]).contains("| a | 1 |"))
  assert_true(@moontemplate.report_key_value("version", "1.0").contains("1.0"))
}

///|
test "report engine dependencies and filters" {
  let engine = @moontemplate.Engine::new("{{ name | trim }}").unwrap()
  assert_true(@moontemplate.report_engine(engine).contains("variables"))
  assert_true(
    @moontemplate.report_template_dependencies(engine).contains("name"),
  )
  assert_true(@moontemplate.report_template_filters(engine).contains("trim"))
}

///|
test "report security schema and audit" {
  let registry = @moontemplate.TemplateRegistry::new(1)
  let _ = registry.register("a", "A")
  assert_true(@moontemplate.report_audit(registry).contains("PASS"))
  assert_true(
    @moontemplate.report_security(
      @moontemplate.SecurityPolicy::default(),
      "{{ x }}",
    ).contains("PASS"),
  )
  assert_true(
    @moontemplate.report_schema(
      @moontemplate.ContextSchema::new().require("x"),
      @moontemplate.Context::new(),
    ).contains("Missing"),
  )
}

///|
test "report locale and diff" {
  let catalog = @moontemplate.LocaleCatalog::new("en").add(
    "en",
    @moontemplate.Context::new().set("title", "Hello"),
  )
  assert_true(
    @moontemplate.report_locale_fallback(catalog, "fr").contains("Hello"),
  )
  let lines = @moontemplate.report_diff_lines(
    @moontemplate.Context::new().set("a", "1"),
    @moontemplate.Context::new().set("a", "2"),
  )
  assert_eq(lines.length(), 1)
  assert_true(lines[0].contains("a"))
  assert_true(@moontemplate.report_file_name("a/b").contains("a_b"))
}

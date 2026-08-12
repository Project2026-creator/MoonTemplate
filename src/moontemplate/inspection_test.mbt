///|
test "template inspection combines structure dependencies filters and lint" {
  let inspection = inspect_template(
    "Hello {{ name | trim }}{% if enabled %}Y{% endif %}",
    ["trim"],
  ).unwrap()
  assert_eq(inspection.stats().node_count(), 4)
  let required = inspection.required_variables()
  assert_eq(required.length(), 2)
  assert_eq(required[0], "name")
  assert_eq(required[1], "enabled")
  let filters = inspection.filter_names()
  assert_eq(filters.length(), 1)
  assert_eq(filters[0], "trim")
  assert_true(inspection.is_clean())
}

///|
test "template inspection preserves unknown filter warnings" {
  let inspection = inspect_template("{{ name | custom }}", ["trim"]).unwrap()
  assert_true(!inspection.is_clean())
  assert_eq(inspection.lint_issues().length(), 1)
  assert_eq(inspection.lint_issues()[0].code(), "TMPL_UNKNOWN_FILTER")
}

///|
test "context audit reports missing and unused keys" {
  let engine = Engine::new("{{ title }}{% if active %}yes{% endif %}").unwrap()
  let context : Map[String, String] = Map([])
  context.set("title", "MoonTemplate")
  context.set("unused", "diagnostic")
  let audit = engine.audit_context(context)
  assert_eq(audit.missing().length(), 1)
  assert_eq(audit.missing()[0], "active")
  assert_eq(audit.unused().length(), 1)
  assert_eq(audit.unused()[0], "unused")
  assert_eq(audit.provided_count(), 2)
}

///|
test "context audit is empty for an exact context" {
  let engine = Engine::new(
    "{{ title }}{% for item in items %}{{ item }}{% endfor %}",
  ).unwrap()
  let context : Map[String, String] = Map([])
  context.set("title", "MoonTemplate")
  context.set("items", "one,two")
  let audit = engine.audit_context(context)
  assert_eq(audit.missing().length(), 0)
  assert_eq(audit.unused().length(), 0)
  assert_eq(audit.provided_count(), 2)
}

///|
test "inspection returns parser diagnostics instead of partial metadata" {
  match inspect_template("{% for item in items %}unfinished", []) {
    Err(diagnostics) => assert_true(diagnostics[0].kind() == Syntax)
    Ok(_) => fail("Expected inspection to reject malformed templates")
  }
}

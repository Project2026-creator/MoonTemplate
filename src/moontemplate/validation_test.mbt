///|
test "validation reports missing context and valid renders" {
  let engine = @moontemplate.Engine::new("Hello {{ name }}").unwrap()
  let invalid = @moontemplate.validate_engine(
    engine,
    @moontemplate.Context::new(),
  )
  assert_false(invalid.valid())
  assert_true(invalid.errors()[0].contains("name"))
  let valid = @moontemplate.validate_engine(
    engine,
    @moontemplate.Context::new().set("name", "Moon"),
  )
  assert_true(valid.valid())
}

///|
test "validation reports syntax failures" {
  let report = @moontemplate.validate_source(
    "{% if",
    @moontemplate.Context::new(),
  )
  assert_false(report.valid())
  assert_true(report.errors().length() > 0)
  assert_true(report.errors()[0].contains("TMPL"))
}

///|
test "bundle validation summary" {
  let bundle = @moontemplate.bundle_from_pairs([("a", "A"), ("b", "{{ x }}")]).unwrap()
  let reports = @moontemplate.validate_bundle(
    bundle,
    @moontemplate.Context::new(),
  )
  assert_eq(reports.length(), 2)
  assert_true(@moontemplate.validation_summary(reports).contains("invalid=1"))
}

///|
test "validation identifiers and uniqueness" {
  assert_eq(@moontemplate.validate_identifier_list(["ok", "2bad", "also-ok"]), [
    "2bad",
  ])
  assert_eq(
    @moontemplate.validate_unique_names(["a", "b", "a", "a", "c", "b"]),
    ["a", "b"],
  )
}

///|
test "validation limits and safe source" {
  assert_eq(
    @moontemplate.validate_limits(@moontemplate.RenderLimits::new(0, 2, 0)),
    ["Output limit is zero", "Depth limit is zero"],
  )
  assert_eq(
    @moontemplate.assert_safe_source(
      @moontemplate.SecurityPolicy::default(),
      "{{ name }}",
    ),
    Ok(()),
  )
  match
    @moontemplate.assert_safe_source(
      @moontemplate.SecurityPolicy::default(),
      "{{ name | nope }}",
    ) {
    Ok(_) => fail("expected policy rejection")
    Err(message) => assert_true(message.contains("TMPL_FILTER"))
  }
}

///|
test "validation report counters" {
  let report = @moontemplate.ValidationReport::new()
    .info("i")
    .warning("w")
    .error("e")
  assert_eq(report.total(), 3)
  assert_eq(report.infos(), ["i"])
  assert_eq(report.warnings(), ["w"])
  assert_eq(report.errors(), ["e"])
}

///|
test "required context validation accepts map input" {
  let engine = @moontemplate.Engine::new("{{ x }}").unwrap()
  assert_true(
    @moontemplate.validate_required_context(
      engine,
      Map([("x", "1")], capacity=1),
    ),
  )
  assert_false(
    @moontemplate.validate_required_context(engine, Map([], capacity=0)),
  )
}

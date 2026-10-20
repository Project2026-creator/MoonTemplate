///|
test "schema requires and defaults" {
  let schema = @moontemplate.ContextSchema::new()
    .require("name")
    .require("version")
    .default_value("version", "1")
    .require_non_empty("name")
  let valid = @moontemplate.Context::new().set("name", "Moon")
  assert_true(schema.accepts(valid))
  assert_eq(schema.validate(@moontemplate.Context::new()), [
    "Missing key: name", "Empty key: name",
  ])
  let filled = schema.apply_defaults(@moontemplate.Context::new())
  assert_eq(filled.get_or("version", ""), "1")
}

///|
test "schema from engine and report" {
  let engine = @moontemplate.Engine::new("{{ user }} {{ count }}").unwrap()
  let schema = @moontemplate.schema_for_engine(engine)
  assert_eq(schema.required(), ["user", "count"])
  assert_true(
    @moontemplate.schema_report(schema, @moontemplate.Context::new()).contains(
      "Missing key",
    ),
  )
}

///|
test "localization fallback chain" {
  let catalog = @moontemplate.LocaleCatalog::new("en")
    .add("en", @moontemplate.Context::new().set("hello", "Hello"))
    .add("zh", @moontemplate.Context::new().set("hello", "你好"))
  assert_eq(catalog.translate("zh", "hello", "?"), "你好")
  assert_eq(catalog.translate("fr", "hello", "?"), "Hello")
  assert_eq(@moontemplate.locale_chain("zh-CN"), ["zh-CN", "zh"])
  assert_eq(catalog.locales(), ["en", "zh"])
}

///|
test "localized render merges locale then request values" {
  let engine = @moontemplate.Engine::new("{{ greeting }} {{ name }}").unwrap()
  let catalog = @moontemplate.LocaleCatalog::new("en").add(
    "en",
    @moontemplate.Context::new().set("greeting", "Hi"),
  )
  let output = @moontemplate.localized_render(
    engine,
    catalog,
    "en",
    @moontemplate.Context::new().set("name", "Moon"),
  )
  assert_eq(output, "Hi Moon")
}

///|
test "summary and diagnostic formatting" {
  let engine = @moontemplate.Engine::new("{{ name }}").unwrap()
  let limits = @moontemplate.RenderLimits::new(20, 10, 4)
  let report = engine
    .render_with_limits(
      @moontemplate.Context::new().set("name", "ok").to_map(),
      limits,
    )
    .unwrap()
  let summary = @moontemplate.RenderSummary::new().record_success(report)
  assert_eq(summary.successful(), 1)
  assert_eq(summary.success_rate(), "100%")
  assert_true(@moontemplate.summary_json(summary).contains("successful"))
  let diagnostics = match @moontemplate.Engine::new_with_diagnostics("{{") {
    Ok(_) => []
    Err(errors) => errors
  }
  assert_true(@moontemplate.diagnostics_text(diagnostics).contains("TMPL"))
  assert_true(@moontemplate.diagnostic_summary(diagnostics).contains("syntax"))
}

///|
test "render plans validate and describe" {
  let bundle = @moontemplate.bundle_from_pairs([("a", "A {{ x }}")]).unwrap()
  let plan = @moontemplate.plan_from_names(["a", "missing"])
  assert_eq(@moontemplate.plan_validate(plan, bundle), ["missing"])
  assert_eq(@moontemplate.plan_required_variables(plan, bundle), ["x"])
  assert_true(plan.describe().contains("templates"))
}

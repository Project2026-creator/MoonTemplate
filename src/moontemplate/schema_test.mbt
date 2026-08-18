///|
test "schema requires and defaults" {
  let schema = ContextSchema::new()
    .require("name")
    .require("version")
    .default_value("version", "1")
    .require_non_empty("name")
  let valid = Context::new().set("name", "Moon")
  assert_true(schema.accepts(valid))
  assert_eq(schema.validate(Context::new()), [
    "Missing key: name", "Empty key: name",
  ])
  let filled = schema.apply_defaults(Context::new())
  assert_eq(filled.get_or("version", ""), "1")
}

///|
test "schema from engine and report" {
  let engine = Engine::new("{{ user }} {{ count }}").unwrap()
  let schema = schema_for_engine(engine)
  assert_eq(schema.required(), ["user", "count"])
  assert_true(schema_report(schema, Context::new()).contains("Missing key"))
}

///|
test "localization fallback chain" {
  let catalog = LocaleCatalog::new("en")
    .add("en", Context::new().set("hello", "Hello"))
    .add("zh", Context::new().set("hello", "你好"))
  assert_eq(catalog.translate("zh", "hello", "?"), "你好")
  assert_eq(catalog.translate("fr", "hello", "?"), "Hello")
  assert_eq(locale_chain("zh-CN"), ["zh-CN", "zh"])
  assert_eq(catalog.locales(), ["en", "zh"])
}

///|
test "localized render merges locale then request values" {
  let engine = Engine::new("{{ greeting }} {{ name }}").unwrap()
  let catalog = LocaleCatalog::new("en").add(
    "en",
    Context::new().set("greeting", "Hi"),
  )
  let output = localized_render(
    engine,
    catalog,
    "en",
    Context::new().set("name", "Moon"),
  )
  assert_eq(output, "Hi Moon")
}

///|
test "summary and diagnostic formatting" {
  let engine = Engine::new("{{ name }}").unwrap()
  let limits = RenderLimits::new(20, 10, 4)
  let report = engine
    .render_with_limits(Context::new().set("name", "ok").to_map(), limits)
    .unwrap()
  let summary = RenderSummary::new().record_success(report)
  assert_eq(summary.successful(), 1)
  assert_eq(summary.success_rate(), "100%")
  assert_true(summary_json(summary).contains("successful"))
  let diagnostics = match Engine::new_with_diagnostics("{{") {
    Ok(_) => []
    Err(errors) => errors
  }
  assert_true(diagnostics_text(diagnostics).contains("TMPL"))
  assert_true(diagnostic_summary(diagnostics).contains("syntax"))
}

///|
test "render plans validate and describe" {
  let bundle = bundle_from_pairs([("a", "A {{ x }}")]).unwrap()
  let plan = plan_from_names(["a", "missing"])
  assert_eq(plan_validate(plan, bundle), ["missing"])
  assert_eq(plan_required_variables(plan, bundle), ["x"])
  assert_true(plan.describe().contains("templates"))
}

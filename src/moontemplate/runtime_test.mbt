///|
test "high level render helpers" {
  let context = Context::new().set("name", "Moon")
  assert_eq(render_string("Hi {{ name }}", context), Ok("Hi Moon"))
  let schema = ContextSchema::new().require("name")
  assert_eq(render_checked("Hi {{ name }}", context, schema), Ok("Hi Moon"))
  let outputs = render_many("{{ name }}", [
    context,
    Context::new().set("name", "Bit"),
  ]).unwrap()
  assert_eq(outputs, ["Moon", "Bit"])
}

///|
test "safe runtime applies policy and limits" {
  let context = Context::new().set("name", "ok")
  let report = render_safe(
    "{{ name }}",
    context,
    SecurityPolicy::default(),
    RenderLimits::default(),
  ).unwrap()
  assert_eq(report.output(), "ok")
  match
    render_safe(
      "{{ name | nope }}",
      context,
      SecurityPolicy::default(),
      RenderLimits::default(),
    ) {
    Ok(_) => fail("expected unsafe filter")
    Err(message) => assert_true(message.contains("TMPL_FILTER"))
  }
  match
    render_safe(
      "long",
      Context::new(),
      SecurityPolicy::default(),
      RenderLimits::new(1, 2, 2),
    ) {
    Ok(_) => fail("expected output limit")
    Err(message) => assert_true(message.contains("output"))
  }
}

///|
test "runtime inspection and dependencies" {
  assert_eq(source_dependencies("{{ name }}").unwrap(), ["name"])
  assert_eq(source_filters("{{ name | trim }}").unwrap(), ["trim"])
  assert_eq(inspect_source("hello").unwrap().literal_chars(), 5)
  assert_true(
    source_lint("{{ x | unknown }}").unwrap()[0].message().contains("Unknown"),
  )
  assert_true(runtime_capabilities().contains("batch-rendering"))
}

///|
test "runtime named rendering and batch limits" {
  let bundle = bundle_from_pairs([("a", "A {{ x }}")]).unwrap()
  let output = render_named(
    bundle,
    "a",
    Context::new().set("x", "1"),
    RenderPipeline::new(),
  ).unwrap()
  assert_eq(output, "A 1")
  let reports = render_many_with_limits(
    "{{ x }}",
    [Context::new().set("x", "a"), Context::new().set("x", "b")],
    RenderLimits::default(),
  )
  assert_eq(reports.length(), 2)
  assert_eq(reports[0].unwrap().output(), "a")
}

///|
test "runtime rejects empty template file names" {
  match render_template_file_name("", Context::new()) {
    Ok(_) => fail("expected empty name")
    Err(error) => assert_true(error.contains("empty"))
  }
  assert_true(
    render_template_file_name("welcome", Context::new())
    .unwrap()
    .contains("welcome"),
  )
}

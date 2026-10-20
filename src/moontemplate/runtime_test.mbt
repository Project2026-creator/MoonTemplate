///|
test "high level render helpers" {
  let context = @moontemplate.Context::new().set("name", "Moon")
  assert_eq(
    @moontemplate.render_string("Hi {{ name }}", context),
    Ok("Hi Moon"),
  )
  let schema = @moontemplate.ContextSchema::new().require("name")
  assert_eq(
    @moontemplate.render_checked("Hi {{ name }}", context, schema),
    Ok("Hi Moon"),
  )
  let outputs = @moontemplate.render_many("{{ name }}", [
    context,
    @moontemplate.Context::new().set("name", "Bit"),
  ]).unwrap()
  assert_eq(outputs, ["Moon", "Bit"])
}

///|
test "safe runtime applies policy and limits" {
  let context = @moontemplate.Context::new().set("name", "ok")
  let report = @moontemplate.render_safe(
    "{{ name }}",
    context,
    @moontemplate.SecurityPolicy::default(),
    @moontemplate.RenderLimits::default(),
  ).unwrap()
  assert_eq(report.output(), "ok")
  match
    @moontemplate.render_safe(
      "{{ name | nope }}",
      context,
      @moontemplate.SecurityPolicy::default(),
      @moontemplate.RenderLimits::default(),
    ) {
    Ok(_) => fail("expected unsafe filter")
    Err(message) => assert_true(message.contains("TMPL_FILTER"))
  }
  match
    @moontemplate.render_safe(
      "long",
      @moontemplate.Context::new(),
      @moontemplate.SecurityPolicy::default(),
      @moontemplate.RenderLimits::new(1, 2, 2),
    ) {
    Ok(_) => fail("expected output limit")
    Err(message) => assert_true(message.contains("output"))
  }
}

///|
test "runtime inspection and dependencies" {
  assert_eq(@moontemplate.source_dependencies("{{ name }}").unwrap(), ["name"])
  assert_eq(@moontemplate.source_filters("{{ name | trim }}").unwrap(), ["trim"])
  assert_eq(@moontemplate.inspect_source("hello").unwrap().literal_chars(), 5)
  assert_true(
    @moontemplate.source_lint("{{ x | unknown }}").unwrap()[0]
    .message()
    .contains("Unknown"),
  )
  assert_true(@moontemplate.runtime_capabilities().contains("batch-rendering"))
}

///|
test "runtime named rendering and batch limits" {
  let bundle = @moontemplate.bundle_from_pairs([("a", "A {{ x }}")]).unwrap()
  let output = @moontemplate.render_named(
    bundle,
    "a",
    @moontemplate.Context::new().set("x", "1"),
    @moontemplate.RenderPipeline::new(),
  ).unwrap()
  assert_eq(output, "A 1")
  let reports = @moontemplate.render_many_with_limits(
    "{{ x }}",
    [
      @moontemplate.Context::new().set("x", "a"),
      @moontemplate.Context::new().set("x", "b"),
    ],
    @moontemplate.RenderLimits::default(),
  )
  assert_eq(reports.length(), 2)
  assert_eq(reports[0].unwrap().output(), "a")
}

///|
test "runtime rejects empty template file names" {
  match
    @moontemplate.render_template_file_name("", @moontemplate.Context::new()) {
    Ok(_) => fail("expected empty name")
    Err(error) => assert_true(error.contains("empty"))
  }
  assert_true(
    @moontemplate.render_template_file_name(
      "welcome",
      @moontemplate.Context::new(),
    )
    .unwrap()
    .contains("welcome"),
  )
}

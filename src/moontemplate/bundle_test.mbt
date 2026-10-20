///|
test "bundle add replace and render" {
  let bundle = @moontemplate.TemplateBundle::new()
  assert_eq(bundle.add("hello", "Hello {{ name }}"), Ok(()))
  assert_eq(bundle.add("hello", "Hi {{ name }}"), Ok(()))
  let context = @moontemplate.Context::new().set("name", "Moon")
  assert_eq(bundle.render_with_context("hello", context), Ok("Hi Moon"))
  assert_eq(bundle.names(), ["hello"])
}

///|
test "bundle rejects empty names and unknown templates" {
  let bundle = @moontemplate.TemplateBundle::new()
  match bundle.add("", "text") {
    Ok(_) => fail("expected name error")
    Err(_) => ()
  }
  match bundle.render("missing", Map([], capacity=0)) {
    Ok(_) => fail("expected missing error")
    Err(error) => assert_true(error.contains("missing"))
  }
}

///|
test "bundle renders all in insertion order" {
  let bundle = @moontemplate.bundle_from_pairs([
    ("b", "B{{ x }}"),
    ("a", "A{{ x }}"),
  ]).unwrap()
  let outputs = bundle.render_all(@moontemplate.Context::new().set("x", "!"))
  assert_eq(outputs, [("b", "B!"), ("a", "A!")])
  assert_eq(bundle.length(), 2)
}

///|
test "bundle remove and aggregate stats" {
  let bundle = @moontemplate.bundle_from_pairs([("a", "A"), ("b", "{{ x }}")]).unwrap()
  assert_true(bundle.remove("a"))
  assert_false(bundle.remove("a"))
  assert_eq(bundle.names(), ["b"])
  assert_eq(bundle.stats().variable_nodes(), 1)
}

///|
test "batch rendering retains failures" {
  let good = @moontemplate.BatchItem::new(
    "good",
    "Hello {{ name }}",
    @moontemplate.Context::new().set("name", "ok"),
  )
  let bad = @moontemplate.BatchItem::new(
    "bad",
    "{% if broken %}",
    @moontemplate.Context::new(),
  )
  let results = @moontemplate.render_batch([good, bad])
  assert_eq(results.length(), 2)
  assert_true(results[0].is_ok())
  assert_false(results[1].is_ok())
  assert_eq(@moontemplate.batch_successes(results).length(), 1)
  assert_eq(@moontemplate.batch_failures(results).length(), 1)
}

///|
test "batch validation and output projection" {
  let results = @moontemplate.render_batch([
    @moontemplate.BatchItem::new("one", "1", @moontemplate.Context::new()),
    @moontemplate.BatchItem::new("two", "2", @moontemplate.Context::new()),
  ])
  assert_eq(@moontemplate.batch_outputs(results), [("one", "1"), ("two", "2")])
  assert_eq(
    @moontemplate.batch_validate([
      @moontemplate.BatchItem::new("bad", "{{", @moontemplate.Context::new()),
    ]).length(),
    1,
  )
}

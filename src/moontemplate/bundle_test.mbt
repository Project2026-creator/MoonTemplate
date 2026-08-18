///|
test "bundle add replace and render" {
  let bundle = TemplateBundle::new()
  assert_eq(bundle.add("hello", "Hello {{ name }}"), Ok(()))
  assert_eq(bundle.add("hello", "Hi {{ name }}"), Ok(()))
  let context = Context::new().set("name", "Moon")
  assert_eq(bundle.render_with_context("hello", context), Ok("Hi Moon"))
  assert_eq(bundle.names(), ["hello"])
}

///|
test "bundle rejects empty names and unknown templates" {
  let bundle = TemplateBundle::new()
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
  let bundle = bundle_from_pairs([("b", "B{{ x }}"), ("a", "A{{ x }}")]).unwrap()
  let outputs = bundle.render_all(Context::new().set("x", "!"))
  assert_eq(outputs, [("b", "B!"), ("a", "A!")])
  assert_eq(bundle.length(), 2)
}

///|
test "bundle remove and aggregate stats" {
  let bundle = bundle_from_pairs([("a", "A"), ("b", "{{ x }}")]).unwrap()
  assert_true(bundle.remove("a"))
  assert_false(bundle.remove("a"))
  assert_eq(bundle.names(), ["b"])
  assert_eq(bundle.stats().variable_nodes(), 1)
}

///|
test "batch rendering retains failures" {
  let good = BatchItem::new(
    "good",
    "Hello {{ name }}",
    Context::new().set("name", "ok"),
  )
  let bad = BatchItem::new("bad", "{% if broken %}", Context::new())
  let results = render_batch([good, bad])
  assert_eq(results.length(), 2)
  assert_true(results[0].is_ok())
  assert_false(results[1].is_ok())
  assert_eq(batch_successes(results).length(), 1)
  assert_eq(batch_failures(results).length(), 1)
}

///|
test "batch validation and output projection" {
  let results = render_batch([
    BatchItem::new("one", "1", Context::new()),
    BatchItem::new("two", "2", Context::new()),
  ])
  assert_eq(batch_outputs(results), [("one", "1"), ("two", "2")])
  assert_eq(
    batch_validate([BatchItem::new("bad", "{{", Context::new())]).length(),
    1,
  )
}

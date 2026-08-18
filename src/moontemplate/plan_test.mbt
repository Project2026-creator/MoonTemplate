///|
test "render plan executes bounded templates" {
  let bundle = bundle_from_pairs([("a", "A {{ name }}")]).unwrap()
  let plan = plan_from_names(["a"])
    .with_limits(RenderLimits::new(10, 5, 3))
    .with_pipeline(RenderPipeline::new().add("suffix", pipeline_suffix("!")))
  let results = plan.render(bundle, Context::new().set("name", "x"))
  assert_eq(results.length(), 1)
  assert_eq(results[0].output(), "A x!")
  assert_true(results[0].is_ok())
}

///|
test "plan reports output budget failures" {
  let bundle = bundle_from_pairs([("a", "long output")]).unwrap()
  let plan = plan_from_names(["a"]).with_limits(RenderLimits::new(3, 5, 3))
  let results = plan.render(bundle, Context::new())
  assert_false(results[0].is_ok())
  assert_true(results[0].error().unwrap().contains("output"))
}

///|
test "summary combines success and failure" {
  let engine = Engine::new("ok").unwrap()
  let success = engine.render_with_limits(
    Map([], capacity=0),
    RenderLimits::default(),
  )
  let summary = summarize_reports([success, Err(OutputLimitExceeded(1, 2))])
  assert_eq(summary.documents(), 2)
  assert_eq(summary.successful(), 1)
  assert_eq(summary.failed(), 1)
  assert_eq(summary.success_rate(), "50%")
}

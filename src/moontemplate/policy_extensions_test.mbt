///|
test "policy filters and source boundaries are deterministic" {
  assert_true(policy_is_builtin_filter("trim"))
  assert_false(policy_is_builtin_filter("unknown"))
  assert_eq(
    policy_validate_filters(["trim", "unknown", "uppercase", "unknown"]),
    ["unknown", "unknown"],
  )
  assert_true(policy_validate_template_size("你好", 2))
  assert_false(policy_validate_template_size("你好", 1))
  assert_false(policy_validate_template_size("x", -1))
  assert_true(policy_source_is_blank(" \n\t"))
  assert_true(policy_source_is_ascii("hello"))
  assert_false(policy_source_is_ascii("你好"))
  assert_eq(policy_source_line_count("a\nb"), 2)
  assert_eq(policy_source_lines("a\nb"), ["1: a", "2: b"])
}

///|
test "policy gates cover syntax context filters and safe rendering" {
  let source = "Hello {{ name | trim }}"
  let context = Context::new().set("name", " MoonBit ")
  assert_true(policy_check(source, context) is Ok(_))
  assert_true(policy_context_complete(source, context))
  assert_true(policy_filter_complete(source))
  assert_true(policy_static_gate(source, context) is Ok(_))
  assert_true(policy_gate_report(source, context).contains("PASS"))
  assert_true(policy_gate_json(source, context).contains("syntax_valid"))
  assert_true(policy_template_summary(source).contains("variables"))
  assert_eq(policy_safe_render(source, context).unwrap(), "Hello MoonBit")
  assert_eq(policy_render_or_message(source, context), "Hello MoonBit")
  assert_eq(policy_release_gate(source, context, 100).unwrap(), "Hello MoonBit")
  assert_true(
    policy_required_key_report(source, Context::new()).contains("name"),
  )
  assert_true(policy_filter_report(source).contains("PASS"))
  assert_true(policy_readiness_report(source, context).contains("PASS"))
  assert_eq(policy_batch_check(["literal", "{{ broken"]), [true, false])
}

///|
test "policy adapters normalize redact cache and compare application inputs" {
  let normalized = policy_normalize_context(
    Context::new().set("title", "  A\r\nB  "),
  )
  assert_eq(normalized.get_or("title", ""), "A\nB")
  assert_true(
    policy_redacted_report(Context::new().set("token", "secret-value"), [
      "token",
    ]).contains("alue"),
  )

  let source = "A {{ name }}"
  let context = Context::new().set("name", "Moon")
  assert_true(policy_template_id(source).has_prefix("tmpl-"))
  assert_true(policy_cache_key(source, context).contains("tmpl-"))
  assert_true(policy_source_fingerprint(source).has_prefix("fp-"))
  assert_true(policy_context_fingerprint(context).has_prefix("ctx-"))
  assert_true(policy_release_key(source, context).contains(":"))
  assert_true(policy_compare_sources("A", source).contains("variables"))

  let cache = TemplateCache::new(2)
  assert_eq(policy_render_cached(cache, source, context).unwrap(), "A Moon")
  assert_eq(policy_render_cached(cache, source, context).unwrap(), "A Moon")
  assert_eq(cache.hits(), 1)
  assert_eq(cache.misses(), 1)
  assert_eq(policy_source_line_count(""), 1)
}

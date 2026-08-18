///|
test "text tools cover empty and unicode boundaries" {
  assert_eq(text_repeat("ab", 3), "ababab")
  assert_eq(text_repeat("ab", 0), "")
  assert_eq(text_indent("a\nb", "> "), "> a\n> b")
  assert_eq(text_line_count("a\nb\n"), 3)
  assert_eq(text_first_non_empty_line("\n  hi"), Some("hi"))
  assert_eq(text_first_non_empty_line(" \n"), None)
  assert_eq(text_pad_left("x", 3, "0"), "00x")
  assert_eq(text_pad_right("x", 3, "0"), "x00")
  assert_eq(text_center("x", 4, "-"), "-x--")
}

///|
test "text tools wrapping and replacement" {
  assert_eq(text_wrap("one two three", 7), ["one two", "three"])
  assert_eq(text_wrap("", 4), [])
  assert_eq(text_count("aaaa", "aa"), 2)
  assert_eq(text_count("abc", ""), 0)
  assert_eq(text_replace_all("a-b-a", "a", "x"), "x-b-x")
  assert_eq(text_common_prefix("moon", "moat"), "mo")
  assert_eq(text_common_suffix("testing", "ring"), "ing")
}

///|
test "text normalization and properties" {
  assert_eq(text_normalize_newlines("a\r\nb\rc"), "a\nb\nc")
  assert_true(text_is_ascii("MoonBit"))
  assert_false(text_is_ascii("月"))
  assert_true(text_is_blank(" \t\n"))
  assert_eq(text_dedent("  a\n  b"), "a\nb")
}

///|
test "json helpers preserve escapes and ordering" {
  assert_eq(json_quote("a\"\nb"), "\"a\\\"\\nb\"")
  assert_eq(json_unquote("\"a\\n b\""), "a\n b")
  let context = Context::from_pairs([("b", "2"), ("a", "1")])
  assert_eq(json_object(context), "{\"a\":\"1\",\"b\":\"2\"}")
  assert_eq(json_array(["a", "b"]), "[\"a\",\"b\"]")
  assert_true(json_is_quoted("\"x\""))
  assert_false(json_is_quoted("x"))
}

///|
test "markdown document helpers" {
  let document = Document::new("Report")
    .add_section("Summary", 2, "Done")
    .add_section("Details", 3, "More")
  assert_eq(document.section_count(), 2)
  assert_eq(
    document.render_markdown(),
    "# Report\n\n## Summary\n\nDone\n\n### Details\n\nMore",
  )
  assert_true(markdown_table(["A", "B"], [["1", "2"]]).contains("| 1 | 2 |"))
  assert_eq(markdown_heading("x", 0), "# x\n")
  assert_eq(markdown_bullets(["a", "b"]), "- a\n- b\n")
}

///|
test "pipeline stages compose in order" {
  let pipeline = RenderPipeline::new()
    .add("trim", pipeline_trim())
    .add("suffix", pipeline_suffix("!"))
    .add("newline", pipeline_ensure_trailing_newline())
  assert_eq(pipeline.names(), ["trim", "suffix", "newline"])
  assert_eq(pipeline.apply("  hi  "), "hi!\n")
  assert_true(pipeline.remove("suffix"))
  assert_eq(pipeline.length(), 2)
}

///|
test "security policy and safe output helpers" {
  let policy = SecurityPolicy::default()
  assert_true(policy.accepts("{{ name | trim }}"))
  assert_false(policy.accepts("{{ name | unknown }}"))
  assert_eq(redact_value("secret", 2), "****et")
  assert_eq(safe_filename("a/b:c"), "a_b_c")
  assert_eq(safe_header("  x\r\ny  "), "xy")
}

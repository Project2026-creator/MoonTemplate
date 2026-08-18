///|
test "context construction and typed setters" {
  let context = Context::new()
    .set("name", " MoonBit ")
    .set_bool("enabled", true)
    .set_int("count", 4)
  assert_eq(context.get_or("name", ""), " MoonBit ")
  assert_eq(context.get_or("enabled", ""), "true")
  assert_eq(context.get_or("count", ""), "4")
  assert_eq(context.length(), 3)
  assert_true(context.contains("name"))
  assert_false(context.contains("missing"))
}

///|
test "context merge and overlay are deterministic" {
  let base = Context::from_pairs([("b", "2"), ("a", "1")])
  let overlay = Context::from_pairs([("b", "new"), ("c", "3")])
  let merged = Context::new().merge(base).merge(overlay)
  assert_eq(merged.get_or("b", ""), "new")
  assert_eq(merged.keys(), ["a", "b", "c"])
  assert_eq(context_to_sorted_pairs(merged), [
    ("a", "1"),
    ("b", "new"),
    ("c", "3"),
  ])
}

///|
test "context freeze prevents later writes" {
  let context = Context::new().set("a", "1").freeze()
  let _ = context.set("a", "2")
  let _ = context.set("b", "3")
  assert_true(context.is_frozen())
  assert_eq(context.get_or("a", ""), "1")
  assert_false(context.contains("b"))
}

///|
test "context namespace and subset" {
  let context = Context::from_pairs([("name", "Moon"), ("version", "1")])
  let prefixed = context.with_prefix("release")
  assert_true(prefixed.contains("release.name"))
  assert_eq(prefixed.get_or("release.version", ""), "1")
  let subset = context.subset(["version", "missing"])
  assert_eq(subset.keys(), ["version"])
}

///|
test "context validation reports missing keys" {
  let context = Context::from_pairs([("a", "1")])
  assert_eq(context.validate(["a", "b", "c"]), ["b", "c"])
  assert_eq(context.validate(["a"]), [])
}

///|
test "context adapters parse comments and whitespace" {
  let context = context_from_lines("# comment\n name=Moon\n\nversion=2\n").unwrap()
  assert_eq(context.keys(), ["name", "version"])
  assert_eq(context_to_lines(context), "name=Moon\nversion=2\n")
}

///|
test "context adapters reject malformed entries" {
  match context_from_strings(["valid=yes", "broken"]) {
    Ok(_) => fail("expected invalid entry")
    Err(message) => assert_true(message.contains("broken"))
  }
}

///|
test "context rows and transformations" {
  let rows = context_rows(["name", "role"], [["Ada", "admin"], ["Lin", "user"]])
  assert_eq(rows.length(), 2)
  assert_eq(rows[1].get_or("role", ""), "user")
  let upper = context_map_values(rows[0], fn(value) { value.to_upper() })
  assert_eq(upper.get_or("name", ""), "ADA")
  let picked = context_filter_keys(upper, fn(key) { key == "role" })
  assert_eq(picked.keys(), ["role"])
}

///|
test "context diff and rename" {
  let left = Context::from_pairs([("a", "1"), ("b", "2")])
  let right = Context::from_pairs([("a", "9"), ("c", "3")])
  assert_eq(context_diff(left, right), ["a", "b", "c"])
  let renamed = context_rename(left, [("a", "alpha")])
  assert_true(renamed.contains("alpha"))
  assert_false(renamed.contains("a"))
}

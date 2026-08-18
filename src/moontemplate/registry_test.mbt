///|
test "registry defines aliases and renders" {
  let registry = TemplateRegistry::new(2)
  assert_eq(registry.register("welcome", "Hi {{ name }}"), Ok(()))
  assert_true(registry.shortcut("home", "welcome"))
  assert_true(registry.contains("home"))
  assert_eq(
    registry.render("home", Context::new().set("name", "Moon")),
    Ok("Hi Moon"),
  )
  assert_eq(registry.names(), ["welcome"])
}

///|
test "registry cache records hits and misses" {
  let registry = TemplateRegistry::new(1)
  let _ = registry.compile_cached("a", "A")
  let _ = registry.compile_cached("a", "A")
  let _ = registry.compile_cached("b", "B")
  assert_true(registry.cache_hit_rate().has_suffix("%"))
  assert_eq(registry.cache_keys(), ["b"])
}

///|
test "registry reports unknown names" {
  let registry = TemplateRegistry::new(1)
  match registry.render("missing", Context::new()) {
    Ok(_) => fail("expected unknown registry entry")
    Err(error) => assert_true(error.contains("missing"))
  }
  assert_false(registry.remove("missing"))
}

///|
test "manifest and engine metadata" {
  let engine = Engine::new("{{ name | trim }}").unwrap()
  let manifest = manifest_from_engine("demo", "1.0", engine)
  assert_eq(manifest.name(), "demo")
  assert_eq(manifest.version(), "1.0")
  assert_true(manifest.to_json().contains("demo"))
  assert_true(manifest.to_markdown().contains("demo"))
  assert_true(manifest.targets().contains("native"))
}

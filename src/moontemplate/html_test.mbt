///|
test "html builder escapes text and attributes" {
  let html = HtmlBuilder::new().element("p", "<safe> & text").render()
  assert_eq(html, "<p>&lt;safe&gt; &amp; text</p>")
  let attrs = HtmlBuilder::new()
    .open_with_attributes("a", [("href", "/x?a=1&b=2")])
    .text("link")
    .close("a")
    .render()
  assert_eq(attrs, "<a href=\"/x?a=1&amp;b=2\">link</a>")
}

///|
test "html list document and metadata helpers" {
  assert_eq(html_list(["one", "two"]), "<ul><li>one</li><li>two</li></ul>")
  assert_true(
    html_document("Title", "<main>x</main>").contains("<title>Title</title>"),
  )
  let context = Context::from_pairs([("id", "a&b")])
  assert_eq(html_attributes(context), " id=\"a&amp;b\"")
  assert_eq(
    html_meta("description", "a&b"),
    "<meta name=\"description\" content=\"a&amp;b\">",
  )
}

///|
test "html safe helpers handle hostile delimiters" {
  assert_eq(html_comment("a--b"), "<!--a-b-->")
  assert_true(html_script_json(Context::new().set("x", "<")).contains("x"))
  assert_eq(
    html_tag("section", Context::new().set("class", "box"), "body"),
    "<section class=\"box\">body</section>",
  )
}

///|
test "format and adapter integration" {
  let engine = Engine::new("<h1>{{ title | escape_html }}</h1>").unwrap()
  let context = Context::new().set("title", "Moon & Bit")
  let output = html_document("Demo", engine.render(context.to_map()))
  assert_true(output.contains("Moon &amp; Bit"))
  let report = report_from_template("Report", engine, context)
  assert_eq(report.section_count(), 1)
}

///|
test "cache and bounded rendering integration" {
  let cache = TemplateCache::new(2)
  let context = Context::new().set("x", "ok")
  assert_eq(cache_render(cache, "key", "{{ x }}", context), Ok("ok"))
  assert_eq(cache_render(cache, "key", "ignored", context), Ok("ok"))
  assert_eq(cache.hits(), 1)
  let engine = cache.get("key").unwrap()
  assert_eq(
    engine
    .render_with_limits(context.to_map(), RenderLimits::new(10, 2, 2))
    .unwrap()
    .output(),
    "ok",
  )
}

///|
test "manifest and localization compose" {
  let catalog = catalog_from_pairs("en", [
    ("en", "title", "Hello"),
    ("zh", "title", "你好"),
  ])
  let engine = Engine::new("{{ title }}").unwrap()
  assert_eq(localized_render(engine, catalog, "zh", Context::new()), "你好")
  let manifest = ProjectManifest::new("x", "0.1")
    .feature("html")
    .target("native")
  assert_eq(manifest.features(), ["html"])
}

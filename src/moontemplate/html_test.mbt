///|
test "html builder escapes text and attributes" {
  let html = @moontemplate.HtmlBuilder::new()
    .element("p", "<safe> & text")
    .render()
  assert_eq(html, "<p>&lt;safe&gt; &amp; text</p>")
  let attrs = @moontemplate.HtmlBuilder::new()
    .open_with_attributes("a", [("href", "/x?a=1&b=2")])
    .text("link")
    .close("a")
    .render()
  assert_eq(attrs, "<a href=\"/x?a=1&amp;b=2\">link</a>")
}

///|
test "html list document and metadata helpers" {
  assert_eq(
    @moontemplate.html_list(["one", "two"]),
    "<ul><li>one</li><li>two</li></ul>",
  )
  assert_true(
    @moontemplate.html_document("Title", "<main>x</main>").contains(
      "<title>Title</title>",
    ),
  )
  let context = @moontemplate.Context::from_pairs([("id", "a&b")])
  assert_eq(@moontemplate.html_attributes(context), " id=\"a&amp;b\"")
  assert_eq(
    @moontemplate.html_meta("description", "a&b"),
    "<meta name=\"description\" content=\"a&amp;b\">",
  )
}

///|
test "html safe helpers handle hostile delimiters" {
  assert_eq(@moontemplate.html_comment("a--b"), "<!--a-b-->")
  assert_true(
    @moontemplate.html_script_json(@moontemplate.Context::new().set("x", "<")).contains(
      "x",
    ),
  )
  assert_eq(
    @moontemplate.html_tag(
      "section",
      @moontemplate.Context::new().set("class", "box"),
      "body",
    ),
    "<section class=\"box\">body</section>",
  )
}

///|
test "format and adapter integration" {
  let engine = @moontemplate.Engine::new("<h1>{{ title | escape_html }}</h1>").unwrap()
  let context = @moontemplate.Context::new().set("title", "Moon & Bit")
  let output = @moontemplate.html_document(
    "Demo",
    engine.render(context.to_map()),
  )
  assert_true(output.contains("Moon &amp; Bit"))
  let report = @moontemplate.report_from_template("Report", engine, context)
  assert_eq(report.section_count(), 1)
}

///|
test "cache and bounded rendering integration" {
  let cache = @moontemplate.TemplateCache::new(2)
  let context = @moontemplate.Context::new().set("x", "ok")
  assert_eq(
    @moontemplate.cache_render(cache, "key", "{{ x }}", context),
    Ok("ok"),
  )
  assert_eq(
    @moontemplate.cache_render(cache, "key", "ignored", context),
    Ok("ok"),
  )
  assert_eq(cache.hits(), 1)
  let engine = cache.get("key").unwrap()
  assert_eq(
    engine
    .render_with_limits(
      context.to_map(),
      @moontemplate.RenderLimits::new(10, 2, 2),
    )
    .unwrap()
    .output(),
    "ok",
  )
}

///|
test "manifest and localization compose" {
  let catalog = @moontemplate.catalog_from_pairs("en", [
    ("en", "title", "Hello"),
    ("zh", "title", "你好"),
  ])
  let engine = @moontemplate.Engine::new("{{ title }}").unwrap()
  assert_eq(
    @moontemplate.localized_render(
      engine,
      catalog,
      "zh",
      @moontemplate.Context::new(),
    ),
    "你好",
  )
  let manifest = @moontemplate.ProjectManifest::new("x", "0.1")
    .feature("html")
    .target("native")
  assert_eq(manifest.features(), ["html"])
}

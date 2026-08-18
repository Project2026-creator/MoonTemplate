///|
/// Additional reusable policies for deployment and CI integrations.
pub fn policy_filter_names() -> Array[String] {
  [
    "trim", "uppercase", "lowercase", "escape_html", "escape_json", "slugify", "length",
    "collapse_whitespace", "capitalize", "newline_to_br",
  ]
}

///|
pub fn policy_is_builtin_filter(name : String) -> Bool {
  policy_filter_names().contains(name)
}

///|
pub fn policy_validate_filters(names : Array[String]) -> Array[String] {
  let unknown = []
  for name in names {
    if !policy_is_builtin_filter(name) {
      unknown.push(name)
    }
  }
  unknown
}

///|
pub fn policy_validate_template_size(source : String, maximum : Int) -> Bool {
  maximum >= 0 && source.char_length() <= maximum
}

///|
pub fn policy_validate_depth(engine : Engine, maximum : Int) -> Bool {
  maximum >= 0 && engine.stats().max_depth() <= maximum
}

///|
pub fn policy_validate_output(report : RenderReport, maximum : Int) -> Bool {
  maximum >= 0 && report.metrics().output_chars() <= maximum
}

///|
pub fn policy_report(source : String, context : Context) -> String {
  let report = validate_source(source, context)
  report_validation(report)
}

///|
pub fn policy_check(source : String, context : Context) -> Result[Unit, String] {
  let report = validate_source(source, context)
  if report.valid() {
    Ok(())
  } else {
    Err(report.errors().join("; "))
  }
}

///|
pub fn policy_safe_render(
  source : String,
  context : Context,
) -> Result[String, String] {
  match
    render_safe(
      source,
      context,
      SecurityPolicy::default(),
      RenderLimits::default(),
    ) {
    Ok(report) => Ok(report.output())
    Err(error) => Err(error)
  }
}

///|
pub fn policy_template_summary(source : String) -> String {
  match inspect_source(source) {
    Ok(stats) =>
      json_object(
        Context::new()
        .set_int("nodes", stats.node_count())
        .set_int("variables", stats.variable_nodes())
        .set_int("depth", stats.max_depth())
        .set_int("literal_chars", stats.literal_chars()),
      )
    Err(errors) => diagnostics_json(errors)
  }
}

///|
pub fn policy_batch_check(sources : Array[String]) -> Array[Bool] {
  let result = []
  for source in sources {
    result.push(policy_check(source, Context::new()) is Ok(_))
  }
  result
}

///|
pub fn policy_release_gate(
  source : String,
  context : Context,
  maximum_chars : Int,
) -> Result[String, String] {
  if !policy_validate_template_size(source, maximum_chars) {
    return Err("Template exceeds release size policy")
  }
  policy_safe_render(source, context)
}

///|
pub fn policy_context_keys(
  source : String,
) -> Result[Array[String], Array[Diagnostic]] {
  source_dependencies(source)
}

///|
pub fn policy_context_complete(source : String, context : Context) -> Bool {
  match source_dependencies(source) {
    Ok(keys) => context.validate(keys).length() == 0
    Err(_) => false
  }
}

///|
pub fn policy_filter_complete(source : String) -> Bool {
  match source_filters(source) {
    Ok(names) => policy_validate_filters(names).length() == 0
    Err(_) => false
  }
}

///|
pub fn policy_static_gate(
  source : String,
  context : Context,
) -> Result[Unit, String] {
  if !policy_context_complete(source, context) {
    return Err("Context is incomplete")
  }
  if !policy_filter_complete(source) {
    return Err("Filter policy rejected template")
  }
  policy_check(source, context)
}

///|
pub fn policy_gate_report(source : String, context : Context) -> String {
  let checks = [
    ("context", policy_context_complete(source, context)),
    ("filters", policy_filter_complete(source)),
    ("syntax", policy_check(source, context) is Ok(_)),
  ]
  report_checks(checks)
}

///|
pub fn policy_normalize_context(context : Context) -> Context {
  context_map_values(context, fn(value) {
    text_normalize_newlines(value).trim().to_owned()
  })
}

///|
pub fn policy_redacted_report(
  context : Context,
  sensitive : Array[String],
) -> String {
  report_context(redact_context(context, sensitive))
}

///|
pub fn policy_template_id(source : String) -> String {
  "tmpl-" + text_checksum(source).to_string()
}

///|
pub fn policy_cache_key(source : String, context : Context) -> String {
  policy_template_id(source) +
  "-" +
  text_checksum(json_object(context)).to_string()
}

///|
pub fn policy_render_cached(
  cache : TemplateCache,
  source : String,
  context : Context,
) -> Result[String, String] {
  cache_render(cache, policy_cache_key(source, context), source, context)
}

///|
pub fn policy_compare_sources(left : String, right : String) -> String {
  match (inspect_source(left), inspect_source(right)) {
    (Ok(a), Ok(b)) => {
      let changes = [
        ("nodes", a.node_count() - b.node_count()),
        ("variables", a.variable_nodes() - b.variable_nodes()),
        ("filters", a.filter_count() - b.filter_count()),
        ("literal_chars", a.literal_chars() - b.literal_chars()),
      ]
      report_counts(changes)
    }
    _ => "Unable to compare invalid sources"
  }
}

///|
pub fn policy_source_fingerprint(source : String) -> String {
  let summary = policy_template_summary(source)
  "fp-" + text_checksum(summary).to_string()
}

///|
pub fn policy_context_fingerprint(context : Context) -> String {
  "ctx-" + text_checksum(json_object(context)).to_string()
}

///|
pub fn policy_release_key(source : String, context : Context) -> String {
  policy_source_fingerprint(source) + ":" + policy_context_fingerprint(context)
}

///|
pub fn policy_gate_json(source : String, context : Context) -> String {
  json_object(
    Context::new()
    .set("template", policy_template_id(source))
    .set_bool("context_complete", policy_context_complete(source, context))
    .set_bool("filters_allowed", policy_filter_complete(source))
    .set_bool("syntax_valid", policy_check(source, context) is Ok(_)),
  )
}

///|
pub fn policy_render_or_message(source : String, context : Context) -> String {
  match policy_safe_render(source, context) {
    Ok(value) => value
    Err(error) => "ERROR: " + error
  }
}

///|
pub fn policy_source_lines(source : String) -> Array[String] {
  text_lines_with_numbers(source)
}

///|
pub fn policy_source_line_count(source : String) -> Int {
  text_line_count(source)
}

///|
pub fn policy_source_is_blank(source : String) -> Bool {
  text_is_blank(source)
}

///|
pub fn policy_source_is_ascii(source : String) -> Bool {
  text_is_ascii(source)
}

///|
pub fn policy_required_key_report(source : String, context : Context) -> String {
  match policy_context_keys(source) {
    Ok(keys) => {
      let missing = context.validate(keys)
      if missing.length() == 0 {
        report_status("required-keys", true)
      } else {
        report_error_list(missing)
      }
    }
    Err(errors) => diagnostics_text(errors)
  }
}

///|
pub fn policy_filter_report(source : String) -> String {
  match source_filters(source) {
    Ok(filters) => {
      let unknown = policy_validate_filters(filters)
      if unknown.length() == 0 {
        report_status("filters", true)
      } else {
        report_error_list(unknown)
      }
    }
    Err(errors) => diagnostics_text(errors)
  }
}

///|
pub fn policy_acceptance_report(source : String, context : Context) -> String {
  report_checks([
    ("syntax", policy_check(source, context) is Ok(_)),
    ("context", policy_context_complete(source, context)),
    ("filters", policy_filter_complete(source)),
    ("size", policy_validate_template_size(source, 100_000)),
  ])
}

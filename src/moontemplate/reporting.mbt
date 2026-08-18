///|
/// Reporting helpers for CI logs, acceptance evidence, and operator dashboards.
pub fn report_header(title : String) -> String {
  markdown_heading(title, 1)
}

///|
pub fn report_status(label : String, passed : Bool) -> String {
  format_badge(label, if passed { "PASS" } else { "FAIL" })
}

///|
pub fn report_checks(checks : Array[(String, Bool)]) -> String {
  let result = StringBuilder::new()
  for pair in checks {
    let (label, passed) = pair
    result.write_string(report_status(label, passed))
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn report_engine(engine : Engine) -> String {
  let stats = engine.stats()
  markdown_table(["Property", "Value"], [
    ["nodes", stats.node_count().to_string()],
    ["variables", stats.variable_nodes().to_string()],
    ["conditionals", stats.if_nodes().to_string()],
    ["loops", stats.for_nodes().to_string()],
    ["filters", stats.filter_count().to_string()],
    ["max_depth", stats.max_depth().to_string()],
    ["literal_chars", stats.literal_chars().to_string()],
  ])
}

///|
pub fn report_context(context : Context) -> String {
  markdown_table(
    ["Key", "Value"],
    context_to_sorted_pairs(context).map(fn(pair) {
      let (key, value) = pair
      [key, value]
    }),
  )
}

///|
pub fn report_validation(report : ValidationReport) -> String {
  let result = StringBuilder::new()
  result.write_string(report_status("validation", report.valid()))
  result.write_char('\n')
  for message in report.errors() {
    result.write_string("- error: " + message + "\n")
  }
  for message in report.warnings() {
    result.write_string("- warning: " + message + "\n")
  }
  for message in report.infos() {
    result.write_string("- info: " + message + "\n")
  }
  result.to_string()
}

///|
pub fn report_batch(results : Array[BatchResult]) -> String {
  let rows = []
  for result in results {
    rows.push([
      result.name(),
      if result.is_ok() {
        "PASS"
      } else {
        "FAIL"
      },
      result.output(),
    ])
  }
  markdown_table(["Name", "Status", "Output"], rows)
}

///|
pub fn report_bundle(bundle : TemplateBundle) -> String {
  let rows = []
  for name in bundle.names() {
    match bundle.get(name) {
      Some(engine) => {
        let stats = engine.stats()
        rows.push([
          name,
          stats.node_count().to_string(),
          engine.required_variables().length().to_string(),
        ])
      }
      None => rows.push([name, "0", "0"])
    }
  }
  markdown_table(["Template", "Nodes", "Inputs"], rows)
}

///|
pub fn report_capabilities() -> String {
  markdown_bullets(runtime_capabilities())
}

///|
pub fn report_package(manifest : ProjectManifest, engine : Engine) -> String {
  report_header(manifest.name()) +
  manifest.to_markdown() +
  "\n" +
  report_engine(engine)
}

///|
pub fn report_json_status(
  label : String,
  passed : Bool,
  message : String,
) -> String {
  json_object(
    Context::new()
    .set("label", label)
    .set_bool("passed", passed)
    .set("message", message),
  )
}

///|
pub fn report_lines(values : Array[String]) -> String {
  format_plain_list(values, "", "\n")
}

///|
pub fn report_error_list(values : Array[String]) -> String {
  format_plain_list(values, "ERROR: ", "\n")
}

///|
pub fn report_warning_list(values : Array[String]) -> String {
  format_plain_list(values, "WARNING: ", "\n")
}

///|
pub fn report_success_list(values : Array[String]) -> String {
  format_plain_list(values, "OK: ", "\n")
}

///|
pub fn report_compare(left : RenderSummary, right : RenderSummary) -> String {
  let rows = []
  for pair in compare_summaries(left, right) {
    let (key, difference) = pair
    rows.push([key, difference.to_string()])
  }
  markdown_table(["Metric", "Difference"], rows)
}

///|
pub fn report_locale(catalog : LocaleCatalog) -> String {
  markdown_bullets(catalog.locales())
}

///|
pub fn report_plan(plan : RenderPlan) -> String {
  markdown_table(["Field", "Value"], [
    ["templates", plan.names().join(", ")],
    ["plan", plan.describe()],
  ])
}

///|
pub fn report_source(source : String) -> String {
  match inspect_source(source) {
    Ok(stats) =>
      format_badge("source", "valid") + "\n" + stats.node_count().to_string()
    Err(errors) => {
      let lines = []
      for line in diagnostics_text(errors).split("\n") {
        lines.push(line.to_owned())
      }
      report_error_list(lines)
    }
  }
}

///|
pub fn report_title_status(title : String, status : String) -> String {
  report_header(title) +
  "\n" +
  report_status("status", status.to_upper() == "PASS")
}

///|
pub fn report_key_value(key : String, value : String) -> String {
  format_badge(safe_header(key), safe_header(value))
}

///|
pub fn report_counts(values : Array[(String, Int)]) -> String {
  let rows = []
  for pair in values {
    let (key, value) = pair
    rows.push([key, value.to_string()])
  }
  markdown_table(["Name", "Count"], rows)
}

///|
pub fn report_template_dependencies(engine : Engine) -> String {
  markdown_bullets(engine.required_variables())
}

///|
pub fn report_template_filters(engine : Engine) -> String {
  markdown_bullets(engine.filter_names())
}

///|
pub fn report_audit(registry : TemplateRegistry) -> String {
  let problems = registry.audit()
  if problems.length() == 0 {
    report_status("audit", true)
  } else {
    report_error_list(problems)
  }
}

///|
pub fn report_security(policy : SecurityPolicy, source : String) -> String {
  report_status("security", policy.accepts(source))
}

///|
pub fn report_schema(schema : ContextSchema, context : Context) -> String {
  report_key_value("schema", schema_report(schema, context))
}

///|
pub fn report_file_name(name : String) -> String {
  report_key_value("file", safe_filename(name))
}

///|
pub fn report_locale_fallback(
  catalog : LocaleCatalog,
  requested : String,
) -> String {
  report_key_value(
    "locale",
    catalog.translate(requested, "title", catalog.fallback()),
  )
}

///|
pub fn report_diff_lines(left : Context, right : Context) -> Array[String] {
  let result = []
  for line in format_diff(left, right).split("\n") {
    if line != "" {
      result.push(line.to_owned())
    }
  }
  result
}

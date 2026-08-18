///|
/// High-level runtime entry points for applications that do not need to keep
/// an Engine object around themselves.
pub fn render_string(
  source : String,
  context : Context,
) -> Result[String, String] {
  match Engine::new(source) {
    Ok(engine) => Ok(engine.render(context.to_map()))
    Err(error) => Err(error)
  }
}

///|
pub fn render_checked(
  source : String,
  context : Context,
  schema : ContextSchema,
) -> Result[String, String] {
  let applied = schema.apply_defaults(context)
  let errors = schema.validate(applied)
  if errors.length() > 0 {
    return Err(errors.join("; "))
  }
  render_string(source, applied)
}

///|
pub fn render_safe(
  source : String,
  context : Context,
  policy : SecurityPolicy,
  limits : RenderLimits,
) -> Result[RenderReport, String] {
  match assert_safe_source(policy, source) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let engine = match Engine::new(source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match engine.render_with_limits(context.to_map(), limits) {
    Ok(report) => Ok(report)
    Err(failure) => Err(render_failure_text(failure))
  }
}

///|
fn render_failure_text(failure : RenderFailure) -> String {
  match failure {
    OutputLimitExceeded(limit, current) =>
      "output limit \{limit}, current \{current}"
    IterationLimitExceeded(limit) => "iteration limit \{limit}"
    DepthLimitExceeded(limit) => "depth limit \{limit}"
  }
}

///|
pub fn render_many(
  source : String,
  contexts : Array[Context],
) -> Result[Array[String], String] {
  let engine = match Engine::new(source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let outputs = []
  for context in contexts {
    outputs.push(engine.render(context.to_map()))
  }
  Ok(outputs)
}

///|
pub fn render_many_with_limits(
  source : String,
  contexts : Array[Context],
  limits : RenderLimits,
) -> Array[Result[RenderReport, RenderFailure]] {
  let result = []
  match Engine::new(source) {
    Ok(engine) =>
      for context in contexts {
        result.push(engine.render_with_limits(context.to_map(), limits))
      }
    Err(_) =>
      for _ in contexts {
        result.push(Err(DepthLimitExceeded(0)))
      }
  }
  result
}

///|
pub fn render_named(
  bundle : TemplateBundle,
  name : String,
  context : Context,
  pipeline : RenderPipeline,
) -> Result[String, String] {
  match bundle.get(name) {
    Some(engine) => Ok(pipeline.apply_to(engine, context))
    None => Err("Unknown template: {name}")
  }
}

///|
pub fn inspect_source(
  source : String,
) -> Result[TemplateStats, Array[Diagnostic]] {
  match Engine::new_with_diagnostics(source) {
    Ok(engine) => Ok(engine.stats())
    Err(errors) => Err(errors)
  }
}

///|
pub fn source_dependencies(
  source : String,
) -> Result[Array[String], Array[Diagnostic]] {
  match Engine::new_with_diagnostics(source) {
    Ok(engine) => Ok(engine.required_variables())
    Err(errors) => Err(errors)
  }
}

///|
pub fn source_filters(
  source : String,
) -> Result[Array[String], Array[Diagnostic]] {
  match Engine::new_with_diagnostics(source) {
    Ok(engine) => Ok(engine.filter_names())
    Err(errors) => Err(errors)
  }
}

///|
pub fn source_lint(
  source : String,
) -> Result[Array[TemplateLintIssue], Array[Diagnostic]] {
  lint_template(source, [
    "trim", "uppercase", "lowercase", "escape_html", "escape_json", "slugify", "replace",
    "truncate", "default", "prefix", "suffix", "pad_left", "pad_right", "slice",
  ])
}

///|
pub fn render_template_file_name(
  name : String,
  context : Context,
) -> Result[String, String] {
  if name.trim() == "" {
    Err("Template name cannot be empty")
  } else {
    Ok(name + ":" + json_object(context))
  }
}

///|
pub fn runtime_capabilities() -> Array[String] {
  [
    "interpolation", "filters", "conditionals", "loops", "diagnostics", "inspection",
    "bounded-rendering", "batch-rendering", "localization", "html-output", "json-output",
    "native-cli",
  ]
}

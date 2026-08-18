///|
/// Validation rules for release pipelines and user-facing template editors.
pub struct ValidationReport {
  errors : Array[String]
  warnings : Array[String]
  infos : Array[String]
} derive(Debug, Eq)

///|
pub fn ValidationReport::new() -> ValidationReport {
  { errors: [], warnings: [], infos: [] }
}

///|
pub fn ValidationReport::error(
  self : ValidationReport,
  message : String,
) -> ValidationReport {
  self.errors.push(message)
  self
}

///|
pub fn ValidationReport::warning(
  self : ValidationReport,
  message : String,
) -> ValidationReport {
  self.warnings.push(message)
  self
}

///|
pub fn ValidationReport::info(
  self : ValidationReport,
  message : String,
) -> ValidationReport {
  self.infos.push(message)
  self
}

///|
pub fn ValidationReport::errors(self : ValidationReport) -> Array[String] {
  self.errors.copy()
}

///|
pub fn ValidationReport::warnings(self : ValidationReport) -> Array[String] {
  self.warnings.copy()
}

///|
pub fn ValidationReport::infos(self : ValidationReport) -> Array[String] {
  self.infos.copy()
}

///|
pub fn ValidationReport::valid(self : ValidationReport) -> Bool {
  self.errors.length() == 0
}

///|
pub fn ValidationReport::total(self : ValidationReport) -> Int {
  self.errors.length() + self.warnings.length() + self.infos.length()
}

///|
pub fn validate_engine(engine : Engine, context : Context) -> ValidationReport {
  let report = ValidationReport::new()
  let schema = schema_for_engine(engine)
  for error in schema.validate(context) {
    let _ = report.error(error)
  }
  if engine.stats().max_depth() > 8 {
    let _ = report.warning("Template nesting is deep")
  }
  if engine.stats().literal_chars() == 0 {
    let _ = report.info("Template has no literal text")
  }
  report
}

///|
pub fn validate_source(source : String, context : Context) -> ValidationReport {
  match Engine::new_with_diagnostics(source) {
    Ok(engine) => validate_engine(engine, context)
    Err(diagnostics) => {
      let report = ValidationReport::new()
      for diagnostic in diagnostics {
        let _ = report.error(diagnostic_text(diagnostic))
      }
      report
    }
  }
}

///|
pub fn validate_bundle(
  bundle : TemplateBundle,
  context : Context,
) -> Array[(String, ValidationReport)] {
  let result = []
  for name in bundle.names() {
    match bundle.get(name) {
      Some(engine) => result.push((name, validate_engine(engine, context)))
      None => ()
    }
  }
  result
}

///|
pub fn validation_summary(
  reports : Array[(String, ValidationReport)],
) -> String {
  let mut valid = 0
  let mut invalid = 0
  for pair in reports {
    let (_, report) = pair
    if report.valid() {
      valid += 1
    } else {
      invalid += 1
    }
  }
  "valid=\{valid}, invalid=\{invalid}, total=\{reports.length()}"
}

///|
pub fn validate_required_context(
  engine : Engine,
  context : Map[String, String],
) -> Bool {
  schema_for_engine(engine).accepts(context_from_map(context))
}

///|
pub fn assert_safe_source(
  policy : SecurityPolicy,
  source : String,
) -> Result[Unit, String] {
  let diagnostics = policy.validate(source)
  if diagnostics.length() == 0 {
    Ok(())
  } else {
    Err(diagnostics_text(diagnostics))
  }
}

///|
pub fn validate_identifier_list(values : Array[String]) -> Array[String] {
  let invalid = []
  for value in values {
    if !text_is_identifier(value) {
      invalid.push(value)
    }
  }
  invalid
}

///|
pub fn validate_unique_names(values : Array[String]) -> Array[String] {
  let duplicates = []
  let seen = []
  for value in values {
    if seen.contains(value) && !duplicates.contains(value) {
      duplicates.push(value)
    }
    seen.push(value)
  }
  duplicates
}

///|
pub fn validate_limits(limits : RenderLimits) -> Array[String] {
  let errors = []
  if limits.max_output_chars() == 0 {
    errors.push("Output limit is zero")
  }
  if limits.max_depth() == 0 {
    errors.push("Depth limit is zero")
  }
  errors
}

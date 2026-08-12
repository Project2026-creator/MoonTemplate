///|
/// A preflight view used by editors, CI checks, and template registries.
pub struct TemplateInspection {
  stats : TemplateStats
  required_variables : Array[String]
  filter_names : Array[String]
  lint_issues : Array[TemplateLintIssue]
} derive(Debug, Eq)

///|
pub fn TemplateInspection::stats(self : TemplateInspection) -> TemplateStats {
  self.stats
}

///|
pub fn TemplateInspection::required_variables(
  self : TemplateInspection,
) -> Array[String] {
  self.required_variables
}

///|
pub fn TemplateInspection::filter_names(
  self : TemplateInspection,
) -> Array[String] {
  self.filter_names
}

///|
pub fn TemplateInspection::lint_issues(
  self : TemplateInspection,
) -> Array[TemplateLintIssue] {
  self.lint_issues
}

///|
pub fn TemplateInspection::is_clean(self : TemplateInspection) -> Bool {
  self.lint_issues.length() == 0
}

///|
/// Parse once for metadata and once for diagnostics, returning no partial result.
pub fn inspect_template(
  template : String,
  known_filters : Array[String],
) -> Result[TemplateInspection, Array[Diagnostic]] {
  let engine = match Engine::new_with_diagnostics(template) {
    Ok(value) => value
    Err(diagnostics) => return Err(diagnostics)
  }
  let issues = match lint_template(template, known_filters) {
    Ok(value) => value
    Err(diagnostics) => return Err(diagnostics)
  }
  Ok({
    stats: engine.stats(),
    required_variables: engine.required_variables(),
    filter_names: engine.filter_names(),
    lint_issues: issues,
  })
}

///|
/// Context coverage for a template invocation.
pub struct ContextAudit {
  missing : Array[String]
  unused : Array[String]
  provided_count : Int
} derive(Debug, Eq)

///|
pub fn ContextAudit::missing(self : ContextAudit) -> Array[String] {
  self.missing
}

///|
pub fn ContextAudit::unused(self : ContextAudit) -> Array[String] {
  self.unused
}

///|
pub fn ContextAudit::provided_count(self : ContextAudit) -> Int {
  self.provided_count
}

///|
/// Compare a concrete string context with the keys referenced by the AST.
pub fn Engine::audit_context(
  self : Engine,
  context : Map[String, String],
) -> ContextAudit {
  let required = self.required_variables()
  let missing : Array[String] = []
  for name in required {
    match context.get(name) {
      Some(_) => ()
      None => missing.push(name)
    }
  }
  let unused : Array[String] = []
  for name, _ in context {
    if !required.contains(name) {
      unused.push(name)
    }
  }
  { missing, unused, provided_count: context.length() }
}

///|
/// Return a compact human-readable context audit for command-line tools.
pub fn ContextAudit::summary(self : ContextAudit) -> String {
  let mut output = "provided=" + self.provided_count.to_string()
  output += ", missing=" + self.missing.length().to_string()
  output += ", unused=" + self.unused.length().to_string()
  if self.missing.length() > 0 {
    output += " [missing: " + join_names(self.missing) + "]"
  }
  if self.unused.length() > 0 {
    output += " [unused: " + join_names(self.unused) + "]"
  }
  output
}

///|
fn join_names(names : Array[String]) -> String {
  let mut output = ""
  for index, name in names {
    if index > 0 {
      output += ", "
    }
    output += name
  }
  output
}

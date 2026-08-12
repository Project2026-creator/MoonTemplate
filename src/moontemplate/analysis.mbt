///|
/// Severity levels emitted by the template linter.
pub(all) enum LintSeverity {
  Info
  Warning
  Error
} derive(Debug, Eq)

///|
/// Structural facts collected from a parsed template.
pub struct TemplateStats {
  mut node_count : Int
  mut text_nodes : Int
  mut variable_nodes : Int
  mut if_nodes : Int
  mut for_nodes : Int
  mut filter_count : Int
  mut max_depth : Int
  mut literal_chars : Int
} derive(Debug, Eq)

///|
pub fn TemplateStats::node_count(self : TemplateStats) -> Int {
  self.node_count
}

///|
pub fn TemplateStats::text_nodes(self : TemplateStats) -> Int {
  self.text_nodes
}

///|
pub fn TemplateStats::variable_nodes(self : TemplateStats) -> Int {
  self.variable_nodes
}

///|
pub fn TemplateStats::if_nodes(self : TemplateStats) -> Int {
  self.if_nodes
}

///|
pub fn TemplateStats::for_nodes(self : TemplateStats) -> Int {
  self.for_nodes
}

///|
pub fn TemplateStats::filter_count(self : TemplateStats) -> Int {
  self.filter_count
}

///|
pub fn TemplateStats::max_depth(self : TemplateStats) -> Int {
  self.max_depth
}

///|
pub fn TemplateStats::literal_chars(self : TemplateStats) -> Int {
  self.literal_chars
}

///|
/// A source-oriented issue reported before rendering.
pub struct TemplateLintIssue {
  severity : LintSeverity
  code : String
  message : String
  line : Int
  column : Int
  source_line : String
} derive(Debug, Eq)

///|
pub fn TemplateLintIssue::severity(self : TemplateLintIssue) -> LintSeverity {
  self.severity
}

///|
pub fn TemplateLintIssue::code(self : TemplateLintIssue) -> String {
  self.code
}

///|
pub fn TemplateLintIssue::message(self : TemplateLintIssue) -> String {
  self.message
}

///|
pub fn TemplateLintIssue::line(self : TemplateLintIssue) -> Int {
  self.line
}

///|
pub fn TemplateLintIssue::column(self : TemplateLintIssue) -> Int {
  self.column
}

///|
pub fn TemplateLintIssue::source_line(self : TemplateLintIssue) -> String {
  self.source_line
}

///|
pub fn Engine::stats(self : Engine) -> TemplateStats {
  let stats : TemplateStats = {
    node_count: 0,
    text_nodes: 0,
    variable_nodes: 0,
    if_nodes: 0,
    for_nodes: 0,
    filter_count: 0,
    max_depth: 0,
    literal_chars: 0,
  }
  collect_stats(self.nodes, 0, stats)
  stats
}

///|
fn collect_stats(
  nodes : Array[Node],
  depth : Int,
  stats : TemplateStats,
) -> Unit {
  if depth > stats.max_depth {
    stats.max_depth = depth
  }
  for node in nodes {
    stats.node_count += 1
    match node {
      Text(value) => {
        stats.text_nodes += 1
        stats.literal_chars += value.char_length()
      }
      Variable(_, filters) => {
        stats.variable_nodes += 1
        stats.filter_count += filters.length()
      }
      If(_, true_branch, false_branch) => {
        stats.if_nodes += 1
        collect_stats(true_branch, depth + 1, stats)
        collect_stats(false_branch, depth + 1, stats)
      }
      For(_, _, body) => {
        stats.for_nodes += 1
        collect_stats(body, depth + 1, stats)
      }
    }
  }
}

///|
/// Return context keys read by the template, in first-use order.
pub fn Engine::required_variables(self : Engine) -> Array[String] {
  let result : Array[String] = []
  collect_required(self.nodes, [], result)
  result
}

///|
fn collect_required(
  nodes : Array[Node],
  locals : Array[String],
  result : Array[String],
) -> Unit {
  for node in nodes {
    match node {
      Text(_) => ()
      Variable(name, _) => add_required(name, locals, result)
      If(condition, true_branch, false_branch) => {
        add_required(condition, locals, result)
        collect_required(true_branch, locals, result)
        collect_required(false_branch, locals, result)
      }
      For(variable, iterable, body) => {
        add_required(iterable, locals, result)
        let nested_locals = locals.copy()
        nested_locals.push(variable)
        collect_required(body, nested_locals, result)
      }
    }
  }
}

///|
fn add_required(
  name : String,
  locals : Array[String],
  result : Array[String],
) -> Unit {
  if !locals.contains(name) && !result.contains(name) {
    result.push(name)
  }
}

///|
/// Return filter names without their optional parameter lists.
pub fn Engine::filter_names(self : Engine) -> Array[String] {
  let result : Array[String] = []
  collect_filter_names(self.nodes, result)
  result
}

///|
fn collect_filter_names(nodes : Array[Node], result : Array[String]) -> Unit {
  for node in nodes {
    match node {
      Text(_) => ()
      Variable(_, filters) =>
        for raw in filters {
          let name = filter_name(raw)
          if name != "" && !result.contains(name) {
            result.push(name)
          }
        }
      If(_, true_branch, false_branch) => {
        collect_filter_names(true_branch, result)
        collect_filter_names(false_branch, result)
      }
      For(_, _, body) => collect_filter_names(body, result)
    }
  }
}

///|
fn filter_name(raw : String) -> String {
  match raw.split_once("(") {
    Some((name, _)) => name.trim().to_owned()
    None => raw
  }
}

///|
/// Parse and lint a template against the caller's available filter registry.
pub fn lint_template(
  template : String,
  known_filters : Array[String],
) -> Result[Array[TemplateLintIssue], Array[Diagnostic]] {
  let engine = match Engine::new_with_diagnostics(template) {
    Ok(value) => value
    Err(diagnostics) => return Err(diagnostics)
  }
  let issues : Array[TemplateLintIssue] = []
  if template.trim() == "" {
    issues.push({
      severity: Info,
      code: "TMPL_EMPTY_TEMPLATE",
      message: "Template is empty",
      line: 1,
      column: 1,
      source_line: "",
    })
  }
  for name in engine.filter_names() {
    if !known_filters.contains(name) {
      let (line, column, source_line) = lint_location(template, name)
      issues.push({
        severity: Warning,
        code: "TMPL_UNKNOWN_FILTER",
        message: "Unknown filter: \{name}",
        line,
        column,
        source_line,
      })
    }
  }
  let stats = engine.stats()
  if stats.max_depth() > 8 {
    issues.push({
      severity: Warning,
      code: "TMPL_DEEP_NESTING",
      message: "Template nesting exceeds the recommended depth of 8",
      line: 1,
      column: 1,
      source_line: first_line(template),
    })
  }
  Ok(issues)
}

///|
fn lint_location(source : String, name : String) -> (Int, Int, String) {
  let needle = "| \{name}"
  let mut line = 1
  for source_line in source.split("\n") {
    if source_line.contains(needle) {
      return (line, 1, source_line.to_owned())
    }
    line += 1
  }
  (1, 1, "")
}

///|
fn first_line(source : String) -> String {
  for source_line in source.split("\n") {
    return source_line.to_owned()
  }
  ""
}

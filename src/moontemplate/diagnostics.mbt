///|
/// Structured categories used by the strict parser and renderer.
pub(all) enum DiagnosticKind {
  Lexical
  Syntax
  Filter
} derive(Debug, Eq)

///|
/// A stable, source-oriented error that can be rendered as text or JSON.
pub struct Diagnostic {
  kind : DiagnosticKind
  message : String
  line : Int
  column : Int
  source_line : String
} derive(Debug, Eq)

///|
pub fn Diagnostic::new(
  kind : DiagnosticKind,
  message : String,
  line : Int,
  column : Int,
  source_line : String,
) -> Diagnostic {
  { kind, message, line, column, source_line }
}

///|
pub fn Diagnostic::kind(self : Diagnostic) -> DiagnosticKind {
  self.kind
}

///|
pub fn Diagnostic::message(self : Diagnostic) -> String {
  self.message
}

///|
pub fn Diagnostic::line(self : Diagnostic) -> Int {
  self.line
}

///|
pub fn Diagnostic::column(self : Diagnostic) -> Int {
  self.column
}

///|
pub fn Diagnostic::source_line(self : Diagnostic) -> String {
  self.source_line
}

///|
pub fn DiagnosticKind::as_str(self : DiagnosticKind) -> String {
  match self {
    Lexical => "lexical"
    Syntax => "syntax"
    Filter => "filter"
  }
}

///|
pub fn Diagnostic::code(self : Diagnostic) -> String {
  match self.kind {
    Lexical => "TMPL_LEX"
    Syntax => "TMPL_PARSE"
    Filter => "TMPL_FILTER"
  }
}

///|
fn make_diagnostic(
  kind : DiagnosticKind,
  message : String,
  source : String,
  offset : Int,
) -> Diagnostic {
  let safe_offset = if offset < 0 {
    0
  } else if offset > source.length() {
    source.length()
  } else {
    offset
  }
  let prefix = source[:safe_offset]
  let mut line = 1
  let mut column = 1
  for c in prefix {
    if c == '\n' {
      line += 1
      column = 1
    } else {
      column += 1
    }
  }
  let mut source_line = ""
  let mut current = 1
  for part in source.split("\n") {
    if current == line {
      source_line = part.to_owned()
      break
    }
    current += 1
  }
  { kind, message, line, column, source_line }
}

///|
fn make_runtime_filter_diagnostic(message : String) -> Diagnostic {
  { kind: Filter, message, line: 0, column: 0, source_line: "" }
}

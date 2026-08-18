///|
/// Helpers for turning structured diagnostics into stable CI and editor text.
pub fn diagnostics_count_by_kind(
  diagnostics : Array[Diagnostic],
) -> Array[(String, Int)] {
  let mut lexical = 0
  let mut syntax = 0
  let mut filter = 0
  for diagnostic in diagnostics {
    match diagnostic.kind() {
      Lexical => lexical += 1
      Syntax => syntax += 1
      Filter => filter += 1
    }
  }
  [("lexical", lexical), ("syntax", syntax), ("filter", filter)]
}

///|
pub fn diagnostic_text(diagnostic : Diagnostic) -> String {
  "\{diagnostic.code()} at \{diagnostic.line()}:\{diagnostic.column()}: \{diagnostic.message()}"
}

///|
pub fn diagnostics_text(diagnostics : Array[Diagnostic]) -> String {
  let result = StringBuilder::new()
  for diagnostic in diagnostics {
    result.write_string(diagnostic_text(diagnostic))
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn diagnostics_json(diagnostics : Array[Diagnostic]) -> String {
  let result = StringBuilder::new()
  result.write_char('[')
  for index, diagnostic in diagnostics {
    if index > 0 {
      result.write_char(',')
    }
    let context = Context::new()
      .set("code", diagnostic.code())
      .set("kind", diagnostic.kind().as_str())
      .set("message", diagnostic.message())
      .set_int("line", diagnostic.line())
      .set_int("column", diagnostic.column())
      .set("source_line", diagnostic.source_line())
    result.write_string(json_object(context))
  }
  result.write_char(']')
  result.to_string()
}

///|
pub fn diagnostic_summary(diagnostics : Array[Diagnostic]) -> String {
  let counts = diagnostics_count_by_kind(diagnostics)
  let result = StringBuilder::new()
  for index, pair in counts {
    if index > 0 {
      result.write_string(", ")
    }
    let (kind, count) = pair
    result.write_string(kind)
    result.write_char('=')
    result.write_string(count.to_string())
  }
  result.to_string()
}

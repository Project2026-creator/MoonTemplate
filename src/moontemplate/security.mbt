///|
/// Policy helpers for rendering user-controlled templates safely.
pub struct SecurityPolicy {
  allowed_filters : Array[String]
  mut max_template_chars : Int
  mut reject_unknown_filters : Bool
} derive(Debug, Eq)

///|
pub fn SecurityPolicy::default() -> SecurityPolicy {
  {
    allowed_filters: [
      "trim", "uppercase", "lowercase", "escape_html", "escape_json", "slugify",
    ],
    max_template_chars: 100_000,
    reject_unknown_filters: true,
  }
}

///|
pub fn SecurityPolicy::new(max_template_chars : Int) -> SecurityPolicy {
  let policy = SecurityPolicy::default()
  policy.max_template_chars = if max_template_chars < 0 {
    0
  } else {
    max_template_chars
  }
  policy
}

///|
pub fn SecurityPolicy::allow_filter(
  self : SecurityPolicy,
  name : String,
) -> SecurityPolicy {
  if !self.allowed_filters.contains(name) {
    self.allowed_filters.push(name)
  }
  self
}

///|
pub fn SecurityPolicy::without_unknown_filter_rejection(
  self : SecurityPolicy,
) -> SecurityPolicy {
  self.reject_unknown_filters = false
  self
}

///|
pub fn SecurityPolicy::validate(
  self : SecurityPolicy,
  source : String,
) -> Array[Diagnostic] {
  let diagnostics = []
  if source.char_length() > self.max_template_chars {
    diagnostics.push(
      Diagnostic::new(
        Lexical,
        "Template exceeds configured size limit",
        1,
        1,
        "",
      ),
    )
    return diagnostics
  }
  match Engine::new_with_diagnostics(source) {
    Ok(engine) =>
      if self.reject_unknown_filters {
        for name in engine.filter_names() {
          if !self.allowed_filters.contains(name) {
            diagnostics.push(
              Diagnostic::new(
                Filter,
                "Filter is not allowed by policy: {name}",
                1,
                1,
                "",
              ),
            )
          }
        }
      }
    Err(errors) =>
      for error in errors {
        diagnostics.push(error)
      }
  }
  diagnostics
}

///|
pub fn SecurityPolicy::accepts(self : SecurityPolicy, source : String) -> Bool {
  self.validate(source).length() == 0
}

///|
pub fn redact_value(value : String, visible_suffix : Int) -> String {
  let count = value.char_length() - visible_suffix
  if count <= 0 {
    return value
  }
  let suffix = if visible_suffix <= 0 {
    ""
  } else {
    value[value.length() - visible_suffix:].to_owned()
  }
  text_repeat("*", count) + suffix
}

///|
pub fn redact_context(context : Context, keys : Array[String]) -> Context {
  let result = Context::new()
  for key in context.keys() {
    let value = context.get_or(key, "")
    let safe = if keys.contains(key) { redact_value(value, 4) } else { value }
    let _ = result.set(key, safe)
  }
  result
}

///|
pub fn safe_filename(value : String) -> String {
  let mut result = ""
  for c in value {
    if (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_' ||
      c == '.' {
      result += c.to_string()
    } else {
      result += "_"
    }
  }
  let normalized = result
  if normalized == "" {
    "untitled"
  } else {
    normalized
  }
}

///|
pub fn safe_header(value : String) -> String {
  let mut result = ""
  for c in value {
    if c != '\r' && c != '\n' {
      result += c.to_string()
    }
  }
  result.trim().to_owned()
}

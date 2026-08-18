///|
/// JSON helpers intentionally operate on strings so the template engine can
/// remain backend independent while still producing valid structured output.
pub fn json_quote(value : String) -> String {
  let result = StringBuilder::new()
  result.write_char('"')
  for c in value {
    match c {
      '"' => result.write_string("\\\"")
      '\\' => result.write_string("\\\\")
      '\n' => result.write_string("\\n")
      '\r' => result.write_string("\\r")
      '\t' => result.write_string("\\t")
      '\b' => result.write_string("\\b")
      '\f' => result.write_string("\\f")
      _ => result.write_char(c)
    }
  }
  result.write_char('"')
  result.to_string()
}

///|
pub fn json_object(context : Context) -> String {
  let result = StringBuilder::new()
  result.write_char('{')
  let mut first = true
  for pair in context_to_sorted_pairs(context) {
    let (key, value) = pair
    if !first {
      result.write_char(',')
    }
    result.write_string(json_quote(key))
    result.write_char(':')
    result.write_string(json_quote(value))
    first = false
  }
  result.write_char('}')
  result.to_string()
}

///|
pub fn json_array(values : Array[String]) -> String {
  let result = StringBuilder::new()
  result.write_char('[')
  for index, value in values {
    if index > 0 {
      result.write_char(',')
    }
    result.write_string(json_quote(value))
  }
  result.write_char(']')
  result.to_string()
}

///|
pub fn json_lines(values : Array[(String, String)]) -> String {
  let result = StringBuilder::new()
  for index, pair in values {
    if index > 0 {
      result.write_char('\n')
    }
    let (key, value) = pair
    result.write_string(json_quote(key))
    result.write_char(':')
    result.write_string(json_quote(value))
  }
  result.to_string()
}

///|
pub fn json_is_quoted(value : String) -> Bool {
  value.length() >= 2 && value[0] == '"' && value[value.length() - 1] == '"'
}

///|
pub fn json_unquote(value : String) -> String {
  if !json_is_quoted(value) {
    return value
  }
  let body = value[1:value.length() - 1]
  let result = StringBuilder::new()
  let mut escaped = false
  for c in body {
    if escaped {
      match c {
        'n' => result.write_char('\n')
        'r' => result.write_char('\r')
        't' => result.write_char('\t')
        '"' => result.write_char('"')
        '\\' => result.write_char('\\')
        _ => result.write_char(c)
      }
      escaped = false
    } else if c == '\\' {
      escaped = true
    } else {
      result.write_char(c)
    }
  }
  if escaped {
    result.write_char('\\')
  }
  result.to_string()
}

///|
pub fn json_escape_html_safe(value : String) -> String {
  json_quote(escape_html(value))
}

///|
pub fn json_context_with_prefix(context : Context, prefix : String) -> String {
  json_object(context.with_prefix(prefix))
}

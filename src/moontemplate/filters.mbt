///|
fn escape_html(value : String) -> String {
  let mut output = ""
  for c in value {
    output += match c {
      '&' => "&amp;"
      '<' => "&lt;"
      '>' => "&gt;"
      '"' => "&quot;"
      _ if c.to_int() == 39 => "&#39;"
      _ => c.to_string()
    }
  }
  output
}

///|
fn escape_json(value : String) -> String {
  value.to_json().stringify()
}

///|
fn slugify(value : String) -> String {
  let mut output = ""
  let mut needs_separator = false
  for c in value.to_lower() {
    if c.is_ascii_alphabetic() || c.is_ascii_digit() {
      if needs_separator && output.length() > 0 {
        output += "-"
      }
      output += c.to_string()
      needs_separator = false
    } else if output.length() > 0 {
      needs_separator = true
    }
  }
  output
}

///|
fn register_builtin_filters(filters : Map[String, (String) -> String]) -> Unit {
  filters.set("trim", fn(value) { value.trim().to_owned() })
  filters.set("uppercase", fn(value) { value.to_upper() })
  filters.set("lowercase", fn(value) { value.to_lower() })
  filters.set("escape_html", escape_html)
  filters.set("escape_json", escape_json)
  filters.set("slugify", slugify)
}

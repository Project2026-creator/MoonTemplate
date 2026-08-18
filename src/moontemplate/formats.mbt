///|
/// Small output-format adapters shared by CLI integrations and applications.
pub fn format_key_value(
  context : Context,
  separator : String,
  newline : String,
) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(context) {
    let (key, value) = pair
    result.write_string(key)
    result.write_string(separator)
    result.write_string(value)
    result.write_string(newline)
  }
  result.to_string()
}

///|
pub fn format_json_lines(context : Context) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(context) {
    let (key, value) = pair
    result.write_string(json_quote(key))
    result.write_string(" = ")
    result.write_string(json_quote(value))
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn format_markdown_definition_list(
  entries : Array[(String, String)],
) -> String {
  let result = StringBuilder::new()
  for pair in entries {
    let (term, definition) = pair
    result.write_string(term)
    result.write_string("\n: ")
    result.write_string(definition)
    result.write_string("\n\n")
  }
  result.to_string()
}

///|
pub fn format_markdown_callout(kind : String, body : String) -> String {
  markdown_quote("**" + safe_header(kind).to_upper() + "** " + body)
}

///|
pub fn format_xml_attributes(values : Context) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(values) {
    let (key, value) = pair
    result.write_char(' ')
    result.write_string(safe_filename(key))
    result.write_string("=\"")
    result.write_string(escape_html(value))
    result.write_char('"')
  }
  result.to_string()
}

///|
pub fn format_xml_element(
  tag : String,
  attributes : Context,
  body : String,
) -> String {
  "<" +
  safe_filename(tag) +
  format_xml_attributes(attributes) +
  ">" +
  body +
  "</" +
  safe_filename(tag) +
  ">"
}

///|
pub fn format_html_document(
  title : String,
  body : String,
  language : String,
) -> String {
  let lang = if language.trim() == "" { "en" } else { safe_filename(language) }
  "<!doctype html><html lang=\"" +
  lang +
  "\"><head><meta charset=\"utf-8\"><title>" +
  escape_html(title) +
  "</title></head><body>" +
  body +
  "</body></html>"
}

///|
pub fn format_log(
  level : String,
  message : String,
  context : Context,
) -> String {
  "[" +
  safe_header(level).to_upper() +
  "] " +
  message +
  " " +
  json_object(context)
}

///|
pub fn format_diff(left : Context, right : Context) -> String {
  let result = StringBuilder::new()
  for key in context_diff(left, right) {
    result.write_string("~ ")
    result.write_string(key)
    result.write_string(": ")
    result.write_string(left.get_or(key, "<missing>"))
    result.write_string(" -> ")
    result.write_string(right.get_or(key, "<missing>"))
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn format_summary_table(summary : RenderSummary) -> String {
  markdown_table(["Metric", "Value"], [
    ["documents", summary.documents().to_string()],
    ["successful", summary.successful().to_string()],
    ["failed", summary.failed().to_string()],
    ["output_chars", summary.output_chars().to_string()],
    ["success_rate", summary.success_rate()],
  ])
}

///|
pub fn format_ini(section : String, context : Context) -> String {
  let body = format_key_value(context, "=", "\n")
  if section.trim() == "" {
    body
  } else {
    "[" + section + "]\n" + body
  }
}

///|
pub fn format_env(context : Context) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(context) {
    let (key, value) = pair
    result.write_string(safe_filename(key).to_upper())
    result.write_char('=')
    result.write_string(json_quote(value))
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn format_shell_assignments(context : Context) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(context) {
    let (key, value) = pair
    result.write_string(safe_filename(key))
    result.write_char('=')
    result.write_string("'")
    result.write_string(value.replace_all(old="'", new="'\\''"))
    result.write_string("' ")
  }
  result.to_string().trim_end().to_owned()
}

///|
pub fn format_csv_row(values : Array[String]) -> String {
  let result = StringBuilder::new()
  for index, value in values {
    if index > 0 {
      result.write_char(',')
    }
    result.write_string(csv_quote(value))
  }
  result.to_string()
}

///|
pub fn csv_quote(value : String) -> String {
  if value.contains(",") || value.contains("\"") || value.contains("\n") {
    "\"" + value.replace_all(old="\"", new="\"\"") + "\""
  } else {
    value
  }
}

///|
pub fn format_csv(
  headers : Array[String],
  rows : Array[Array[String]],
) -> String {
  let result = StringBuilder::new()
  result.write_string(format_csv_row(headers))
  for row in rows {
    result.write_char('\n')
    result.write_string(format_csv_row(row))
  }
  result.to_string()
}

///|
pub fn format_plain_list(
  items : Array[String],
  prefix : String,
  newline : String,
) -> String {
  let result = StringBuilder::new()
  for item in items {
    result.write_string(prefix)
    result.write_string(item)
    result.write_string(newline)
  }
  result.to_string()
}

///|
pub fn format_tree(items : Array[(Int, String)]) -> String {
  let result = StringBuilder::new()
  for pair in items {
    let (level, value) = pair
    result.write_string(text_repeat("  ", if level < 0 { 0 } else { level }))
    result.write_string("- ")
    result.write_string(value)
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn format_badge(label : String, value : String) -> String {
  "[" + safe_header(label) + ": " + safe_header(value) + "]"
}

///|
pub fn format_table_rows(
  rows : Array[Array[String]],
  separator : String,
) -> String {
  let result = StringBuilder::new()
  for index, row in rows {
    if index > 0 {
      result.write_char('\n')
    }
    result.write_string(row.join(separator))
  }
  result.to_string()
}

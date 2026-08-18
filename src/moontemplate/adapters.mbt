///|
/// Adapters for turning common application data into deterministic template
/// contexts without requiring a JSON dependency at every call site.
pub fn context_from_strings(values : Array[String]) -> Result[Context, String] {
  let context = Context::with_capacity(values.length())
  for entry in values {
    match entry.split_once("=") {
      Some((key, value)) if key.trim() != "" => {
        let _ = context.set(key.trim().to_owned(), value.to_owned())
      }
      _ => return Err("Invalid context entry: \{entry}")
    }
  }
  Ok(context)
}

///|
pub fn context_from_lines(source : String) -> Result[Context, String] {
  let entries = []
  for line in text_normalize_newlines(source).split("\n") {
    let trimmed = line.trim()
    if trimmed != "" && !trimmed.has_prefix("#") {
      entries.push(trimmed.to_owned())
    }
  }
  context_from_strings(entries)
}

///|
pub fn context_to_lines(context : Context) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(context) {
    let (key, value) = pair
    result.write_string(key)
    result.write_char('=')
    result.write_string(value)
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn context_from_columns(
  headers : Array[String],
  values : Array[String],
) -> Context {
  let context = Context::with_capacity(headers.length())
  for index in 0..<headers.length() {
    let value = if index < values.length() { values[index] } else { "" }
    let _ = context.set(headers[index], value)
  }
  context
}

///|
pub fn context_rows(
  headers : Array[String],
  rows : Array[Array[String]],
) -> Array[Context] {
  let result = []
  for row in rows {
    result.push(context_from_columns(headers, row))
  }
  result
}

///|
pub fn render_rows(
  engine : Engine,
  headers : Array[String],
  rows : Array[Array[String]],
) -> Array[String] {
  let result = []
  for context in context_rows(headers, rows) {
    result.push(engine.render(context.to_map()))
  }
  result
}

///|
pub fn render_csv(
  engine : Engine,
  headers : Array[String],
  rows : Array[Array[String]],
) -> String {
  render_rows(engine, headers, rows).join("\n")
}

///|
pub fn context_pick(context : Context, prefix : String) -> Context {
  let result = Context::new()
  for key in context.keys() {
    if key.has_prefix(prefix) {
      let short = if key.length() > prefix.length() {
        key[prefix.length():].to_owned()
      } else {
        ""
      }
      let _ = result.set(short, context.get_or(key, ""))
    }
  }
  result
}

///|
pub fn context_rename(
  context : Context,
  mappings : Array[(String, String)],
) -> Context {
  let result = Context::new()
  for key in context.keys() {
    let mut target = key
    for pair in mappings {
      let (from, to) = pair
      if key == from {
        target = to
      }
    }
    let _ = result.set(target, context.get_or(key, ""))
  }
  result
}

///|
pub fn context_filter_keys(
  context : Context,
  predicate : (String) -> Bool,
) -> Context {
  let result = Context::new()
  for key in context.keys() {
    if predicate(key) {
      let _ = result.set(key, context.get_or(key, ""))
    }
  }
  result
}

///|
pub fn context_map_values(
  context : Context,
  transform : (String) -> String,
) -> Context {
  let result = Context::new()
  for key in context.keys() {
    let _ = result.set(key, transform(context.get_or(key, "")))
  }
  result
}

///|
pub fn context_diff(left : Context, right : Context) -> Array[String] {
  let result = []
  let keys = left.keys()
  for key in right.keys() {
    if !keys.contains(key) {
      keys.push(key)
    }
  }
  keys.sort()
  for key in keys {
    let a = left.get_or(key, "")
    let b = right.get_or(key, "")
    if a != b {
      result.push(key)
    }
  }
  result
}

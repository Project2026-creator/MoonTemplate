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
/// A deliberately small argument model for the supported parameterized filters.
/// Keeping this private lets the public AST continue to store filter expressions
/// as strings while still giving the renderer typed values after validation.
priv enum FilterArgument {
  TextArgument(String)
  NumberArgument(Int)
}

///|
fn decode_filter_string(raw : String) -> Result[String, String] {
  if raw.length() < 2 || !raw.has_prefix("\"") || !raw.has_suffix("\"") {
    return Err("Filter string arguments must use double quotes")
  }
  let inner = raw.sub(start=1, end=raw.length() - 1)
  let mut value = ""
  let mut escaped = false
  for c in inner {
    if escaped {
      value += match c {
        'n' => "\n"
        'r' => "\r"
        't' => "\t"
        '"' => "\""
        '\\' => "\\"
        _ => return Err("Unsupported filter string escape")
      }
      escaped = false
    } else if c == '\\' {
      escaped = true
    } else if c == '"' {
      return Err("Unescaped quote in filter string argument")
    } else {
      value += c.to_string()
    }
  }
  if escaped {
    return Err("Incomplete filter string escape")
  }
  Ok(value)
}

///|
fn parse_filter_integer(raw : String) -> Result[Int, String] {
  let value = raw.trim().to_owned()
  if value == "" {
    return Err("Filter integer arguments cannot be empty")
  }
  let mut sign = 1
  let mut start = 0
  if value.has_prefix("-") {
    sign = -1
    start = 1
  } else if value.has_prefix("+") {
    start = 1
  }
  if start >= value.length() {
    return Err("Invalid filter integer argument")
  }
  let mut number = 0
  let mut digits = 0
  for c in value[start:] {
    if !c.is_ascii_digit() {
      return Err("Invalid filter integer argument")
    }
    number = number * 10 + c.to_int() - '0'.to_int()
    digits += 1
  }
  if digits == 0 {
    return Err("Invalid filter integer argument")
  }
  Ok(sign * number)
}

///|
fn parse_filter_argument(raw : String) -> Result[FilterArgument, String] {
  let value = raw.trim().to_owned()
  if value.has_prefix("\"") {
    match decode_filter_string(value) {
      Ok(decoded) => Ok(TextArgument(decoded))
      Err(err) => Err(err)
    }
  } else {
    match parse_filter_integer(value) {
      Ok(number) => Ok(NumberArgument(number))
      Err(err) => Err(err)
    }
  }
}

///|
fn parse_filter_call(
  raw : String,
) -> Result[(String, Array[FilterArgument]), String] {
  match raw.split_once("(") {
    None =>
      if raw.contains(")") {
        Err("Unexpected ')' in filter expression")
      } else {
        Ok((raw.trim().to_owned(), []))
      }
    Some((name_view, rest_view)) => {
      let name = name_view.trim().to_owned()
      let rest = rest_view.to_owned()
      if name == "" || !rest.has_suffix(")") {
        return Err("Filter call must end with ')' ")
      }
      let body = rest.sub(end=rest.length() - 1).trim()
      let args = []
      if !body.is_empty() {
        let mut current = ""
        let mut quoted = false
        let mut escaped = false
        for c in body {
          if quoted {
            current += c.to_string()
            if escaped {
              escaped = false
            } else if c == '\\' {
              escaped = true
            } else if c == '"' {
              quoted = false
            }
          } else if c == '"' {
            quoted = true
            current += c.to_string()
          } else if c == ',' {
            match parse_filter_argument(current) {
              Ok(argument) => args.push(argument)
              Err(err) => return Err(err)
            }
            current = ""
          } else {
            current += c.to_string()
          }
        }
        if quoted || escaped {
          return Err("Unterminated filter string argument")
        }
        match parse_filter_argument(current) {
          Ok(argument) => args.push(argument)
          Err(err) => return Err(err)
        }
      }
      Ok((name, args))
    }
  }
}

///|
fn validate_filter_expression(raw : String) -> Result[Unit, String] {
  let (name, args) = match parse_filter_call(raw) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  if args.length() == 0 {
    return Ok(())
  }
  match name {
    "replace" =>
      if args.length() != 2 {
        Err("replace expects two string arguments")
      } else {
        match (args[0], args[1]) {
          (TextArgument(_), TextArgument(_)) => Ok(())
          _ => Err("replace expects two string arguments")
        }
      }
    "truncate" =>
      if args.length() != 1 {
        Err("truncate expects one integer argument")
      } else {
        match args[0] {
          NumberArgument(_) => Ok(())
          _ => Err("truncate expects one integer argument")
        }
      }
    "default" =>
      if args.length() != 1 {
        Err("default expects one string argument")
      } else {
        match args[0] {
          TextArgument(_) => Ok(())
          _ => Err("default expects one string argument")
        }
      }
    _ => Err("Unknown parameterized filter")
  }
}

///|
fn truncate_unicode(value : String, limit : Int) -> String {
  if limit <= 0 {
    return ""
  }
  if value.char_length() <= limit {
    return value
  }
  match value.offset_of_nth_char(limit) {
    Some(offset) => value.sub(end=offset).to_owned()
    None => value
  }
}

///|
fn apply_filter_spec(value : String, raw : String) -> Result[String, String] {
  let (name, args) = match parse_filter_call(raw) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  if args.length() == 0 {
    return Ok(value)
  }
  match name {
    "replace" =>
      match (args[0], args[1]) {
        (TextArgument(old), TextArgument(new)) =>
          Ok(value.replace_all(old~, new~))
        _ => Err("replace expects two string arguments")
      }
    "truncate" =>
      match args[0] {
        NumberArgument(limit) => Ok(truncate_unicode(value, limit))
        _ => Err("truncate expects one integer argument")
      }
    "default" =>
      match args[0] {
        TextArgument(fallback) =>
          if value.trim().is_empty() {
            Ok(fallback)
          } else {
            Ok(value)
          }
        _ => Err("default expects one string argument")
      }
    _ => Ok(value)
  }
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

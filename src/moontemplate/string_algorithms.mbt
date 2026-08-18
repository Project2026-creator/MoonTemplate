///|
/// Deterministic string algorithms used by adapters and filters.
pub fn text_reverse(value : String) -> String {
  let chars = []
  for c in value {
    chars.push(c)
  }
  let result = StringBuilder::new()
  for index in 0..<chars.length() {
    result.write_char(chars[chars.length() - index - 1])
  }
  result.to_string()
}

///|
pub fn text_char_at(value : String, index : Int) -> String? {
  if index < 0 {
    return None
  }
  let mut current = 0
  for c in value {
    if current == index {
      return Some(c.to_string())
    }
    current += 1
  }
  None
}

///|
pub fn text_take(value : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  let result = StringBuilder::new()
  let mut seen = 0
  for c in value {
    if seen >= count {
      break
    }
    result.write_char(c)
    seen += 1
  }
  result.to_string()
}

///|
pub fn text_drop(value : String, count : Int) -> String {
  if count <= 0 {
    return value
  }
  let result = StringBuilder::new()
  let mut seen = 0
  for c in value {
    if seen >= count {
      result.write_char(c)
    }
    seen += 1
  }
  result.to_string()
}

///|
pub fn text_slice(value : String, start : Int, length : Int) -> String {
  if start < 0 || length <= 0 {
    return ""
  }
  text_take(text_drop(value, start), length)
}

///|
pub fn text_words(value : String) -> Array[String] {
  let result = []
  let mut current = ""
  for c in value {
    if c.is_ascii_whitespace() {
      if current != "" {
        result.push(current)
        current = ""
      }
    } else {
      current += c.to_string()
    }
  }
  if current != "" {
    result.push(current)
  }
  result
}

///|
pub fn text_join_non_empty(
  values : Array[String],
  separator : String,
) -> String {
  let kept = []
  for value in values {
    if value.trim() != "" {
      kept.push(value)
    }
  }
  kept.join(separator)
}

///|
pub fn text_kebab(value : String) -> String {
  let words = text_words(value)
  let result = []
  for word in words {
    result.push(word.to_lower())
  }
  result.join("-")
}

///|
pub fn text_snake(value : String) -> String {
  text_kebab(value).replace_all(old="-", new="_")
}

///|
pub fn text_title(value : String) -> String {
  let result = StringBuilder::new()
  let mut start = true
  for c in value {
    if c.is_ascii_whitespace() {
      result.write_char(c)
      start = true
    } else if start {
      result.write_string(c.to_string().to_upper())
      start = false
    } else {
      result.write_string(c.to_string().to_lower())
    }
  }
  result.to_string()
}

///|
pub fn text_is_integer(value : String) -> Bool {
  let trimmed = value.trim()
  if trimmed == "" {
    return false
  }
  let mut first = true
  let mut digits = 0
  for c in trimmed {
    if first && (c == '-' || c == '+') {
      first = false
      continue
    }
    if !c.is_ascii_digit() {
      return false
    }
    digits += 1
    first = false
  }
  digits > 0
}

///|
pub fn text_is_identifier(value : String) -> Bool {
  if value == "" {
    return false
  }
  let mut first = true
  for c in value {
    if first {
      if !c.is_ascii_alphabetic() && c != '_' {
        return false
      }
      first = false
    } else if !(c.is_ascii_alphabetic() || c.is_ascii_digit()) &&
      c != '_' &&
      c != '-' {
      return false
    }
  }
  true
}

///|
pub fn text_checksum(value : String) -> Int {
  let mut hash = 7
  for c in value {
    hash = (hash * 31 + c.to_int()) % 1_000_003
  }
  hash
}

///|
pub fn text_lines_with_numbers(value : String) -> Array[String] {
  let result = []
  for index, line in text_lines(value) {
    result.push("\{index + 1}: \{line}")
  }
  result
}

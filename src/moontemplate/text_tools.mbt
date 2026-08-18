///|
/// Stable text utilities used by filters, adapters, and generated documents.
pub fn text_repeat(value : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  let mut result = ""
  for _ in 0..<count {
    result += value
  }
  result
}

///|
pub fn text_indent(value : String, prefix : String) -> String {
  let mut result = ""
  let mut first = true
  for line in value.split("\n") {
    if !first {
      result += "\n"
    }
    result += prefix
    result += line.to_owned()
    first = false
  }
  result
}

///|
pub fn text_dedent(value : String) -> String {
  let lines = value.split("\n")
  let mut width = -1
  for line in lines {
    if line.trim() != "" {
      let mut leading = 0
      for c in line {
        if c == ' ' {
          leading += 1
        } else {
          break
        }
      }
      if width < 0 || leading < width {
        width = leading
      }
    }
  }
  if width <= 0 {
    return value
  }
  text_replace_all(value, text_repeat(" ", width), "")
}

///|
pub fn text_lines(value : String) -> Array[String] {
  let result = []
  for line in value.split("\n") {
    result.push(line.to_owned())
  }
  result
}

///|
pub fn text_line_count(value : String) -> Int {
  value.split("\n").length()
}

///|
pub fn text_first_non_empty_line(value : String) -> String? {
  for line in value.split("\n") {
    if line.trim() != "" {
      return Some(line.trim().to_owned())
    }
  }
  None
}

///|
pub fn text_wrap(value : String, width : Int) -> Array[String] {
  if width <= 0 {
    return if value == "" { [] } else { [value] }
  }
  let words = []
  for word in value.trim().split(" ") {
    if word != "" {
      words.push(word.to_owned())
    }
  }
  let lines = []
  let mut current = ""
  for word in words {
    if current == "" {
      current = word
    } else if current.char_length() + 1 + word.char_length() <= width {
      current += " " + word
    } else {
      lines.push(current)
      current = word
    }
  }
  if current != "" {
    lines.push(current)
  }
  lines
}

///|
pub fn text_pad_left(value : String, width : Int, fill : String) -> String {
  let missing = width - value.char_length()
  if missing <= 0 || fill == "" {
    return value
  }
  text_repeat(fill, missing) + value
}

///|
pub fn text_pad_right(value : String, width : Int, fill : String) -> String {
  let missing = width - value.char_length()
  if missing <= 0 || fill == "" {
    return value
  }
  value + text_repeat(fill, missing)
}

///|
pub fn text_center(value : String, width : Int, fill : String) -> String {
  let missing = width - value.char_length()
  if missing <= 0 || fill == "" {
    return value
  }
  let left = missing / 2
  text_repeat(fill, left) + value + text_repeat(fill, missing - left)
}

///|
pub fn text_count(value : String, needle : String) -> Int {
  if needle == "" {
    return 0
  }
  let mut count = 0
  let mut rest = value
  while rest.contains(needle) {
    count += 1
    match rest.split_once(needle) {
      Some((_, tail)) => rest = tail.to_owned()
      None => return count
    }
  }
  count
}

///|
pub fn text_replace_all(value : String, old : String, new : String) -> String {
  if old == "" {
    return value
  }
  let parts = value.split(old)
  parts.join(new)
}

///|
pub fn text_common_prefix(left : String, right : String) -> String {
  let result = StringBuilder::new()
  let a = []
  let b = []
  for c in left {
    a.push(c)
  }
  for c in right {
    b.push(c)
  }
  let limit = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<limit {
    if a[i] == b[i] {
      result.write_char(a[i])
    } else {
      break
    }
  }
  result.to_string()
}

///|
pub fn text_common_suffix(left : String, right : String) -> String {
  let a = []
  let b = []
  for c in left {
    a.push(c)
  }
  for c in right {
    b.push(c)
  }
  let mut result = ""
  let limit = if a.length() < b.length() { a.length() } else { b.length() }
  for offset in 0..<limit {
    let x = a[a.length() - offset - 1]
    let y = b[b.length() - offset - 1]
    if x == y {
      result = x.to_string() + result
    } else {
      break
    }
  }
  result
}

///|
pub fn text_is_ascii(value : String) -> Bool {
  for c in value {
    if c.to_int() > 127 {
      return false
    }
  }
  true
}

///|
pub fn text_is_blank(value : String) -> Bool {
  value.trim() == ""
}

///|
pub fn text_normalize_newlines(value : String) -> String {
  text_replace_all(text_replace_all(value, "\r\n", "\n"), "\r", "\n")
}

///|
pub(all) enum Token {
  Text(String)
  VarStart
  VarEnd
  TagStart
  TagEnd
  Pipe
  Identifier(String)
  In
  EOF
} derive(Debug, Eq)

///|
pub struct Lexer {
  input : String
  mut pos : Int
  mut in_tag : Bool
  mut trim_next_text : Bool
  mut lexical_error : String?
  mut lexical_error_offset : Int
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  {
    input,
    pos: 0,
    in_tag: false,
    trim_next_text: false,
    lexical_error: None,
    lexical_error_offset: 0,
  }
}

///|
fn trim_ascii_start(value : String) -> String {
  value.trim_start(chars=" \n\r\t").to_owned()
}

///|
fn trim_ascii_end(value : String) -> String {
  value.trim_end(chars=" \n\r\t").to_owned()
}

///|
fn Lexer::skip_comment(self : Lexer) -> Unit {
  self.pos += 2
  while self.pos < self.input.length() {
    if self.peek(2) == "#}" {
      self.pos += 2
      return
    }
    self.pos += 1
  }
  self.lexical_error = Some("Unterminated template comment")
  self.lexical_error_offset = self.pos
}

///|
fn Lexer::peek(self : Lexer, n : Int) -> String {
  if self.pos + n > self.input.length() {
    self.input[self.pos:self.input.length()].to_owned()
  } else {
    self.input[self.pos:self.pos + n].to_owned()
  }
}

///|
pub fn Lexer::next_token(self : Lexer) -> Token {
  if self.pos >= self.input.length() {
    return EOF
  }

  if !self.in_tag {
    let mut text = ""
    while self.pos < self.input.length() {
      if self.peek(2) == "{#" {
        if text.length() > 0 {
          break
        }
        self.skip_comment()
        continue
      }
      if self.peek(2) == "{{" || self.peek(2) == "{%" {
        let trim_left = self.peek(3) == "{{-" || self.peek(3) == "{%-"
        if self.trim_next_text {
          text = trim_ascii_start(text)
          if text.length() > 0 {
            self.trim_next_text = false
          }
        }
        if trim_left {
          text = trim_ascii_end(text)
        }
        if text.length() > 0 {
          return Text(text)
        }
        let tag = self.peek(2)
        self.pos += if trim_left { 3 } else { 2 }
        self.in_tag = true
        return if tag == "{{" { VarStart } else { TagStart }
      }
      text += self.peek(1)
      self.pos += 1
    }
    if self.trim_next_text {
      text = trim_ascii_start(text)
      if text.length() > 0 {
        self.trim_next_text = false
      }
    }
    return Text(text)
  }

  while self.pos < self.input.length() &&
        (
          self.peek(1) == " " ||
          self.peek(1) == "\n" ||
          self.peek(1) == "\r" ||
          self.peek(1) == "\t"
        ) {
    self.pos += 1
  }
  if self.pos >= self.input.length() {
    return EOF
  }

  if self.peek(3) == "-}}" || self.peek(2) == "}}" {
    let trim_right = self.peek(3) == "-}}"
    self.pos += if trim_right { 3 } else { 2 }
    self.in_tag = false
    if trim_right {
      self.trim_next_text = true
    }
    return VarEnd
  }
  if self.peek(3) == "-%}" || self.peek(2) == "%}" {
    let trim_right = self.peek(3) == "-%}"
    self.pos += if trim_right { 3 } else { 2 }
    self.in_tag = false
    if trim_right {
      self.trim_next_text = true
    }
    return TagEnd
  }
  if self.peek(1) == "|" {
    self.pos += 1
    return Pipe
  }

  let mut id = ""
  let mut parentheses = 0
  let mut quoted = false
  let mut escaped = false
  while self.pos < self.input.length() {
    let c = self.peek(1)
    if quoted {
      id += c
      self.pos += 1
      if escaped {
        escaped = false
      } else if c == "\\" {
        escaped = true
      } else if c == "\"" {
        quoted = false
      }
      continue
    }
    if c == "\"" && parentheses > 0 {
      quoted = true
      id += c
      self.pos += 1
      continue
    }
    if c == "(" {
      parentheses += 1
      id += c
      self.pos += 1
      continue
    }
    if c == ")" && parentheses > 0 {
      parentheses -= 1
      id += c
      self.pos += 1
      continue
    }
    if parentheses == 0 &&
      (
        c == " " ||
        c == "\n" ||
        c == "\r" ||
        c == "\t" ||
        c == "}" ||
        c == "%" ||
        c == "|"
      ) {
      break
    }
    id += c
    self.pos += 1
  }
  if id.length() > 0 {
    if id == "in" {
      return In
    }
    return Identifier(id)
  }
  self.pos += 1
  EOF
}

///|
pub fn Lexer::tokenize(self : Lexer) -> Array[Token] {
  let tokens = []
  while true {
    let tok = self.next_token()
    tokens.push(tok)
    if tok == EOF {
      break
    }
  }
  tokens
}

///|
fn Lexer::tokenize_with_positions(
  self : Lexer,
) -> (Array[Token], Array[Int], String?, Int) {
  let tokens = []
  let positions = []
  while true {
    positions.push(self.pos)
    let tok = self.next_token()
    tokens.push(tok)
    if tok == EOF {
      break
    }
  }
  (tokens, positions, self.lexical_error, self.lexical_error_offset)
}

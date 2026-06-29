
pub(all) enum Token {
  Text(String)
  VarStart
  VarEnd
  TagStart
  TagEnd
  Identifier(String)
  In
  EOF
} derive(Show, Eq)

pub struct Lexer {
  input: String
  mut pos: Int
  mut in_tag: Bool
}

pub fn Lexer::new(input: String) -> Lexer {
  { input, pos: 0, in_tag: false }
}

fn Lexer::peek(self: Lexer, n: Int) -> String {
  if self.pos + n > self.input.length() {
    self.input[self.pos : self.input.length()].to_string()
  } else {
    self.input[self.pos : self.pos + n].to_string()
  }
}

pub fn Lexer::next_token(self: Lexer) -> Token {
  if self.pos >= self.input.length() {
    return EOF
  }

  if !self.in_tag {
    let mut text = ""
    while self.pos < self.input.length() {
      if self.peek(2) == "{{" || self.peek(2) == "{%" {
        if text.length() > 0 { return Text(text) }
        let tag = self.peek(2)
        self.pos += 2
        self.in_tag = true
        return if tag == "{{" { VarStart } else { TagStart }
      }
      text += self.peek(1)
      self.pos += 1
    }
    return Text(text)
  }

  while self.pos < self.input.length() && (self.peek(1) == " " || self.peek(1) == "\n" || self.peek(1) == "\t") {
    self.pos += 1
  }
  if self.pos >= self.input.length() { return EOF }

  if self.peek(2) == "}}" { self.pos += 2; self.in_tag = false; return VarEnd }
  if self.peek(2) == "%}" { self.pos += 2; self.in_tag = false; return TagEnd }

  let mut id = ""
  while self.pos < self.input.length() {
    let c = self.peek(1)
    if c == " " || c == "\n" || c == "}" || c == "%" { break }
    id += c
    self.pos += 1
  }
  if id.length() > 0 {
    if id == "in" { return In }
    return Identifier(id)
  }
  self.pos += 1
  EOF
}
pub fn Lexer::tokenize(self: Lexer) -> Array[Token] {
  let tokens = []
  while true {
    let tok = self.next_token()
    tokens.push(tok)
    if tok == EOF { break }
  }
  tokens
}


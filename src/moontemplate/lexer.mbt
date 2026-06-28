
pub enum Token {
  Text(String)
  VarStart
  VarEnd
  TagStart
  TagEnd
  Identifier(String)
  EOF
} derive(Show, Eq)

pub struct Lexer {
  input: String
  mut pos: Int
}

pub fn Lexer::new(input: String) -> Lexer {
  { input, pos: 0 }
}

pub fn Lexer::next_token(self: Lexer) -> Token {
  if self.pos >= self.input.length() {
    return EOF
  }
  
  let rest = self.input.substring(start=self.pos)
  if rest.starts_with("{{") {
    self.pos += 2
    return VarStart
  }
  if rest.starts_with("}}") {
    self.pos += 2
    return VarEnd
  }
  if rest.starts_with("{%") {
    self.pos += 2
    return TagStart
  }
  if rest.starts_with("%}") {
    self.pos += 2
    return TagEnd
  }
  
  self.pos += 1
  return Text(rest.substring(end=1))
}

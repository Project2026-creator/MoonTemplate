
pub struct Parser {
  tokens: Array[Token]
  mut pos: Int
}

pub fn Parser::new(tokens: Array[Token]) -> Parser {
  { tokens, pos: 0 }
}

fn Parser::peek(self: Parser) -> Token {
  if self.pos >= self.tokens.length() {
    EOF
  } else {
    self.tokens[self.pos]
  }
}

fn Parser::advance(self: Parser) -> Token {
  let tok = self.peek()
  self.pos += 1
  tok
}

pub fn Parser::parse(self: Parser) -> Result[Array[Node], String] {
  let nodes = []
  while self.peek() != EOF {
    let node = self.parse_node()?
    match node {
      Some(n) => nodes.push(n)
      None => break
    }
  }
  Ok(nodes)
}

fn Parser::parse_node(self: Parser) -> Result[Node?, String] {
  let tok = self.advance()
  match tok {
    EOF => Ok(None)
    Text(s) => Ok(Some(Text(s)))
    VarStart => {
      let id_tok = self.advance()
      match id_tok {
        Identifier(name) => {
          let end_tok = self.advance()
          if end_tok != VarEnd {
            return Err("Expected }} after variable")
          }
          Ok(Some(Variable(name)))
        }
        _ => Err("Expected identifier inside {{ }}")
      }
    }
    _ => Err("Unexpected token")
  }
}

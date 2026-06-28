
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
  self.parse_until("EOF")
}

fn Parser::parse_until(self: Parser, end_token_ident: String) -> Result[Array[Node], String] {
  let nodes = []
  while self.peek() != EOF {
    if self.peek() == TagStart {
      let mut is_end = false
      if self.pos + 1 < self.tokens.length() {
        match self.tokens[self.pos + 1] {
          Identifier(id) => if id == end_token_ident { is_end = true }
          _ => ()
        }
      }
      if is_end { break }
    }

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
          if self.advance() != VarEnd { return Err("Expected }}") }
          Ok(Some(Variable(name)))
        }
        _ => Err("Expected identifier inside {{ }}")
      }
    }
    TagStart => {
      let cmd_tok = self.advance()
      match cmd_tok {
        Identifier(cmd) => {
          if cmd == "if" {
            let cond_tok = self.advance()
            match cond_tok {
              Identifier(cond) => {
                if self.advance() != TagEnd { return Err("Expected %}") }
                let true_branch = self.parse_until("endif")?
                self.advance() // TagStart
                self.advance() // Identifier("endif")
                self.advance() // TagEnd
                Ok(Some(If(cond, true_branch, [])))
              }
              _ => Err("Expected condition in if")
            }
          } else {
            Err("Unknown tag command")
          }
        }
        _ => Err("Expected command inside {% %}")
      }
    }
    _ => Err("Unexpected token")
  }
}


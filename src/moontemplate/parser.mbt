///|
pub struct Parser {
  tokens : Array[Token]
  mut pos : Int
}

///|
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::peek(self : Parser) -> Token {
  if self.pos >= self.tokens.length() {
    EOF
  } else {
    self.tokens[self.pos]
  }
}

///|
fn Parser::peek_n(self : Parser, offset : Int) -> Token {
  let index = self.pos + offset
  if index >= self.tokens.length() {
    EOF
  } else {
    self.tokens[index]
  }
}

///|
fn Parser::advance(self : Parser) -> Token {
  let tok = self.peek()
  self.pos += 1
  tok
}

///|
pub fn Parser::parse(self : Parser) -> Result[Array[Node], String] {
  self.parse_until([])
}

///|
fn Parser::parse_until(
  self : Parser,
  end_token_idents : Array[String],
) -> Result[Array[Node], String] {
  let nodes = []
  while self.peek() != EOF {
    match self.peek_tag_identifier() {
      Some(id) if end_token_idents.contains(id) => break
      _ => ()
    }
    match self.parse_node() {
      Ok(Some(n)) => nodes.push(n)
      Ok(None) => break
      Err(e) => return Err(e)
    }
  }
  Ok(nodes)
}

///|
fn Parser::peek_tag_identifier(self : Parser) -> String? {
  if self.peek() != TagStart {
    return None
  }
  match self.peek_n(1) {
    Identifier(id) => Some(id)
    _ => None
  }
}

///|
fn Parser::consume_token(
  self : Parser,
  expected : Token,
  message : String,
) -> Result[Unit, String] {
  let actual = self.advance()
  if actual == expected {
    Ok(())
  } else {
    Err(message)
  }
}

///|
fn Parser::consume_tag_command(
  self : Parser,
  command : String,
  message : String,
) -> Result[Unit, String] {
  match self.consume_token(TagStart, message) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  match self.advance() {
    Identifier(name) if name == command => ()
    _ => return Err(message)
  }
  self.consume_token(TagEnd, message)
}

///|
fn Parser::parse_filters(self : Parser) -> Result[Array[String], String] {
  let filters = []
  while self.peek() == Pipe {
    let _ = self.advance()
    match self.advance() {
      Identifier(name) => filters.push(name)
      _ => return Err("Expected filter name after |")
    }
  }
  Ok(filters)
}

///|
fn Parser::parse_node(self : Parser) -> Result[Node?, String] {
  let tok = self.advance()
  match tok {
    EOF => Ok(None)
    Text(s) => Ok(Some(Text(s)))
    VarStart => {
      let id_tok = self.advance()
      match id_tok {
        Identifier(name) => {
          let filters = match self.parse_filters() {
            Ok(value) => value
            Err(err) => return Err(err)
          }
          match self.consume_token(VarEnd, "Expected }}") {
            Ok(_) => ()
            Err(err) => return Err(err)
          }
          Ok(Some(Variable(name, filters)))
        }
        _ => Err("Expected identifier inside {{ }}")
      }
    }
    TagStart => {
      let cmd_tok = self.advance()
      match cmd_tok {
        Identifier(cmd) =>
          if cmd == "if" {
            let cond_tok = self.advance()
            match cond_tok {
              Identifier(cond) => {
                match self.consume_token(TagEnd, "Expected %}") {
                  Ok(_) => ()
                  Err(err) => return Err(err)
                }
                let true_branch = match self.parse_until(["else", "endif"]) {
                  Ok(value) => value
                  Err(err) => return Err(err)
                }
                if self.peek_tag_identifier() == Some("else") {
                  match
                    self.consume_tag_command("else", "Expected {% else %}") {
                    Ok(_) => ()
                    Err(err) => return Err(err)
                  }
                  let false_branch = match self.parse_until(["endif"]) {
                    Ok(value) => value
                    Err(err) => return Err(err)
                  }
                  match
                    self.consume_tag_command("endif", "Expected {% endif %}") {
                    Ok(_) => ()
                    Err(err) => return Err(err)
                  }
                  Ok(Some(If(cond, true_branch, false_branch)))
                } else {
                  match
                    self.consume_tag_command("endif", "Expected {% endif %}") {
                    Ok(_) => ()
                    Err(err) => return Err(err)
                  }
                  Ok(Some(If(cond, true_branch, [])))
                }
              }
              _ => Err("Expected condition in if")
            }
          } else if cmd == "for" {
            let var_tok = self.advance()
            match var_tok {
              Identifier(v) => {
                if self.advance() != In {
                  return Err("Expected in")
                }
                let iter_tok = self.advance()
                match iter_tok {
                  Identifier(iter) => {
                    match self.consume_token(TagEnd, "Expected %}") {
                      Ok(_) => ()
                      Err(err) => return Err(err)
                    }
                    let body = match self.parse_until(["endfor"]) {
                      Ok(value) => value
                      Err(err) => return Err(err)
                    }
                    match
                      self.consume_tag_command(
                        "endfor", "Expected {% endfor %}",
                      ) {
                      Ok(_) => ()
                      Err(err) => return Err(err)
                    }
                    Ok(Some(For(v, iter, body)))
                  }
                  _ => Err("Expected iterable in for loop")
                }
              }
              _ => Err("Expected variable name in for loop")
            }
          } else {
            Err("Unknown tag command")
          }
        _ => Err("Expected command inside {% %}")
      }
    }
    _ => Err("Unexpected token")
  }
}

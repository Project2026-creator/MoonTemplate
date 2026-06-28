
pub struct Engine {
  nodes: Array[Node]
}

pub fn Engine::new(template: String) -> Result[Engine, String] {
  let lexer = Lexer::new(template)
  let tokens = lexer.tokenize()
  let parser = Parser::new(tokens)
  let nodes = parser.parse()?
  Ok({ nodes })
}

pub fn Engine::render(self: Engine, context: Map[String, String]) -> String {
  let mut result = ""
  for node in self.nodes {
    match node {
      Text(s) => result += s
      Variable(name) => {
        match context.get(name) {
          Some(val) => result += val
          None => result += "" // silent ignore
        }
      }
      _ => ()
    }
  }
  result
}

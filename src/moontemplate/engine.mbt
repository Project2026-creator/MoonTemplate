
pub struct Engine {
  nodes: Array[Node]
  filters: Map[String, (String) -> String]
}

pub fn Engine::new(template: String) -> Result[Engine, String] {
  let lexer = Lexer::new(template)
  let tokens = lexer.tokenize()
  let parser = Parser::new(tokens)
  let nodes = parser.parse()?
  Ok({ nodes, filters: Map::new() })
}

pub fn Engine::register_filter(self: Engine, name: String, filter: (String) -> String) -> Unit {
  self.filters.set(name, filter)
}

pub fn Engine::render(self: Engine, context: Map[String, String]) -> String {
  self.render_nodes(self.nodes, context)
}

fn Engine::render_nodes(self: Engine, nodes: Array[Node], context: Map[String, String]) -> String {
  let mut result = ""
  for node in nodes {
    match node {
      Text(s) => result += s
      Variable(name) => {
        let mut val = match context.get(name) {
          Some(v) => v
          None => ""
        }
        result += val
      }
      If(cond, true_branch, false_branch) => {
        let is_true = match context.get(cond) {
          Some(val) => val != "" && val != "false" && val != "0"
          None => false
        }
        if is_true {
          result += self.render_nodes(true_branch, context)
        } else {
          result += self.render_nodes(false_branch, context)
        }
      }
      _ => ()
    }
  }
  result
}


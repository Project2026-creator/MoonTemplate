
pub struct Engine {
  nodes: Array[Node]
  filters: Map[String, (String) -> String]
}

pub fn Engine::new(template: String) -> Result[Engine, String] {
  let lexer = Lexer::new(template)
  let tokens = lexer.tokenize()
  let parser = Parser::new(tokens)
  match parser.parse() {
    Ok(nodes) => {
      let filters : Map[String, (String) -> String] = {}
      Ok({ nodes, filters })
    }
    Err(e) => Err(e)
  }
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
        let val = match context.get(name) {
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
      For(var_name, iterable, body) => {
        match context.get(iterable) {
          Some(val) => {
            let items = val.split(",")
            for item in items {
              let new_ctx : Map[String, String] = {}
              for k, v in context {
                new_ctx.set(k, v)
              }
              new_ctx.set(var_name, item.to_string())
              result += self.render_nodes(body, new_ctx)
            }
          }
          None => ()
        }
      }
    }
  }
  result
}


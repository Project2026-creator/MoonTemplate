///|
pub struct Engine {
  nodes : Array[Node]
  filters : Map[String, (String) -> String]
}

///|
pub fn Engine::new(template : String) -> Result[Engine, String] {
  let lexer = Lexer::new(template)
  let tokens = lexer.tokenize()
  let parser = Parser::new(tokens)
  match parser.parse() {
    Ok(nodes) => {
      let filters : Map[String, (String) -> String] = Map([], capacity=4)
      filters.set("trim", fn(value) { value.trim().to_owned() })
      filters.set("uppercase", fn(value) { value.to_upper() })
      filters.set("lowercase", fn(value) { value.to_lower() })
      Ok({ nodes, filters })
    }
    Err(e) => Err(e)
  }
}

///|
pub fn Engine::register_filter(
  self : Engine,
  name : String,
  filter : (String) -> String,
) -> Unit {
  self.filters.set(name, filter)
}

///|
pub fn Engine::render(self : Engine, context : Map[String, String]) -> String {
  self.render_nodes(self.nodes, context)
}

///|
fn Engine::render_nodes(
  self : Engine,
  nodes : Array[Node],
  context : Map[String, String],
) -> String {
  let mut result = ""
  for node in nodes {
    match node {
      Text(s) => result += s
      Variable(name, filters) => {
        let base = match context.get(name) {
          Some(v) => v
          None => ""
        }
        result += self.apply_filters(base, filters)
      }
      If(cond, true_branch, false_branch) => {
        let is_true = match context.get(cond) {
          Some(val) => val.trim() != "" && val != "false" && val != "0"
          None => false
        }
        if is_true {
          result += self.render_nodes(true_branch, context)
        } else {
          result += self.render_nodes(false_branch, context)
        }
      }
      For(var_name, iterable, body) =>
        match context.get(iterable) {
          Some(val) if val.trim() != "" => {
            let items = parse_iterable(val)
            for item in items {
              let new_ctx : Map[String, String] = Map(
                [],
                capacity=context.length() + 1,
              )
              for k, v in context {
                new_ctx.set(k, v)
              }
              new_ctx.set(var_name, item)
              result += self.render_nodes(body, new_ctx)
            }
          }
          None => ()
          _ => ()
        }
    }
  }
  result
}

///|
fn Engine::apply_filters(
  self : Engine,
  value : String,
  filters : Array[String],
) -> String {
  let mut rendered = value
  for filter_name in filters {
    match self.filters.get(filter_name) {
      Some(filter) => rendered = filter(rendered)
      None => ()
    }
  }
  rendered
}

///|
fn parse_iterable(raw : String) -> Array[String] {
  let items = []
  for item in raw.split(",") {
    let trimmed = item.trim()
    if trimmed != "" {
      items.push(trimmed.to_owned())
    }
  }
  items
}

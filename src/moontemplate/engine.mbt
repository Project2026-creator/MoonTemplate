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
      register_builtin_filters(filters)
      Ok({ nodes, filters })
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse a template while retaining source-aware diagnostics.
pub fn Engine::new_with_diagnostics(
  template : String,
) -> Result[Engine, Array[Diagnostic]] {
  let lexer = Lexer::new(template)
  let (tokens, positions, lexical_error, error_offset) = lexer.tokenize_with_positions()
  match lexical_error {
    Some(message) =>
      Err([make_diagnostic(Lexical, message, template, error_offset)])
    None => {
      let parser = Parser::new_with_positions(tokens, positions, template)
      match parser.parse_with_diagnostics() {
        Ok(nodes) => {
          let filters : Map[String, (String) -> String] = Map([], capacity=4)
          register_builtin_filters(filters)
          Ok({ nodes, filters })
        }
        Err(diagnostics) => Err(diagnostics)
      }
    }
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
/// Render with strict filter validation and structured runtime failures.
pub fn Engine::render_strict(
  self : Engine,
  context : Map[String, String],
) -> Result[String, Array[Diagnostic]] {
  self.render_nodes_strict(self.nodes, context)
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
fn Engine::render_nodes_strict(
  self : Engine,
  nodes : Array[Node],
  context : Map[String, String],
) -> Result[String, Array[Diagnostic]] {
  let mut result = ""
  for node in nodes {
    match node {
      Text(s) => result += s
      Variable(name, filters) => {
        let base = match context.get(name) {
          Some(v) => v
          None => ""
        }
        match self.apply_filters_strict(base, filters) {
          Ok(value) => result += value
          Err(diagnostic) => return Err([diagnostic])
        }
      }
      If(cond, true_branch, false_branch) => {
        let is_true = match context.get(cond) {
          Some(val) => val.trim() != "" && val != "false" && val != "0"
          None => false
        }
        let branch = if is_true { true_branch } else { false_branch }
        match self.render_nodes_strict(branch, context) {
          Ok(value) => result += value
          Err(diagnostics) => return Err(diagnostics)
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
              match self.render_nodes_strict(body, new_ctx) {
                Ok(value) => result += value
                Err(diagnostics) => return Err(diagnostics)
              }
            }
          }
          None => ()
          _ => ()
        }
    }
  }
  Ok(result)
}

///|
fn Engine::apply_filters(
  self : Engine,
  value : String,
  filters : Array[String],
) -> String {
  let mut rendered = value
  for filter_name in filters {
    match filter_name.split_once("(") {
      Some(_) =>
        match apply_filter_spec(rendered, filter_name) {
          Ok(value) => rendered = value
          Err(_) => ()
        }
      None =>
        match self.filters.get(filter_name) {
          Some(filter) => rendered = filter(rendered)
          None => ()
        }
    }
  }
  rendered
}

///|
fn Engine::apply_filters_strict(
  self : Engine,
  value : String,
  filters : Array[String],
) -> Result[String, Diagnostic] {
  let mut rendered = value
  for filter_name in filters {
    match filter_name.split_once("(") {
      Some(_) =>
        match apply_filter_spec(rendered, filter_name) {
          Ok(value) => rendered = value
          Err(message) => return Err(make_runtime_filter_diagnostic(message))
        }
      None =>
        match self.filters.get(filter_name) {
          Some(filter) => rendered = filter(rendered)
          None =>
            return Err(
              make_runtime_filter_diagnostic("Unknown filter: \{filter_name}"),
            )
        }
    }
  }
  Ok(rendered)
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

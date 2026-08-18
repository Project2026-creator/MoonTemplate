///|
/// A named collection of parsed templates. Bundles are useful for page
/// layouts, email families, and code-generation projects.
pub struct TemplateBundle {
  templates : Map[String, Engine]
  order : Array[String]
}

///|
pub fn TemplateBundle::new() -> TemplateBundle {
  { templates: Map([], capacity=8), order: [] }
}

///|
pub fn TemplateBundle::add(
  self : TemplateBundle,
  name : String,
  source : String,
) -> Result[Unit, String] {
  let normalized = name.trim()
  if normalized == "" {
    return Err("Template name cannot be empty")
  }
  let engine = match Engine::new(source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if self.templates.get(normalized.to_owned()) is None {
    self.order.push(normalized.to_owned())
  }
  self.templates.set(normalized.to_owned(), engine)
  Ok(())
}

///|
pub fn TemplateBundle::add_engine(
  self : TemplateBundle,
  name : String,
  engine : Engine,
) -> Result[Unit, String] {
  let normalized = name.trim()
  if normalized == "" {
    return Err("Template name cannot be empty")
  }
  if self.templates.get(normalized.to_owned()) is None {
    self.order.push(normalized.to_owned())
  }
  self.templates.set(normalized.to_owned(), engine)
  Ok(())
}

///|
pub fn TemplateBundle::get(self : TemplateBundle, name : String) -> Engine? {
  self.templates.get(name)
}

///|
pub fn TemplateBundle::contains(self : TemplateBundle, name : String) -> Bool {
  self.templates.get(name) is Some(_)
}

///|
pub fn TemplateBundle::remove(self : TemplateBundle, name : String) -> Bool {
  if self.templates.get(name) is Some(_) {
    self.templates.remove(name)
    let remaining = []
    for item in self.order {
      if item != name {
        remaining.push(item)
      }
    }
    self.order.clear()
    for item in remaining {
      self.order.push(item)
    }
    true
  } else {
    false
  }
}

///|
pub fn TemplateBundle::names(self : TemplateBundle) -> Array[String] {
  self.order.copy()
}

///|
pub fn TemplateBundle::length(self : TemplateBundle) -> Int {
  self.order.length()
}

///|
pub fn TemplateBundle::render(
  self : TemplateBundle,
  name : String,
  context : Map[String, String],
) -> Result[String, String] {
  match self.get(name) {
    Some(engine) => Ok(engine.render(context))
    None => Err("Unknown template: \{name}")
  }
}

///|
pub fn TemplateBundle::render_with_context(
  self : TemplateBundle,
  name : String,
  context : Context,
) -> Result[String, String] {
  self.render(name, context.to_map())
}

///|
pub fn TemplateBundle::render_all(
  self : TemplateBundle,
  context : Context,
) -> Array[(String, String)] {
  let result = []
  for name in self.order {
    match self.render_with_context(name, context) {
      Ok(output) => result.push((name, output))
      Err(_) => ()
    }
  }
  result
}

///|
pub fn TemplateBundle::stats(self : TemplateBundle) -> TemplateStats {
  let result : TemplateStats = {
    node_count: 0,
    text_nodes: 0,
    variable_nodes: 0,
    if_nodes: 0,
    for_nodes: 0,
    filter_count: 0,
    max_depth: 0,
    literal_chars: 0,
  }
  for name in self.order {
    match self.templates.get(name) {
      Some(engine) => {
        let stats = engine.stats()
        result.node_count += stats.node_count()
        result.text_nodes += stats.text_nodes()
        result.variable_nodes += stats.variable_nodes()
        result.if_nodes += stats.if_nodes()
        result.for_nodes += stats.for_nodes()
        result.filter_count += stats.filter_count()
        result.literal_chars += stats.literal_chars()
        if stats.max_depth() > result.max_depth {
          result.max_depth = stats.max_depth()
        }
      }
      None => ()
    }
  }
  result
}

///|
pub fn bundle_from_pairs(
  templates : Array[(String, String)],
) -> Result[TemplateBundle, String] {
  let bundle = TemplateBundle::new()
  for pair in templates {
    let (name, source) = pair
    match bundle.add(name, source) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(bundle)
}

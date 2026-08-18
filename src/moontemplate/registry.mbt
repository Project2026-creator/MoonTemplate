///|
/// A registry gives long-running applications one place to manage named
/// templates, aliases, and cache statistics.
pub struct TemplateRegistry {
  bundle : TemplateBundle
  aliases : Map[String, String]
  cache : TemplateCache
}

///|
pub fn TemplateRegistry::new(cache_capacity : Int) -> TemplateRegistry {
  {
    bundle: TemplateBundle::new(),
    aliases: Map([], capacity=8),
    cache: TemplateCache::new(cache_capacity),
  }
}

///|
pub fn TemplateRegistry::register(
  self : TemplateRegistry,
  name : String,
  source : String,
) -> Result[Unit, String] {
  self.bundle.add(name, source)
}

///|
pub fn TemplateRegistry::shortcut(
  self : TemplateRegistry,
  shortcut : String,
  target : String,
) -> Bool {
  if shortcut.trim() == "" || target.trim() == "" {
    return false
  }
  self.aliases.set(shortcut.trim().to_owned(), target.trim().to_owned())
  true
}

///|
pub fn TemplateRegistry::resolve(
  self : TemplateRegistry,
  name : String,
) -> String {
  match self.aliases.get(name) {
    Some(target) => target
    None => name
  }
}

///|
pub fn TemplateRegistry::contains(
  self : TemplateRegistry,
  name : String,
) -> Bool {
  self.bundle.contains(self.resolve(name))
}

///|
pub fn TemplateRegistry::names(self : TemplateRegistry) -> Array[String] {
  self.bundle.names()
}

///|
pub fn TemplateRegistry::render(
  self : TemplateRegistry,
  name : String,
  context : Context,
) -> Result[String, String] {
  let resolved = self.resolve(name)
  match self.bundle.get(resolved) {
    Some(engine) => Ok(engine.render(context.to_map()))
    None => Err("Unknown registered template: \{name}")
  }
}

///|
pub fn TemplateRegistry::compile_cached(
  self : TemplateRegistry,
  key : String,
  source : String,
) -> Result[Engine, String] {
  self.cache.compile(key, source)
}

///|
pub fn TemplateRegistry::cache_hit_rate(self : TemplateRegistry) -> String {
  self.cache.hit_rate()
}

///|
pub fn TemplateRegistry::cache_keys(self : TemplateRegistry) -> Array[String] {
  self.cache.keys()
}

///|
pub fn TemplateRegistry::remove(self : TemplateRegistry, name : String) -> Bool {
  self.bundle.remove(name)
}

///|
pub fn TemplateRegistry::audit(self : TemplateRegistry) -> Array[String] {
  let problems = []
  for name in self.bundle.names() {
    match self.bundle.get(name) {
      Some(engine) =>
        for key in engine.required_variables() {
          if key == "" {
            problems.push(name)
          }
        }
      None => problems.push(name)
    }
  }
  problems
}

///|
pub fn registry_from_bundle(
  bundle : TemplateBundle,
  cache_capacity : Int,
) -> TemplateRegistry {
  let registry = TemplateRegistry::new(cache_capacity)
  for name in bundle.names() {
    match bundle.get(name) {
      Some(engine) => {
        let _ = registry.bundle.add_engine(name, engine)
      }
      None => ()
    }
  }
  registry
}

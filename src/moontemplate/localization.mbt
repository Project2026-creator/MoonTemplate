///|
/// Minimal locale catalog for applications that need deterministic fallback
/// behavior while rendering translated templates.
pub struct LocaleCatalog {
  entries : Map[String, Context]
  fallback : String
} derive(Debug)

///|
pub fn LocaleCatalog::new(fallback : String) -> LocaleCatalog {
  {
    entries: Map([], capacity=4),
    fallback: if fallback == "" {
      "en"
    } else {
      fallback
    },
  }
}

///|
pub fn LocaleCatalog::add(
  self : LocaleCatalog,
  locale : String,
  values : Context,
) -> LocaleCatalog {
  if locale.trim() != "" {
    self.entries.set(locale.trim().to_owned(), values)
  }
  self
}

///|
pub fn LocaleCatalog::fallback(self : LocaleCatalog) -> String {
  self.fallback
}

///|
pub fn LocaleCatalog::locales(self : LocaleCatalog) -> Array[String] {
  let result = []
  for locale, _ in self.entries {
    result.push(locale)
  }
  result.sort()
  result
}

///|
pub fn LocaleCatalog::translate(
  self : LocaleCatalog,
  locale : String,
  key : String,
  fallback : String,
) -> String {
  let values = match self.entries.get(locale) {
    Some(value) => value
    None =>
      match self.entries.get(self.fallback) {
        Some(value) => value
        None => return fallback
      }
  }
  values.get_or(key, fallback)
}

///|
pub fn LocaleCatalog::context(self : LocaleCatalog, locale : String) -> Context {
  match self.entries.get(locale) {
    Some(value) => value
    None =>
      match self.entries.get(self.fallback) {
        Some(value) => value
        None => Context::new()
      }
  }
}

///|
pub fn localized_render(
  engine : Engine,
  catalog : LocaleCatalog,
  locale : String,
  context : Context,
) -> String {
  let merged = Context::new().merge(catalog.context(locale)).merge(context)
  engine.render(merged.to_map())
}

///|
pub fn locale_chain(locale : String) -> Array[String] {
  let result = []
  let normalized = locale.trim().to_owned()
  if normalized != "" {
    result.push(normalized)
  }
  match normalized.split_once("-") {
    Some((language, _)) if language != "" => result.push(language.to_owned())
    None => ()
    _ => ()
  }
  result
}

///|
pub fn catalog_from_pairs(
  fallback : String,
  pairs : Array[(String, String, String)],
) -> LocaleCatalog {
  let catalog = LocaleCatalog::new(fallback)
  for pair in pairs {
    let (locale, key, value) = pair
    let context = catalog.context(locale)
    let _ = context.set(key, value)
    let _ = catalog.add(locale, context)
  }
  catalog
}

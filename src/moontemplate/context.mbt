///|
/// A small, deterministic context builder for applications that render many
/// templates with the same request data.
pub struct Context {
  values : Map[String, String]
  mut frozen : Bool
} derive(Debug, Eq)

///|
pub fn Context::new() -> Context {
  { values: Map([], capacity=8), frozen: false }
}

///|
pub fn Context::with_capacity(capacity : Int) -> Context {
  {
    values: Map([], capacity=if capacity < 0 { 0 } else { capacity }),
    frozen: false,
  }
}

///|
pub fn Context::from_pairs(pairs : Array[(String, String)]) -> Context {
  let context = Context::with_capacity(pairs.length())
  for pair in pairs {
    let (key, value) = pair
    let _ = context.set(key, value)
  }
  context
}

///|
pub fn Context::set(self : Context, key : String, value : String) -> Context {
  if !self.frozen && key.trim() != "" {
    self.values.set(key.trim().to_owned(), value)
  }
  self
}

///|
pub fn Context::set_if_absent(
  self : Context,
  key : String,
  value : String,
) -> Context {
  if !self.contains(key) {
    self.set(key, value)
  } else {
    self
  }
}

///|
pub fn Context::set_bool(self : Context, key : String, value : Bool) -> Context {
  self.set(key, if value { "true" } else { "false" })
}

///|
pub fn Context::set_int(self : Context, key : String, value : Int) -> Context {
  self.set(key, value.to_string())
}

///|
pub fn Context::get(self : Context, key : String) -> String? {
  self.values.get(key)
}

///|
pub fn Context::get_or(
  self : Context,
  key : String,
  fallback : String,
) -> String {
  match self.get(key) {
    Some(value) => value
    None => fallback
  }
}

///|
pub fn Context::contains(self : Context, key : String) -> Bool {
  self.values.get(key) is Some(_)
}

///|
pub fn Context::remove(self : Context, key : String) -> Context {
  if !self.frozen {
    self.values.remove(key)
  }
  self
}

///|
pub fn Context::length(self : Context) -> Int {
  self.values.length()
}

///|
pub fn Context::keys(self : Context) -> Array[String] {
  let result = []
  for key, _ in self.values {
    result.push(key)
  }
  result.sort()
  result
}

///|
pub fn Context::freeze(self : Context) -> Context {
  self.frozen = true
  self
}

///|
pub fn Context::is_frozen(self : Context) -> Bool {
  self.frozen
}

///|
pub fn Context::merge(self : Context, other : Context) -> Context {
  if !self.frozen {
    for key, value in other.values {
      self.values.set(key, value)
    }
  }
  self
}

///|
pub fn Context::subset(self : Context, requested : Array[String]) -> Context {
  let result = Context::with_capacity(requested.length())
  for key in requested {
    match self.get(key) {
      Some(value) => {
        let _ = result.set(key, value)
      }
      None => ()
    }
  }
  result
}

///|
pub fn Context::to_map(self : Context) -> Map[String, String] {
  let result = Map([], capacity=self.length())
  for key, value in self.values {
    let _ = result.set(key, value)
  }
  result
}

///|
pub fn Context::with_prefix(self : Context, prefix : String) -> Context {
  let result = Context::with_capacity(self.length())
  let normalized = prefix.trim()
  for key, value in self.values {
    let _ = result.set(
      if normalized == "" {
        key
      } else {
        "\{normalized}.\{key}"
      },
      value,
    )
  }
  result
}

///|
pub fn Context::validate(
  self : Context,
  required : Array[String],
) -> Array[String] {
  let missing = []
  for key in required {
    if !self.contains(key) {
      missing.push(key)
    }
  }
  missing
}

///|
pub fn context_from_map(values : Map[String, String]) -> Context {
  let result = Context::with_capacity(values.length())
  for key, value in values {
    let _ = result.set(key, value)
  }
  result
}

///|
pub fn context_overlay(
  base : Context,
  overrides : Map[String, String],
) -> Context {
  let result = Context::from_pairs([])
  let _ = result.merge(base)
  for key, value in overrides {
    let _ = result.set(key, value)
  }
  result
}

///|
pub fn context_to_sorted_pairs(context : Context) -> Array[(String, String)] {
  let result = []
  for key in context.keys() {
    result.push((key, context.get_or(key, "")))
  }
  result
}

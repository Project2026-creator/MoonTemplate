///|
/// A bounded parsed-template cache. It keeps insertion order explicit so that
/// eviction is deterministic and easy to inspect in production diagnostics.
pub struct TemplateCache {
  entries : Array[CacheEntry]
  capacity : Int
  mut hits : Int
  mut misses : Int
}

///|
struct CacheEntry {
  key : String
  engine : Engine
}

///|
pub fn TemplateCache::new(capacity : Int) -> TemplateCache {
  {
    entries: [],
    capacity: if capacity < 0 {
      0
    } else {
      capacity
    },
    hits: 0,
    misses: 0,
  }
}

///|
pub fn TemplateCache::capacity(self : TemplateCache) -> Int {
  self.capacity
}

///|
pub fn TemplateCache::hits(self : TemplateCache) -> Int {
  self.hits
}

///|
pub fn TemplateCache::misses(self : TemplateCache) -> Int {
  self.misses
}

///|
pub fn TemplateCache::len(self : TemplateCache) -> Int {
  self.entries.length()
}

///|
pub fn TemplateCache::get(self : TemplateCache, key : String) -> Engine? {
  for entry in self.entries {
    if entry.key == key {
      self.hits += 1
      return Some(entry.engine)
    }
  }
  self.misses += 1
  None
}

///|
pub fn TemplateCache::compile(
  self : TemplateCache,
  key : String,
  source : String,
) -> Result[Engine, String] {
  match self.get(key) {
    Some(engine) => Ok(engine)
    None => {
      let engine = match Engine::new(source) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let _ = self.insert(key, engine)
      Ok(engine)
    }
  }
}

///|
pub fn TemplateCache::insert(
  self : TemplateCache,
  key : String,
  engine : Engine,
) -> Bool {
  if self.capacity == 0 || key.trim() == "" {
    return false
  }
  for index in 0..<self.entries.length() {
    if self.entries[index].key == key {
      self.entries[index] = { key, engine }
      return true
    }
  }
  if self.entries.length() >= self.capacity {
    let _ = self.entries.remove(0)
  }
  self.entries.push({ key, engine })
  true
}

///|
pub fn TemplateCache::remove(self : TemplateCache, key : String) -> Bool {
  for index in 0..<self.entries.length() {
    if self.entries[index].key == key {
      let _ = self.entries.remove(index)
      return true
    }
  }
  false
}

///|
pub fn TemplateCache::clear(self : TemplateCache) -> Unit {
  self.entries.clear()
  self.hits = 0
  self.misses = 0
}

///|
pub fn TemplateCache::keys(self : TemplateCache) -> Array[String] {
  let result = []
  for entry in self.entries {
    result.push(entry.key)
  }
  result
}

///|
pub fn TemplateCache::hit_rate(self : TemplateCache) -> String {
  let total = self.hits + self.misses
  if total == 0 {
    "0%"
  } else {
    "{self.hits * 100 / total}%"
  }
}

///|
pub fn cache_render(
  cache : TemplateCache,
  key : String,
  source : String,
  context : Context,
) -> Result[String, String] {
  let engine = match cache.compile(key, source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(engine.render(context.to_map()))
}

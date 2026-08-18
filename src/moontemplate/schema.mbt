///|
/// Lightweight context schemas make missing or malformed input visible before
/// a render is accepted by a build pipeline.
pub struct ContextSchema {
  required : Array[String]
  defaults : Context
  non_empty : Array[String]
} derive(Debug, Eq)

///|
pub fn ContextSchema::new() -> ContextSchema {
  { required: [], defaults: Context::new(), non_empty: [] }
}

///|
pub fn ContextSchema::require(
  self : ContextSchema,
  key : String,
) -> ContextSchema {
  if key.trim() != "" && !self.required.contains(key) {
    self.required.push(key.trim().to_owned())
  }
  self
}

///|
pub fn ContextSchema::default_value(
  self : ContextSchema,
  key : String,
  value : String,
) -> ContextSchema {
  let _ = self.defaults.set(key, value)
  self
}

///|
pub fn ContextSchema::require_non_empty(
  self : ContextSchema,
  key : String,
) -> ContextSchema {
  if key.trim() != "" && !self.non_empty.contains(key) {
    self.non_empty.push(key.trim().to_owned())
  }
  self
}

///|
pub fn ContextSchema::required(self : ContextSchema) -> Array[String] {
  self.required.copy()
}

///|
pub fn ContextSchema::validate(
  self : ContextSchema,
  context : Context,
) -> Array[String] {
  let errors = []
  for key in self.required {
    if !context.contains(key) && !self.defaults.contains(key) {
      errors.push("Missing key: \{key}")
    }
  }
  for key in self.non_empty {
    if context.get_or(key, self.defaults.get_or(key, "")).trim() == "" {
      errors.push("Empty key: \{key}")
    }
  }
  errors
}

///|
pub fn ContextSchema::apply_defaults(
  self : ContextSchema,
  context : Context,
) -> Context {
  let result = Context::new().merge(self.defaults).merge(context)
  result
}

///|
pub fn ContextSchema::accepts(self : ContextSchema, context : Context) -> Bool {
  self.validate(context).length() == 0
}

///|
pub fn schema_for_engine(engine : Engine) -> ContextSchema {
  let schema = ContextSchema::new()
  for key in engine.required_variables() {
    let _ = schema.require(key)
  }
  schema
}

///|
pub fn schema_report(schema : ContextSchema, context : Context) -> String {
  let errors = schema.validate(context)
  if errors.length() == 0 {
    "valid"
  } else {
    errors.join("; ")
  }
}

///|
/// A render plan is a serializable description of work selected for a batch.
pub struct RenderPlan {
  names : Array[String]
  mut limits : RenderLimits
  mut pipeline : RenderPipeline
}

///|
pub fn RenderPlan::new() -> RenderPlan {
  {
    names: [],
    limits: RenderLimits::default(),
    pipeline: RenderPipeline::new(),
  }
}

///|
pub fn RenderPlan::add_name(self : RenderPlan, name : String) -> RenderPlan {
  if name.trim() != "" {
    self.names.push(name.trim().to_owned())
  }
  self
}

///|
pub fn RenderPlan::with_limits(
  self : RenderPlan,
  limits : RenderLimits,
) -> RenderPlan {
  self.limits = limits
  self
}

///|
pub fn RenderPlan::with_pipeline(
  self : RenderPlan,
  pipeline : RenderPipeline,
) -> RenderPlan {
  self.pipeline = pipeline
  self
}

///|
pub fn RenderPlan::names(self : RenderPlan) -> Array[String] {
  self.names.copy()
}

///|
pub fn RenderPlan::limits(self : RenderPlan) -> RenderLimits {
  self.limits
}

///|
pub fn RenderPlan::describe(self : RenderPlan) -> String {
  let context = Context::new()
    .set_int("templates", self.names.length())
    .set_int("max_output", self.limits.max_output_chars())
    .set_int("max_iterations", self.limits.max_iterations())
    .set_int("max_depth", self.limits.max_depth())
    .set("pipeline", self.pipeline.names().join(","))
  json_object(context)
}

///|
pub fn RenderPlan::render(
  self : RenderPlan,
  bundle : TemplateBundle,
  context : Context,
) -> Array[BatchResult] {
  let items = []
  for name in self.names {
    match bundle.get(name) {
      Some(_) => items.push(BatchItem::new(name, "", context))
      None =>
        items.push(BatchItem::new(name, "{% invalid plan entry %}", context))
    }
  }
  let results = []
  for item in items {
    match bundle.get(item.name()) {
      Some(engine) =>
        match engine.render_with_limits(item.context.to_map(), self.limits) {
          Ok(report) =>
            results.push({
              name: item.name(),
              output: self.pipeline.apply(report.output()),
              error: None,
            })
          Err(failure) =>
            results.push({
              name: item.name(),
              output: "",
              error: Some(render_failure_message(failure)),
            })
        }
      None =>
        results.push({
          name: item.name(),
          output: "",
          error: Some("Unknown template"),
        })
    }
  }
  results
}

///|
fn render_failure_message(failure : RenderFailure) -> String {
  match failure {
    OutputLimitExceeded(limit, current) =>
      "output limit \{limit} exceeded at \{current}"
    IterationLimitExceeded(limit) => "iteration limit \{limit} exceeded"
    DepthLimitExceeded(limit) => "depth limit \{limit} exceeded"
  }
}

///|
pub fn plan_from_names(names : Array[String]) -> RenderPlan {
  let plan = RenderPlan::new()
  for name in names {
    let _ = plan.add_name(name)
  }
  plan
}

///|
pub fn plan_validate(
  plan : RenderPlan,
  bundle : TemplateBundle,
) -> Array[String] {
  let missing = []
  for name in plan.names() {
    if !bundle.contains(name) {
      missing.push(name)
    }
  }
  missing
}

///|
pub fn plan_required_variables(
  plan : RenderPlan,
  bundle : TemplateBundle,
) -> Array[String] {
  let result = []
  for name in plan.names() {
    match bundle.get(name) {
      Some(engine) =>
        for key in engine.required_variables() {
          if !result.contains(key) {
            result.push(key)
          }
        }
      None => ()
    }
  }
  result.sort()
  result
}

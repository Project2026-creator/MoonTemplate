///|
/// Resource limits for untrusted or user-authored templates.
pub struct RenderLimits {
  max_output_chars : Int32
  max_iterations : Int32
  max_depth : Int32
} derive(Debug, Eq)

///|
pub extend RenderLimits with Debug::{to_repr}

///|
pub extend RenderLimits with Eq::{not_equal, equal}

///|
pub fn RenderLimits::new(
  max_output_chars : Int32,
  max_iterations : Int32,
  max_depth : Int32,
) -> RenderLimits {
  {
    max_output_chars: non_negative(max_output_chars),
    max_iterations: non_negative(max_iterations),
    max_depth: non_negative(max_depth),
  }
}

///|
pub fn RenderLimits::default() -> RenderLimits {
  RenderLimits::new(1_000_000, 100_000, 64)
}

///|
pub fn RenderLimits::max_output_chars(self : RenderLimits) -> Int32 {
  self.max_output_chars
}

///|
pub fn RenderLimits::max_iterations(self : RenderLimits) -> Int32 {
  self.max_iterations
}

///|
pub fn RenderLimits::max_depth(self : RenderLimits) -> Int32 {
  self.max_depth
}

///|
fn non_negative(value : Int32) -> Int32 {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
/// Runtime counters returned with a bounded render.
pub struct RenderMetrics {
  mut output_chars : Int32
  mut nodes_visited : Int32
  mut iterations : Int32
  mut max_depth : Int32
  mut variables_resolved : Int32
  mut missing_variables : Int32
} derive(Debug, Eq)

///|
pub extend RenderMetrics with Debug::{to_repr}

///|
pub extend RenderMetrics with Eq::{not_equal, equal}

///|
pub fn RenderMetrics::output_chars(self : RenderMetrics) -> Int32 {
  self.output_chars
}

///|
pub fn RenderMetrics::nodes_visited(self : RenderMetrics) -> Int32 {
  self.nodes_visited
}

///|
pub fn RenderMetrics::iterations(self : RenderMetrics) -> Int32 {
  self.iterations
}

///|
pub fn RenderMetrics::max_depth(self : RenderMetrics) -> Int32 {
  self.max_depth
}

///|
pub fn RenderMetrics::variables_resolved(self : RenderMetrics) -> Int32 {
  self.variables_resolved
}

///|
pub fn RenderMetrics::missing_variables(self : RenderMetrics) -> Int32 {
  self.missing_variables
}

///|
/// Successful bounded-render result.
pub struct RenderReport {
  output : String
  metrics : RenderMetrics
} derive(Debug, Eq)

///|
pub extend RenderReport with Debug::{to_repr}

///|
pub extend RenderReport with Eq::{not_equal, equal}

///|
pub fn RenderReport::output(self : RenderReport) -> String {
  self.output
}

///|
pub fn RenderReport::metrics(self : RenderReport) -> RenderMetrics {
  self.metrics
}

///|
/// Failure raised when a render would exceed a caller-supplied limit.
pub(all) enum RenderFailure {
  OutputLimitExceeded(Int32, Int32) // configured limit, current output
  IterationLimitExceeded(Int32) // configured limit
  DepthLimitExceeded(Int32) // configured limit
} derive(Debug, Eq)

///|
pub extend RenderFailure with Debug::{to_repr}

///|
pub extend RenderFailure with Eq::{not_equal, equal}

///|
/// Render while enforcing output, loop, and nesting budgets.
pub fn Engine::render_with_limits(
  self : Engine,
  context : Map[String, String],
  limits : RenderLimits,
) -> Result[RenderReport, RenderFailure] {
  let metrics : RenderMetrics = {
    output_chars: 0,
    nodes_visited: 0,
    iterations: 0,
    max_depth: 0,
    variables_resolved: 0,
    missing_variables: 0,
  }
  match self.render_bounded_nodes(self.nodes, context, limits, metrics, 0) {
    Ok(output) => Ok({ output, metrics, })
    Err(failure) => Err(failure)
  }
}

///|
fn Engine::render_bounded_nodes(
  self : Engine,
  nodes : Array[Node],
  context : Map[String, String],
  limits : RenderLimits,
  metrics : RenderMetrics,
  depth : Int32,
) -> Result[String, RenderFailure] {
  if depth > limits.max_depth() {
    return Err(DepthLimitExceeded(limits.max_depth()))
  }
  if depth > metrics.max_depth {
    metrics.max_depth = depth
  }
  let mut result = ""
  for node in nodes {
    metrics.nodes_visited += 1
    match node {
      Text(value) =>
        match record_output(value, limits, metrics) {
          Ok(_) => result += value
          Err(failure) => return Err(failure)
        }
      Variable(name, filters) => {
        let base = match context.get(name) {
          Some(value) => {
            metrics.variables_resolved += 1
            value
          }
          None => {
            metrics.missing_variables += 1
            ""
          }
        }
        let rendered = self.apply_filters(base, filters)
        match record_output(rendered, limits, metrics) {
          Ok(_) => result += rendered
          Err(failure) => return Err(failure)
        }
      }
      If(condition, true_branch, false_branch) => {
        let is_true = match context.get(condition) {
          Some(value) => {
            metrics.variables_resolved += 1
            value.trim() != "" && value != "false" && value != "0"
          }
          None => {
            metrics.missing_variables += 1
            false
          }
        }
        let branch = if is_true { true_branch } else { false_branch }
        match
          self.render_bounded_nodes(branch, context, limits, metrics, depth + 1) {
          Ok(rendered) => result += rendered
          Err(failure) => return Err(failure)
        }
      }
      For(variable, iterable, body) =>
        match context.get(iterable) {
          Some(raw) if raw.trim() != "" => {
            metrics.variables_resolved += 1
            for item in parse_iterable(raw) {
              if metrics.iterations >= limits.max_iterations() {
                return Err(IterationLimitExceeded(limits.max_iterations()))
              }
              metrics.iterations += 1
              let new_context = extend_context(context, variable, item)
              match
                self.render_bounded_nodes(
                  body,
                  new_context,
                  limits,
                  metrics,
                  depth + 1,
                ) {
                Ok(rendered) => result += rendered
                Err(failure) => return Err(failure)
              }
            }
          }
          Some(_) => metrics.variables_resolved += 1
          None => metrics.missing_variables += 1
        }
    }
  }
  Ok(result)
}

///|
fn record_output(
  value : String,
  limits : RenderLimits,
  metrics : RenderMetrics,
) -> Result[Unit, RenderFailure] {
  let next = metrics.output_chars + value.char_length()
  if next > limits.max_output_chars() {
    Err(OutputLimitExceeded(limits.max_output_chars(), metrics.output_chars))
  } else {
    metrics.output_chars = next
    Ok(())
  }
}

///|
fn extend_context(
  context : Map[String, String],
  variable : String,
  item : String,
) -> Map[String, String] {
  let new_context : Map[String, String] = Map([], capacity=context.length() + 1)
  for key, value in context {
    new_context.set(key, value)
  }
  new_context.set(variable, item)
  new_context
}

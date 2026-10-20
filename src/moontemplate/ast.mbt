///|
pub(all) enum Node {
  Text(String)
  Variable(String, Array[String])
  If(String, Array[Node], Array[Node]) // condition, true_branch, false_branch
  For(String, String, Array[Node]) // var_name, iterable, body
} derive(Debug, Eq)

///|
pub extend Node with Debug::{to_repr}

///|
pub extend Node with Eq::{not_equal, equal}

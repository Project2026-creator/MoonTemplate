
pub(all) enum Node {
  Text(String)
  Variable(String)
  If(String, Array[Node], Array[Node]) // condition, true_branch, false_branch
  For(String, String, Array[Node]) // var_name, iterable, body
} derive(Show, Eq)

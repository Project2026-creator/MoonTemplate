
test "parser text and variable" {
  let tokens = [Token::Text("hello "), Token::VarStart, Token::Identifier("name"), Token::VarEnd]
  let parser = Parser::new(tokens)
  let nodes = parser.parse().unwrap()
  assert_eq(nodes.length(), 2)
  assert_eq(nodes[0], Node::Text("hello "))
  assert_eq(nodes[1], Node::Variable("name"))
}

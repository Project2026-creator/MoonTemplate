///|
test "parser text and variable" {
  let tokens = [
    Token::Text("hello "),
    Token::VarStart,
    Token::Identifier("name"),
    Token::VarEnd,
  ]
  let parser = Parser::new(tokens)
  let nodes = parser.parse().unwrap()
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] == Node::Text("hello "))
  assert_true(nodes[1] == Node::Variable("name", []))
}

///|
test "parser variable filters and else branch" {
  let tokens = Lexer::new(
    "{{ name | trim | uppercase }}{% if show %}yes{% else %}no{% endif %}",
  ).tokenize()
  let parser = Parser::new(tokens)
  let nodes = parser.parse().unwrap()
  assert_true(
    nodes ==
    [
      Node::Variable("name", ["trim", "uppercase"]),
      Node::If("show", [Node::Text("yes")], [Node::Text("no")]),
    ],
  )
}

///|
test "parser reports missing endif" {
  let tokens = Lexer::new("{% if show %}yes").tokenize()
  let parser = Parser::new(tokens)
  match parser.parse() {
    Err(message) => assert_eq(message, "Expected {% endif %}")
    Ok(_) => fail("Expected parser error for missing endif")
  }
}

///|
test "parser reports missing endfor" {
  let tokens = Lexer::new("{% for item in list %}{{ item }}").tokenize()
  let parser = Parser::new(tokens)
  match parser.parse() {
    Err(message) => assert_eq(message, "Expected {% endfor %}")
    Ok(_) => fail("Expected parser error for missing endfor")
  }
}

///|
test "parser rejects filter without a name" {
  let tokens = Lexer::new("{{ name | }}").tokenize()
  let parser = Parser::new(tokens)
  match parser.parse() {
    Err(message) => assert_eq(message, "Expected filter name after |")
    Ok(_) => fail("Expected parser error for missing filter name")
  }
}

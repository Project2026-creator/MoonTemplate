///|
test "string algorithms handle unicode and empty values" {
  assert_eq(@moontemplate.text_reverse("abc"), "cba")
  assert_eq(@moontemplate.text_reverse("月球"), "球月")
  assert_eq(@moontemplate.text_char_at("abc", 1), Some("b"))
  assert_eq(@moontemplate.text_char_at("abc", 3), None)
  assert_eq(@moontemplate.text_take("abcdef", 3), "abc")
  assert_eq(@moontemplate.text_drop("abcdef", 3), "def")
  assert_eq(@moontemplate.text_slice("abcdef", 2, 2), "cd")
  assert_eq(@moontemplate.text_slice("abc", -1, 2), "")
}

///|
test "word and case algorithms" {
  assert_eq(@moontemplate.text_words(" one\ttwo  three "), [
    "one", "two", "three",
  ])
  assert_eq(@moontemplate.text_join_non_empty(["a", "", "b"], ","), "a,b")
  assert_eq(@moontemplate.text_kebab("Hello Moon Bit"), "hello-moon-bit")
  assert_eq(@moontemplate.text_snake("Hello Moon Bit"), "hello_moon_bit")
  assert_eq(@moontemplate.text_title("hello moon"), "Hello Moon")
  assert_true(@moontemplate.text_is_integer("-12"))
  assert_false(@moontemplate.text_is_integer("12x"))
  assert_true(@moontemplate.text_is_identifier("moon-bit_2"))
  assert_false(@moontemplate.text_is_identifier("2moon"))
}

///|
test "algorithm checksum and numbered lines" {
  assert_true(
    @moontemplate.text_checksum("abc") != @moontemplate.text_checksum("abd"),
  )
  assert_eq(@moontemplate.text_lines_with_numbers("a\nb"), ["1: a", "2: b"])
}

///|
test "format adapters" {
  let context = @moontemplate.Context::from_pairs([("z", "3"), ("a", "1")])
  assert_eq(@moontemplate.format_key_value(context, "=", "\n"), "a=1\nz=3\n")
  assert_eq(@moontemplate.format_ini("main", context), "[main]\na=1\nz=3\n")
  assert_true(@moontemplate.format_env(context).contains("A=\"1\""))
  assert_true(@moontemplate.format_shell_assignments(context).contains("a='1'"))
}

///|
test "csv and list formats quote boundaries" {
  assert_eq(@moontemplate.csv_quote("a,b"), "\"a,b\"")
  assert_eq(@moontemplate.csv_quote("a\"b"), "\"a\"\"b\"")
  assert_eq(@moontemplate.format_csv_row(["a", "b,c"]), "a,\"b,c\"")
  assert_eq(@moontemplate.format_csv(["a"], [["1"], ["2"]]), "a\n1\n2")
  assert_eq(
    @moontemplate.format_plain_list(["a", "b"], "- ", "\n"),
    "- a\n- b\n",
  )
}

///|
test "format tree and table utilities" {
  assert_eq(
    @moontemplate.format_tree([(0, "root"), (1, "child")]),
    "- root\n  - child\n",
  )
  assert_eq(@moontemplate.format_badge("build", "pass"), "[build: pass]")
  assert_eq(
    @moontemplate.format_table_rows([["a", "b"], ["c", "d"]], " | "),
    "a | b\nc | d",
  )
}

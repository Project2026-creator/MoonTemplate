///|
test "benchmark catalog contains practical rendering scenarios" {
  let cases = benchmark_cases()
  assert_true(cases.length() >= 12)
  assert_true(cases[0].name() != "")
  assert_true(cases[0].category() != "")
  assert_true(cases[0].template().length() > 0)
  assert_true(cases[0].expected_output().length() > 0)
}

///|
test "benchmark suite produces reproducible passing results" {
  let results = run_benchmark_suite().unwrap()
  assert_true(results.length() >= 12)
  for result in results {
    assert_true(result.passed())
    assert_true(result.output_chars() >= 0)
    assert_true(result.nodes_visited() > 0)
  }
}

///|
test "benchmark results expose loop and Unicode evidence" {
  let results = run_benchmark_suite().unwrap()
  let mut found_loop = false
  let mut found_unicode = false
  for result in results {
    if result.iterations() > 0 {
      found_loop = true
    }
    if result.unicode_chars() > 0 {
      found_unicode = true
    }
  }
  assert_true(found_loop)
  assert_true(found_unicode)
}

///|
test "benchmark limits cover empty and dense input boundaries" {
  let cases = benchmark_cases()
  let mut has_empty = false
  let mut has_dense = false
  for item in cases {
    if item.name() == "empty-values" {
      has_empty = true
    }
    if item.name() == "dense-catalog" {
      has_dense = true
    }
  }
  assert_true(has_empty)
  assert_true(has_dense)
}

///|
test "individual benchmark execution retains expected output" {
  let item = benchmark_cases()[0]
  let result = run_benchmark_case(item).unwrap()
  assert_true(result.passed())
  assert_eq(result.name(), item.name())
  assert_eq(result.expected_chars(), item.expected_output().char_length())
}

///|
test "benchmark report exports machine-readable acceptance evidence" {
  let results = run_benchmark_suite().unwrap()
  assert_true(benchmark_all_passed(results))
  assert_true(benchmark_total_output_chars(results) > 0)
  assert_true(benchmark_total_iterations(results) > 0)
  let json = benchmark_report_json(results)
  assert_true(json.has_prefix("["))
  assert_true(json.contains("\"name\":\"greeting\""))
  assert_true(json.contains("\"passed\":true"))
}

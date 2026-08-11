# Template Syntax

## Variables

Use `{{ variable_name }}` for direct interpolation.

```text
Hello, {{ user }}
```

## Filter pipelines

Chain filters from left to right with `|`.

```text
{{ user | trim | uppercase }}
```

Built-in filters:

- `trim`
- `uppercase`
- `lowercase`
- `escape_html` — escapes `&`, `<`, `>`, double quotes, and apostrophes.
- `escape_json` — serializes the value as a quoted JSON string.
- `slugify` — lowercases ASCII letters, keeps ASCII digits, and joins runs of separators with `-`.

Filter names are applied from left to right, so escaping can be composed with
normalization when appropriate: `{{ title | trim | slugify }}`.

## Conditionals

Use `if` / `else` / `endif` blocks.

```text
{% if is_admin %}
Admin
{% else %}
User
{% endif %}
```

## Loops

Use `for` / `endfor` blocks to iterate comma-separated context values.

```text
{% for item in users %}
- {{ item | trim }}
{% endfor %}
```

If `users = "alice, bob, carol"`, the loop renders three iterations.

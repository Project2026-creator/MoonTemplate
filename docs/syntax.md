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

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

Parameterized filters include `replace("old", "new")`, `truncate(20)`, and
`default("fallback")`. Truncation counts Unicode characters. Arguments are
only quoted strings or signed integers; strings accept `\\` and `\"` escapes.

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

## Comments and whitespace control

`{# comment #}` is a non-nesting comment and renders nothing. A leading `-`
trims ASCII whitespace on the preceding text, while a trailing `-` trims it
from the following text:

```text
A  {{- name -}}  B
{%- if enabled -%}yes{%- endif -%}
```

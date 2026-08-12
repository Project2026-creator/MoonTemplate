# Template Syntax

## Variables and filters

Use `{{ variable_name }}` for interpolation and chain filters left to right:

```text
{{ user | trim | uppercase }}
{{ title | replace("Moon", "Star") | truncate(20) }}
```

Built-in filters are `trim`, `uppercase`, `lowercase`, `escape_html`,
`escape_json`, `slugify`, `length`, `collapse_whitespace`, `capitalize`, and
`newline_to_br`. Parameterized filters include `replace`, `truncate`,
`default`, `prefix`, `suffix`, `pad_left`, `pad_right`, and Unicode `slice`.
Arguments are only double-quoted strings or signed decimal integers; strings
support the necessary `\\`, `\"`, `\n`, `\r`, and `\t` escapes.

## Conditionals

```text
{% if is_admin %}
Admin
{% else %}
User
{% endif %}
```

Conditions treat an empty value, `0`, and `false` as false.

## Loops

```text
{% for item in users %}
- {{ item | trim }}
{% endfor %}
```

Loop inputs are comma-separated strings. Empty items are ignored after trimming.
Loop variables are local to the loop body and are not required context keys.

## Comments and whitespace control

`{# comment #}` is a non-nesting comment and renders nothing. A leading `-`
trims ASCII whitespace on the preceding text, while a trailing `-` trims ASCII
whitespace from the following text:

```text
A  {{- name -}}  B
{%- if enabled -%}yes{%- endif -%}
```

Whitespace control never removes non-ASCII whitespace.

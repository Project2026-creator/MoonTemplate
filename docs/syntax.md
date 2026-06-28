# Template Syntax

## Variables
Use `{{ }}` to interpolate variables: `{{ user_name }}`

## Filters
Use pipes to filter variables: `{{ name | uppercase }}`

## If Statements
```moonbit
{% if is_admin %}
Welcome, Administrator!
{% endif %}
```

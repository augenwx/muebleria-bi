/*
    Macro: generate_schema_name
    ---------------------------
    Por defecto dbt genera schemas como "<target_schema>_<custom_schema>"
    (ej: staging_marts).  Este macro lo cambia para usar el custom_schema
    directamente cuando se especifica, de modo que:
      +schema: staging  →  schema "staging"
      +schema: marts    →  schema "marts"
*/

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
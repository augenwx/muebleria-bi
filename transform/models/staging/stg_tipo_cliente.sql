WITH source AS (
    SELECT * FROM {{ source('raw', 'tipo_cliente') }}
)

SELECT
    id      AS tipo_cliente_id,
    nombre  AS tipocliente
FROM source

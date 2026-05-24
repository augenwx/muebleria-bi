WITH source AS (
    SELECT * FROM {{ source('raw', 'tipo_venta') }}
)

SELECT
    id      AS tipo_venta_id,
    nombre  AS tipoventa
FROM source

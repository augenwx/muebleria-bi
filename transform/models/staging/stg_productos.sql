WITH source AS (
    SELECT * FROM {{ source('raw', 'producto') }}
)

SELECT
    id                  AS producto_id,
    nombre,
    costo_estandar,
    precio_venta_retail,
    precio_venta_mayorista
FROM source

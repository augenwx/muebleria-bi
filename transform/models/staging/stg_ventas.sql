WITH source AS (
    SELECT * FROM {{ source('raw', 'venta') }}
)

SELECT
    id              AS venta_id,
    fecha,
    cliente_id,
    tipo_cliente_id,
    producto_id,
    cantidad,
    precio_unitario,
    total_venta,
    tipo_venta_id,
    usuario_id,
    created_at
FROM source

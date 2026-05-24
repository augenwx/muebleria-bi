WITH source AS (
    SELECT * FROM {{ source('raw', 'cliente') }}
)

SELECT
    id              AS cliente_id,
    tipo_cliente_id,
    documento,
    nombre,
    razon_social,
    direccion,
    telefono,
    email,
    limite_credito,
    saldo_pendiente,
    estado,
    created_at
FROM source

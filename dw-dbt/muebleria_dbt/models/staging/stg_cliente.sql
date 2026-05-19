-- stg_cliente.sql
-- Maestro de clientes

with source as (
    select * from {{ source('raw', 'cliente') }}
)

select
    id                              as cliente_id,
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
    activo,
    created_at

from source

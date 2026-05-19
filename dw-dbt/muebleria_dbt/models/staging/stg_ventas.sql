-- stg_ventas.sql
-- Cabecera de ventas: 1 fila por venta

with source as (
    select * from {{ source('raw', 'venta') }}
)

select
    id                              as venta_id,
    fecha                           as fecha_venta,
    cliente_id,
    tipo_venta_id,
    total_venta,
    usuario_id,
    observaciones,
    created_at

from source

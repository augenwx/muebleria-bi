-- stg_detalle_venta.sql
-- Líneas de venta: 1 fila por producto vendido

with source as (
    select * from {{ source('raw', 'detalle_venta') }}
)

select
    id                              as detalle_venta_id,
    venta_id,
    producto_id,
    cantidad,
    precio_unitario,
    -- subtotal llega calculado desde OLTP (GENERATED ALWAYS AS)
    coalesce(subtotal, cantidad * precio_unitario)  as subtotal,
    created_at

from source

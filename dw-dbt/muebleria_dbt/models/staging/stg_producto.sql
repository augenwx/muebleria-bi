-- stg_producto.sql
-- Maestro de productos terminados

with source as (
    select * from {{ source('raw', 'producto') }}
)

select
    id                              as producto_id,
    nombre,
    costo_estandar,
    precio_venta_retail,
    precio_venta_mayorista,
    activo,
    created_at

from source

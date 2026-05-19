-- stg_compra_material.sql
-- Compras de materiales a proveedores

with source as (
    select * from {{ source('raw', 'compra_material') }}
)

select
    id                              as compra_id,
    fecha,
    proveedor_id,
    material_id,
    cantidad,
    precio_unitario,
    -- total_compra llega calculado desde OLTP (GENERATED)
    coalesce(total_compra, cantidad * precio_unitario) as total_compra,
    factura_numero,
    notas,
    usuario_id,
    created_at

from source

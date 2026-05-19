-- stg_material.sql
-- Maestro de materias primas

with source as (
    select * from {{ source('raw', 'material') }}
)

select
    id                              as material_id,
    nombre,
    unidad_medida_id,
    stock_minimo,
    stock_actual,
    proveedor_preferido_id,
    activo,
    created_at

from source

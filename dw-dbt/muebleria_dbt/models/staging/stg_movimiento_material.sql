-- stg_movimiento_material.sql
-- Kardex: entradas, salidas y ajustes de materiales

with source as (
    select * from {{ source('raw', 'movimiento_material') }}
)

select
    id                              as movimiento_id,
    fecha,
    material_id,
    tipo_movimiento,
    cantidad,
    precio_unitario,
    total_valor,
    referencia_id,
    referencia_tabla,
    notas,
    created_at

from source

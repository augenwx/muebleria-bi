-- dim_material.sql
-- Dimensión de materias primas con unidad de medida

with materiales as (
    select * from {{ ref('stg_material') }}
),

unidades as (
    select
        id          as unidad_medida_id,
        nombre      as unidad_nombre,
        abreviatura as unidad_abreviatura
    from {{ source('raw', 'unidad_medida') }}
)

select
    m.material_id,
    m.nombre,
    u.unidad_nombre,
    u.unidad_abreviatura,
    m.stock_minimo,
    m.activo

from materiales m
left join unidades u on u.unidad_medida_id = m.unidad_medida_id

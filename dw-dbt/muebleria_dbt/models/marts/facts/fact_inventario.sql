-- fact_inventario.sql
-- Hecho de inventario (Kardex): 1 fila por movimiento de material
-- CORRECCIÓN: Base = movimiento_material (kardex unificado)
--   - DIM_PROVEEDOR se llena solo cuando tipo = 'entrada' y referencia = 'compra_material'
--   - NULLs en proveedor son esperados para salidas y ajustes
-- Conecta con: DIM_TIEMPO, DIM_MATERIAL, DIM_PROVEEDOR (nullable)

with movimientos as (
    select * from {{ ref('stg_movimiento_material') }}
),

compras as (
    select * from {{ ref('stg_compra_material') }}
),

tiempo as (
    select * from {{ ref('dim_tiempo') }}
)

select
    -- PK
    mv.movimiento_id,

    -- FKs dimensionales
    t.fecha_key                                     as tiempo_key,
    mv.material_id,
    -- proveedor solo cuando es entrada por compra (NULLs son correctos)
    cm.proveedor_id,

    -- Tipo de movimiento
    mv.tipo_movimiento,

    -- Métricas
    mv.cantidad,
    mv.precio_unitario,
    mv.total_valor,

    -- Referencia cruzada
    mv.referencia_id,
    mv.referencia_tabla,
    mv.notas

from movimientos mv
left join compras cm
    on  mv.referencia_tabla = 'compra_material'
    and mv.referencia_id    = cm.compra_id
inner join tiempo t on t.fecha = mv.fecha

-- stg_produccion.sql
-- Lotes de producción con costos totales (MP + MO)
-- NOTA: NO se hace JOIN con consumo_material → evita fan-out

with source as (
    select * from {{ source('raw', 'produccion') }}
)

select
    id                              as produccion_id,
    orden_produccion_id,
    fecha_produccion,
    producto_id,
    cantidad_producida,
    costo_materia_prima,
    mano_de_obra,
    -- costo_total llega calculado desde OLTP (GENERATED)
    coalesce(costo_total, costo_materia_prima + mano_de_obra) as costo_total,
    -- costo_unitario llega calculado desde OLTP (GENERATED)
    coalesce(
        costo_unitario,
        case
            when cantidad_producida > 0
            then (costo_materia_prima + mano_de_obra) / cantidad_producida
            else 0
        end
    )                               as costo_unitario,
    destino_id,
    notas,
    created_at

from source

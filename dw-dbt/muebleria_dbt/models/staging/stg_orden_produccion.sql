-- stg_orden_produccion.sql
-- Órdenes de producción (planificación)

with source as (
    select * from {{ source('raw', 'orden_produccion') }}
)

select
    id                              as orden_produccion_id,
    numero_orden,
    fecha_inicio,
    fecha_fin_estimada,
    fecha_fin_real,
    producto_id,
    cantidad_ordenada,
    cantidad_producida,
    estado,
    responsable_id                  as usuario_id,
    costo_mp_estimado,
    costo_mo_estimado,
    notas,
    created_at

from source

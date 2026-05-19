-- fact_produccion.sql
-- Hecho de producción: 1 fila por lote de producción
-- CORRECCIÓN: Solo usa tabla produccion (NO consumo_material → evita fan-out)
-- Conecta con: DIM_TIEMPO, DIM_PRODUCTO, DIM_DESTINO_PROD, DIM_USUARIO (via orden)

with produccion as (
    select * from {{ ref('stg_produccion') }}
),

ordenes as (
    select * from {{ ref('stg_orden_produccion') }}
),

tiempo as (
    select * from {{ ref('dim_tiempo') }}
)

select
    -- PK
    pr.produccion_id,

    -- FKs dimensionales
    t.fecha_key                                     as tiempo_key,
    pr.producto_id,
    pr.destino_id,
    o.usuario_id,                                   -- responsable de la orden

    -- Referencia OLTP
    pr.orden_produccion_id                          as orden_id_oltp,
    o.numero_orden,

    -- Métricas de producción
    pr.cantidad_producida,
    pr.costo_materia_prima,
    pr.mano_de_obra,
    pr.costo_total,
    pr.costo_unitario

from produccion pr
left join ordenes o on o.orden_produccion_id = pr.orden_produccion_id
inner join tiempo t on t.fecha              = pr.fecha_produccion

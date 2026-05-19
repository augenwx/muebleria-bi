-- fact_gastos.sql
-- Hecho de gastos operativos: 1 fila por gasto registrado
-- Aquí van: alquiler, luz, mano de obra eventual, publicidad, etc.
-- Conecta con: DIM_TIEMPO, DIM_CATEGORIA_GASTO, DIM_USUARIO

with gastos as (
    select * from {{ ref('stg_gasto') }}
),

tiempo as (
    select * from {{ ref('dim_tiempo') }}
)

select
    -- PK
    g.gasto_id,

    -- FKs dimensionales
    t.fecha_key                                     as tiempo_key,
    g.categoria_id,
    g.usuario_id,

    -- Período (útil para agrupaciones rápidas)
    g.anio,
    g.mes,

    -- Métricas
    g.monto,

    -- Detalle
    g.detalle,
    g.comprobante

from gastos g
inner join tiempo t on t.fecha = g.fecha

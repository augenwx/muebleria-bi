-- stg_gasto.sql
-- Gastos operativos (alquiler, luz, MO eventual, publicidad, etc.)

with source as (
    select * from {{ source('raw', 'gasto') }}
)

select
    id                              as gasto_id,
    fecha,
    categoria_id,
    -- anio y mes llegan calculados desde OLTP (GENERATED)
    coalesce(anio, extract(year  from fecha)::int) as anio,
    coalesce(mes,  extract(month from fecha)::int) as mes,
    monto,
    detalle,
    comprobante,
    usuario_id,
    created_at

from source

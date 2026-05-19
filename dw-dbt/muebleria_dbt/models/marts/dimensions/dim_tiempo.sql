-- dim_tiempo.sql
-- Dimensión de tiempo generada a partir de todas las fechas de los hechos
-- Una fila por cada fecha única que aparece en ventas, producción, inventario o gastos

with fechas_ventas as (
    select fecha_venta as fecha from {{ ref('stg_ventas') }}
),

fechas_produccion as (
    select fecha_produccion as fecha from {{ ref('stg_produccion') }}
),

fechas_inventario as (
    select fecha from {{ ref('stg_movimiento_material') }}
),

fechas_gastos as (
    select fecha from {{ ref('stg_gasto') }}
),

todas_fechas as (
    select fecha from fechas_ventas
    union
    select fecha from fechas_produccion
    union
    select fecha from fechas_inventario
    union
    select fecha from fechas_gastos
),

calendario as (
    select
        fecha,
        -- clave surrogate YYYYMMDD
        (extract(year from fecha) * 10000
         + extract(month from fecha) * 100
         + extract(day from fecha))::int          as fecha_key,
        extract(day   from fecha)::int            as dia,
        extract(month from fecha)::int            as mes,
        to_char(fecha, 'TMMonth')                 as mes_nombre,
        extract(quarter from fecha)::int          as trimestre,
        extract(year  from fecha)::int            as anio,
        extract(dow   from fecha)::int            as dia_semana_num,
        to_char(fecha, 'TMDay')                   as dia_semana_nombre,
        extract(week  from fecha)::int            as semana_anio

    from todas_fechas
    where fecha is not null
)

select
    fecha_key,
    fecha,
    dia,
    mes,
    mes_nombre,
    trimestre,
    anio,
    dia_semana_num,
    dia_semana_nombre,
    semana_anio

from calendario
order by fecha

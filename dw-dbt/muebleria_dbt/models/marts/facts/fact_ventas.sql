-- fact_ventas.sql
-- Hecho de ventas: 1 fila por línea de detalle_venta
-- Conecta con: DIM_TIEMPO, DIM_CLIENTE, DIM_PRODUCTO, DIM_TIPO_VENTA, DIM_USUARIO

with ventas as (
    select * from {{ ref('stg_ventas') }}
),

detalle as (
    select * from {{ ref('stg_detalle_venta') }}
),

productos as (
    select * from {{ ref('stg_producto') }}
),

tiempo as (
    select * from {{ ref('dim_tiempo') }}
)

select
    -- PK
    dv.detalle_venta_id,

    -- FKs dimensionales
    t.fecha_key                                     as tiempo_key,
    v.cliente_id,
    dv.producto_id,
    v.tipo_venta_id,
    v.usuario_id,

    -- Referencia OLTP
    v.venta_id                                      as venta_id_oltp,

    -- Métricas de venta
    dv.cantidad,
    dv.precio_unitario,
    dv.subtotal,

    -- Métricas de costo y margen
    p.costo_estandar,
    round(p.costo_estandar * dv.cantidad, 2)        as costo_total,
    round(dv.subtotal - (p.costo_estandar * dv.cantidad), 2)
                                                    as margen_bruto,
    case
        when dv.subtotal > 0
        then round(
            ((dv.subtotal - (p.costo_estandar * dv.cantidad)) / dv.subtotal) * 100,
            2
        )
        else 0
    end                                             as pct_margen

from detalle dv
inner join ventas    v on v.venta_id    = dv.venta_id
inner join productos p on p.producto_id = dv.producto_id
inner join tiempo    t on t.fecha       = v.fecha_venta

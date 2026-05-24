WITH ventas AS (
    SELECT * FROM {{ ref('stg_ventas') }}
),
clientes AS (
    SELECT * FROM {{ ref('dim_cliente') }}
),
productos AS (
    SELECT * FROM {{ ref('dim_producto') }}
),
fechas AS (
    SELECT * FROM {{ ref('dim_fecha') }}
),
tipo_venta AS (
    SELECT * FROM {{ ref('stg_tipo_venta') }}
)

SELECT
    f.idfecha,
    p.idproducto,
    c.idcliente,
    v.cantidad,
    v.precio_unitario                       AS preciounitvta,
    v.total_venta                           AS importetotal,
    tv.tipoventa                            AS tipoventa,
    ROUND(COALESCE(p.costomaterial, 0) * v.cantidad, 2)  AS costomattotal,
    ROUND(COALESCE(p.costomanoobra, 0) * v.cantidad, 2)  AS costomototal,
    NULL::NUMERIC(10,2)                     AS costoalmacen,
    ROUND(v.total_venta
        - COALESCE(p.costomaterial, 0) * v.cantidad
        - COALESCE(p.costomanoobra, 0) * v.cantidad, 2)  AS margencontrib,
    CASE WHEN v.total_venta > 0
        THEN ROUND((v.total_venta
            - COALESCE(p.costomaterial, 0) * v.cantidad
            - COALESCE(p.costomanoobra, 0) * v.cantidad
        ) / v.total_venta * 100, 2)
        ELSE 0
    END                                     AS pctmargen,
    NULL::INT                               AS diasentienda,
    NULL::BOOLEAN                           AS es_ocioso,
    NULL::NUMERIC(10,2)                     AS costocioso,
    f.es_pico                               AS es_temporada
FROM ventas v
JOIN fechas f     ON f.idfecha    = CAST(TO_CHAR(v.fecha, 'YYYYMMDD') AS INT)
JOIN productos p  ON p.idproducto = v.producto_id
JOIN clientes c   ON c.idcliente  = v.cliente_id
LEFT JOIN tipo_venta tv ON tv.tipo_venta_id = v.tipo_venta_id

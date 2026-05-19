-- ============================================================
-- 2_G_pasos.sql  — v3.0
-- CONSTRUCCIÓN DE LA VISTA G (lógica analítica de HVENTAS)
-- Compatible con OLTP transaccional v3.0
--
-- CAMBIOS respecto a versión anterior:
--   - venta ya no tiene producto_id/cantidad/precio_unitario
--     → ahora se lee desde detalle_venta (multi-producto)
--   - tipo_cliente ya no viene de venta sino de cliente → tipo_cliente
--   - DCLIENTE ahora usa documento como clave (no tipo_cliente)
--   - alquiler prorrateado sobre SUM(detalle_venta.cantidad)
-- ============================================================

SET search_path TO estrella, transaccional, public;

CREATE OR REPLACE VIEW vw_g_ventas_muebleria AS
WITH

-- Total de unidades vendidas en todas las líneas (para prorratear alquiler)
total_unidades AS (
    SELECT SUM(dv.cantidad) AS total
    FROM detalle_venta dv
),

-- Gasto fijo de alquiler del período (tabla gasto, nueva OLTP)
gastos_fijos AS (
    SELECT SUM(g.monto) AS total
    FROM gasto g
    JOIN categoria_gasto cg ON cg.id = g.categoria_id
    WHERE cg.nombre ILIKE '%Alquiler%'
),

-- Costo de almacén prorrateado por unidad
costo_almacen_unit AS (
    SELECT ROUND(gf.total::NUMERIC / NULLIF(tu.total, 0), 4) AS costo_unit
    FROM gastos_fijos gf, total_unidades tu
)

SELECT
    -- Claves de dimensión
    CAST(TO_CHAR(v.fecha, 'YYYYMMDD') AS INT)           AS IDFECHA,
    dp.IDPRODUCTO                                        AS IDPRODUCTO,
    dc.IDCLIENTE                                         AS IDCLIENTE,
    v.id                                                 AS IDVENTA_OLTP,

    -- Métricas de la línea de venta (detalle_venta)
    dv.cantidad                                          AS CANTIDAD,
    dv.precio_unitario                                   AS PRECIOUNITVTA,
    dv.subtotal                                          AS IMPORTETOTAL,
    tv.nombre                                            AS TIPOVENTA,

    -- Costos usando costo_estandar del producto (ya incluye MP + MO)
    p.costo_estandar                                     AS COSTOESTANDAR,
    ROUND(p.costo_estandar * dv.cantidad, 2)             AS COSTOMATTOTAL,
    ROUND(ca.costo_unit    * dv.cantidad, 2)             AS COSTOALMACEN,

    -- Margen de contribución = subtotal - costo_estandar * cantidad
    ROUND(dv.subtotal - (p.costo_estandar * dv.cantidad), 2) AS MARGENCONTRIB,

    CASE WHEN dv.subtotal > 0
         THEN ROUND(
             (dv.subtotal - (p.costo_estandar * dv.cantidad))
             / dv.subtotal * 100, 2)
         ELSE 0
    END                                                  AS PCTMARGEN,

    -- Devoluciones: marca si esta línea tuvo devolución
    EXISTS (
        SELECT 1 FROM devolucion_venta dv2
        WHERE dv2.detalle_venta_id = dv.id
    )                                                    AS ES_DEVUELTO,

    COALESCE((
        SELECT SUM(dv2.monto_reembolsado)
        FROM devolucion_venta dv2
        WHERE dv2.detalle_venta_id = dv.id
    ), 0)                                                AS MONTO_DEV,

    dt.ES_PICO                                           AS ES_TEMPORADA

FROM detalle_venta     dv
-- cabecera de venta
JOIN venta             v   ON v.id   = dv.venta_id
-- cliente real → tipo de cliente
JOIN cliente           c   ON c.id   = v.cliente_id
JOIN tipo_cliente      tc  ON tc.id  = c.tipo_cliente_id
JOIN tipo_venta        tv  ON tv.id  = v.tipo_venta_id
-- producto
JOIN producto          p   ON p.id   = dv.producto_id
-- dimensiones del datamart
JOIN DPRODUCTO         dp  ON dp.DSPRODUCTO = p.nombre
JOIN DCLIENTE          dc  ON dc.CDCLIENTE  = c.documento
JOIN DTIEMPO           dt  ON dt.IDFECHA    = CAST(TO_CHAR(v.fecha, 'YYYYMMDD') AS INT)
CROSS JOIN costo_almacen_unit ca;

-- Validación rápida: ver 5 filas
SELECT * FROM vw_g_ventas_muebleria LIMIT 5;

-- ============================================================
-- FIN 2_G_pasos.sql
-- ============================================================
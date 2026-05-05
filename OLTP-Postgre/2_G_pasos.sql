-- ============================================================
-- 2_G_pasos.sql
-- CONSTRUCCIÓN DE LA VISTA G (lógica analítica de HVENTAS)
-- ============================================================

SET search_path TO estrella, transaccional, public;

CREATE OR REPLACE VIEW vw_g_ventas_muebleria AS
WITH total_unidades AS (
    SELECT SUM(cantidad) AS total FROM venta
),
gastos_fijos AS (
    SELECT SUM(gm.monto) AS total
    FROM gasto_mes gm
    JOIN categoria_gasto cg ON cg.id = gm.categoria_id
    WHERE cg.nombre ILIKE '%Alquiler%'
),
costo_almacen_unit AS (
    SELECT ROUND(gf.total::NUMERIC / NULLIF(tu.total, 0), 4) AS costo_unit
    FROM gastos_fijos gf, total_unidades tu
)
SELECT
    CAST(TO_CHAR(v.fecha, 'YYYYMMDD') AS INT)       AS IDFECHA,
    dp.IDPRODUCTO                                    AS IDPRODUCTO,
    dc.IDCLIENTE                                     AS IDCLIENTE,
    v.cantidad                                       AS CANTIDAD,
    v.precio_unitario                                AS PRECIOUNITVTA,
    v.total_venta                                    AS IMPORTETOTAL,
    tv.nombre                                        AS TIPOVENTA,
    ROUND(dp.COSTOMATERIAL * v.cantidad, 2)          AS COSTOMATTOTAL,
    ROUND(dp.COSTOMANOOBRA * v.cantidad, 2)          AS COSTOMOTOTAL,
    ROUND(ca.costo_unit    * v.cantidad, 2)          AS COSTOALMACEN,
    ROUND(v.total_venta
          - COALESCE(dp.COSTOMATERIAL, 0) * v.cantidad
          - COALESCE(dp.COSTOMANOOBRA, 0) * v.cantidad, 2) AS MARGENCONTRIB,
    CASE WHEN v.total_venta > 0
         THEN ROUND(
             (v.total_venta
              - COALESCE(dp.COSTOMATERIAL, 0) * v.cantidad
              - COALESCE(dp.COSTOMANOOBRA, 0) * v.cantidad
             ) / v.total_venta * 100, 2)
         ELSE 0
    END                                              AS PCTMARGEN,
    NULL::INT                                        AS DIASENTIENDA,
    NULL::BOOLEAN                                    AS ES_OCIOSO,
    NULL::NUMERIC(10,2)                              AS COSTOCIOSO,
    dt.ES_PICO                                       AS ES_TEMPORADA
FROM venta v
JOIN producto      p   ON p.id  = v.producto_id
JOIN tipo_cliente  tc  ON tc.id = v.tipo_cliente_id
JOIN tipo_venta    tv  ON tv.id = v.tipo_venta_id
JOIN DPRODUCTO     dp  ON dp.DSPRODUCTO  = p.nombre
JOIN DCLIENTE      dc  ON dc.TIPOCLIENTE = tc.nombre
JOIN DTIEMPO       dt  ON dt.IDFECHA = CAST(TO_CHAR(v.fecha, 'YYYYMMDD') AS INT)
CROSS JOIN costo_almacen_unit ca;

-- Validación
SELECT * FROM vw_g_ventas_muebleria LIMIT 5;

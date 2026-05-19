-- ============================================================

-- POBLAR DIMENSIONES Y TABLAS DE HECHOS (ETL MANUAL)

-- CAMBIOS respecto a versión anterior:
--   - DTIEMPO: fechas vienen de venta, produccion, compra_material, gasto
--     (ya no de inventario ni de gasto_mes.periodo)
--   - DCLIENTE: usa tabla cliente real con documento como clave
--   - DMATERIAL: JOIN por material_id (FK real), no por texto libre
--   - DCATEGORIA_GASTO: código estable basado en nombre normalizado
--   - HGASTOS: desde tabla gasto (fecha individual, no gasto_mes)
--   - HPRODUCCION: costos son TOTALES del lote (columnas GENERATED en OLTP)
--   - HCOMPRAS_MATERIAL: desde compra_material (no desde inventario)
--   - HVENTAS: desde vw_g_ventas_muebleria (que ya usa detalle_venta)
-- ============================================================

SET search_path TO estrella, transaccional, public;

-- ============================================================
-- 1. POBLAR DIMENSIONES
-- ============================================================

-- ► DTIEMPO
--   Fuentes: venta, produccion, compra_material, gasto
INSERT INTO DTIEMPO (IDFECHA, FECHA, DIA, MES, MESNOMBRE, TRIMESTRE, ANIO, TEMPORADA, ES_PICO)
SELECT DISTINCT
    CAST(TO_CHAR(f, 'YYYYMMDD') AS INT)      AS IDFECHA,
    f                                         AS FECHA,
    EXTRACT(DAY     FROM f)::INT              AS DIA,
    EXTRACT(MONTH   FROM f)::INT              AS MES,
    TO_CHAR(f, 'TMMonth')                     AS MESNOMBRE,
    EXTRACT(QUARTER FROM f)::INT              AS TRIMESTRE,
    EXTRACT(YEAR    FROM f)::INT              AS ANIO,
    CASE EXTRACT(MONTH FROM f)
        WHEN 9  THEN 'Alta'
        WHEN 10 THEN 'Alta'
        WHEN 12 THEN 'Alta'
        ELSE 'Normal'
    END                                       AS TEMPORADA,
    EXTRACT(MONTH FROM f) IN (9, 10, 12)      AS ES_PICO
FROM (
    -- fechas de ventas
    SELECT v.fecha AS f FROM venta v
    UNION
    -- fechas de producción
    SELECT pr.fecha_produccion FROM produccion pr
    UNION
    -- fechas de compras de materiales (nueva tabla, no inventario)
    SELECT cm.fecha FROM compra_material cm
    UNION
    -- fechas de gastos individuales (nueva tabla, no gasto_mes)
    SELECT g.fecha FROM gasto g
) sub
ON CONFLICT (IDFECHA) DO NOTHING;

-- ► DPRODUCTO
--   Costos reales = promedio de lotes de produccion del período
--   costo_estandar del producto como referencia base
INSERT INTO DPRODUCTO
    (CDPRODUCTO, DSPRODUCTO, CDCATEGORIA, PRECIOVENTA,
     COSTOMATERIAL, COSTOMANOOBRA, ES_ESTRELLA)
WITH costos_reales AS (
    -- costo_materia_prima y mano_de_obra son totales del lote en la nueva OLTP
    -- → dividir entre cantidad_producida para obtener costo unitario real
    SELECT
        p.nombre                                          AS producto,
        ROUND(AVG(pr.costo_materia_prima / pr.cantidad_producida), 2) AS costo_mat_unit,
        ROUND(AVG(pr.mano_de_obra        / pr.cantidad_producida), 2) AS costo_mo_unit
    FROM produccion pr
    JOIN producto p ON p.id = pr.producto_id
    GROUP BY p.nombre
),
precios_prom AS (
    SELECT
        p.nombre                                          AS producto,
        ROUND(AVG(dv.precio_unitario), 2)                AS precio_prom
    FROM detalle_venta dv
    JOIN producto p ON p.id = dv.producto_id
    GROUP BY p.nombre
),
margen_calc AS (
    SELECT
        p.nombre,
        p.precio_venta_retail                             AS precio_ref,
        COALESCE(cr.costo_mat_unit, p.costo_estandar * 0.7)  AS costo_mat,
        COALESCE(cr.costo_mo_unit,  p.costo_estandar * 0.3)  AS costo_mo,
        COALESCE(pp.precio_prom,    p.precio_venta_retail)    AS precio_prom
    FROM producto p
    LEFT JOIN costos_reales  cr ON cr.producto = p.nombre
    LEFT JOIN precios_prom   pp ON pp.producto = p.nombre
    WHERE p.activo = TRUE
)
SELECT
    UPPER(REPLACE(m.nombre, ' ', '_'))                    AS CDPRODUCTO,
    m.nombre                                              AS DSPRODUCTO,
    'Mueble de Melamina'                                  AS CDCATEGORIA,
    m.precio_prom                                         AS PRECIOVENTA,
    m.costo_mat                                           AS COSTOMATERIAL,
    m.costo_mo                                            AS COSTOMANOOBRA,
    -- producto estrella: mayor margen bruto unitario
    CASE WHEN (m.precio_prom - m.costo_mat - m.costo_mo)
              = MAX(m.precio_prom - m.costo_mat - m.costo_mo) OVER ()
         THEN TRUE ELSE FALSE END                         AS ES_ESTRELLA
FROM margen_calc m
ON CONFLICT (CDPRODUCTO) DO NOTHING;

-- ► DCLIENTE
--   La nueva OLTP tiene tabla cliente real con documento, nombre y tipo
INSERT INTO DCLIENTE
    (CDCLIENTE, NOMBRE, TIPOCLIENTE, CANAL, LIMITE_CREDITO, FRECUENCIA)
SELECT
    c.documento                                           AS CDCLIENTE,
    c.nombre                                              AS NOMBRE,
    tc.nombre                                             AS TIPOCLIENTE,
    CASE tc.nombre
        WHEN 'Retail'    THEN 'Tienda directa'
        WHEN 'Mayorista' THEN 'Pedido especial'
        ELSE 'Otro'
    END                                                   AS CANAL,
    c.limite_credito                                      AS LIMITE_CREDITO,
    NULL::VARCHAR                                         AS FRECUENCIA    -- futuro: historial
FROM cliente c
JOIN tipo_cliente tc ON tc.id = c.tipo_cliente_id
WHERE c.activo = TRUE
ON CONFLICT (CDCLIENTE) DO NOTHING;

-- ► DMATERIAL
--   La nueva OLTP tiene tabla material con FK real a unidad_medida y proveedor
INSERT INTO DMATERIAL
    (CDMATERIAL, DSMATERIAL, TIPO, UNIDADMEDIDA, PROVEEDOR)
SELECT
    'MAT_' || UPPER(REGEXP_REPLACE(m.nombre, '[^A-Za-z0-9]', '', 'g')) AS CDMATERIAL,
    m.nombre                                                             AS DSMATERIAL,
    CASE
        WHEN m.nombre ILIKE '%Melamina%' OR m.nombre ILIKE '%Mapresa%'   THEN 'Melamina'
        WHEN m.nombre ILIKE '%Tapacanto%' OR m.nombre ILIKE '%Tornillo%'
          OR m.nombre ILIKE '%Jalador%'   OR m.nombre ILIKE '%Corredera%'
          OR m.nombre ILIKE '%Bisagra%'   OR m.nombre ILIKE '%Patita%'   THEN 'Accesorio'
        WHEN m.nombre ILIKE '%Laca%'      OR m.nombre ILIKE '%Pegamento%' THEN 'Acabado'
        ELSE 'Otro'
    END                                                                  AS TIPO,
    um.abreviatura                                                       AS UNIDADMEDIDA,
    p.nombre                                                             AS PROVEEDOR
FROM material m
JOIN unidad_medida um ON um.id = m.unidad_medida_id
LEFT JOIN proveedor p ON p.id  = m.proveedor_preferido_id
WHERE m.activo = TRUE
ON CONFLICT (CDMATERIAL) DO NOTHING;

-- ► DCATEGORIA_GASTO
--   Código estable derivado del nombre (no ROW_NUMBER, que cambia entre ejecuciones)
INSERT INTO DCATEGORIA_GASTO
    (CDCATEGORIA, DSCATEGORIA, TIPO)
SELECT
    'GAS_' || UPPER(REGEXP_REPLACE(SUBSTRING(cg.nombre, 1, 20), '[^A-Za-z0-9]', '', 'g')) AS CDCATEGORIA,
    cg.nombre                                                            AS DSCATEGORIA,
    cg.tipo                                                              AS TIPO
FROM categoria_gasto cg
ON CONFLICT (CDCATEGORIA) DO NOTHING;

-- ============================================================
-- 2. POBLAR HECHOS
-- ============================================================

-- ► HGASTOS
--   Fuente: tabla gasto (fecha individual + anio/mes GENERATED)
--   Reemplaza HGASTOS_MES basado en gasto_mes.periodo
INSERT INTO HGASTOS
    (IDFECHA, IDCATEGORIA, IDGASTO_OLTP, ANIO, MES, MONTO, DETALLE, ES_FIJO)
SELECT
    CAST(TO_CHAR(g.fecha, 'YYYYMMDD') AS INT)                            AS IDFECHA,
    dc.IDCATEGORIA,
    g.id                                                                 AS IDGASTO_OLTP,
    g.anio,
    g.mes,
    g.monto,
    g.detalle,
    (cg.tipo = 'fijo')                                                   AS ES_FIJO
FROM gasto g
JOIN categoria_gasto   cg ON cg.id         = g.categoria_id
JOIN DCATEGORIA_GASTO  dc ON dc.DSCATEGORIA = cg.nombre;

-- ► HPRODUCCION
--   costos totales del lote ya vienen calculados en la OLTP (columnas GENERATED)
INSERT INTO HPRODUCCION
    (IDFECHA, IDPRODUCTO, IDORDEN_OLTP, CANTPRODUCIDA,
     COSTOMATTOTAL, COSTOMOTOTAL, COSTOTOTALPROD, COSTOUNITARIO, DESTINO)
SELECT
    CAST(TO_CHAR(pr.fecha_produccion, 'YYYYMMDD') AS INT)               AS IDFECHA,
    dp.IDPRODUCTO,
    pr.orden_produccion_id                                               AS IDORDEN_OLTP,
    pr.cantidad_producida,
    pr.costo_materia_prima                                               AS COSTOMATTOTAL,
    pr.mano_de_obra                                                      AS COSTOMOTOTAL,
    pr.costo_total                                                       AS COSTOTOTALPROD,  -- columna GENERATED
    pr.costo_unitario                                                    AS COSTOUNITARIO,   -- columna GENERATED
    dpr.descripcion                                                      AS DESTINO
FROM produccion pr
JOIN producto           p   ON p.id   = pr.producto_id
JOIN destino_produccion dpr ON dpr.id = pr.destino_id
JOIN DPRODUCTO          dp  ON dp.DSPRODUCTO = p.nombre;

-- ► HCOMPRAS_MATERIAL
--   Fuente: compra_material (con material_id real, no texto libre)
INSERT INTO HCOMPRAS_MATERIAL (
    IDFECHA, IDMATERIAL, IDCOMPRA_OLTP,
    CANTCOMPRADA, PRECIOUNIT, TOTALCOMPRA,
    COSTOCOMPTOTAL, STOCKANTES, STOCKDESPUES,
    ES_EMERG, ES_TEMPORADA
)
SELECT
    CAST(TO_CHAR(cm.fecha, 'YYYYMMDD') AS INT)                          AS IDFECHA,
    dm.IDMATERIAL,
    cm.id                                                               AS IDCOMPRA_OLTP,
    cm.cantidad,
    cm.precio_unitario,
    cm.total_compra,                                                    -- columna GENERATED
    cm.total_compra                                                     AS COSTOCOMPTOTAL,
    -- stock antes/después: leer desde movimiento_material (kardex)
    (SELECT mm_ant.cantidad
     FROM movimiento_material mm_ant
     WHERE mm_ant.material_id  = cm.material_id
       AND mm_ant.referencia_id = cm.id
       AND mm_ant.referencia_tabla = 'compra_material'
     LIMIT 1)                                                           AS STOCKANTES,
    m.stock_actual                                                      AS STOCKDESPUES,
    CASE WHEN cm.notas ILIKE '%urgente%' OR cm.notas ILIKE '%emergencia%'
         THEN TRUE ELSE FALSE END                                       AS ES_EMERG,
    dt.ES_PICO                                                         AS ES_TEMPORADA
FROM compra_material cm
JOIN material  m  ON m.id  = cm.material_id
-- CDMATERIAL derivado con la misma fórmula usada en DMATERIAL
JOIN DMATERIAL dm ON dm.CDMATERIAL =
    'MAT_' || UPPER(REGEXP_REPLACE(m.nombre, '[^A-Za-z0-9]', '', 'g'))
JOIN DTIEMPO   dt ON dt.IDFECHA =
    CAST(TO_CHAR(cm.fecha, 'YYYYMMDD') AS INT);

-- ► HVENTAS
--   Fuente: vw_g_ventas_muebleria (ya adaptada a detalle_venta multi-producto)
INSERT INTO HVENTAS (
    IDFECHA, IDPRODUCTO, IDCLIENTE, IDVENTA_OLTP,
    CANTIDAD, PRECIOUNITVTA, IMPORTETOTAL, TIPOVENTA,
    COSTOESTANDAR, COSTOMATTOTAL, COSTOALMACEN,
    MARGENCONTRIB, PCTMARGEN,
    ES_DEVUELTO, MONTO_DEV, ES_TEMPORADA
)
SELECT
    IDFECHA, IDPRODUCTO, IDCLIENTE, IDVENTA_OLTP,
    CANTIDAD, PRECIOUNITVTA, IMPORTETOTAL, TIPOVENTA,
    COSTOESTANDAR, COSTOMATTOTAL, COSTOALMACEN,
    MARGENCONTRIB, PCTMARGEN,
    ES_DEVUELTO, MONTO_DEV, ES_TEMPORADA
FROM vw_g_ventas_muebleria;

-- ============================================================
-- 3. VALIDACIÓN FINAL
-- ============================================================

SELECT 'DTIEMPO'            AS tabla, COUNT(*) AS filas FROM DTIEMPO
UNION ALL SELECT 'DPRODUCTO',         COUNT(*) FROM DPRODUCTO
UNION ALL SELECT 'DCLIENTE',          COUNT(*) FROM DCLIENTE
UNION ALL SELECT 'DMATERIAL',         COUNT(*) FROM DMATERIAL
UNION ALL SELECT 'DCATEGORIA_GASTO',  COUNT(*) FROM DCATEGORIA_GASTO
UNION ALL SELECT '--- HECHOS ---',    0
UNION ALL SELECT 'HVENTAS',           COUNT(*) FROM HVENTAS
UNION ALL SELECT 'HPRODUCCION',       COUNT(*) FROM HPRODUCCION
UNION ALL SELECT 'HCOMPRAS_MATERIAL', COUNT(*) FROM HCOMPRAS_MATERIAL
UNION ALL SELECT 'HGASTOS',           COUNT(*) FROM HGASTOS
ORDER BY 1;

-- Verificación de totales vs OLTP (deben coincidir)
SELECT 'Ventas OLTP'    AS origen, SUM(total_venta)    AS total_importe FROM venta
UNION ALL
SELECT 'Ventas DM',               SUM(IMPORTETOTAL)               FROM HVENTAS;

SELECT 'Gastos OLTP'   AS origen, SUM(monto)           AS total_monto  FROM gasto
UNION ALL
SELECT 'Gastos DM',               SUM(MONTO)                      FROM HGASTOS;

SELECT 'Compras OLTP'  AS origen, SUM(total_compra)    AS total_compra FROM compra_material
UNION ALL
SELECT 'Compras DM',              SUM(TOTALCOMPRA)                FROM HCOMPRAS_MATERIAL;

-- ============================================================
-- FIN 3_poblar.sql
-- ============================================================
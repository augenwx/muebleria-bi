-- ============================================================
-- 3_poblar.sql
-- POBLAR DIMENSIONES Y TABLAS DE HECHOS (ETL MANUAL)
-- ============================================================

SET search_path TO estrella, transaccional, public;

-- =========================================
-- 1. POBLAR DIMENSIONES
-- =========================================

-- DTIEMPO
INSERT INTO DTIEMPO (IDFECHA, FECHA, DIA, MES, MESNOMBRE, TRIMESTRE, ANIO, TEMPORADA, ES_PICO)
SELECT DISTINCT
    CAST(TO_CHAR(f, 'YYYYMMDD') AS INT) AS IDFECHA,
    f                                   AS FECHA,
    EXTRACT(DAY   FROM f)::INT          AS DIA,
    EXTRACT(MONTH FROM f)::INT          AS MES,
    TO_CHAR(f, 'TMMonth')               AS MESNOMBRE,
    EXTRACT(QUARTER FROM f)::INT        AS TRIMESTRE,
    EXTRACT(YEAR  FROM f)::INT          AS ANIO,
    CASE EXTRACT(MONTH FROM f)
        WHEN 9  THEN 'Alta'
        WHEN 10 THEN 'Alta'
        WHEN 12 THEN 'Alta'
        ELSE 'Normal'
    END                                 AS TEMPORADA,
    EXTRACT(MONTH FROM f) IN (9, 10, 12) AS ES_PICO
FROM (
    SELECT fecha          AS f FROM venta          UNION
    SELECT fecha_produccion    FROM produccion      UNION
    SELECT fecha               FROM inventario      UNION
    -- FIX: usar periodo real de gasto_mes en lugar de fecha hardcodeada
    SELECT periodo             FROM gasto_mes WHERE periodo IS NOT NULL
) sub
ON CONFLICT (IDFECHA) DO NOTHING;

-- DPRODUCTO
INSERT INTO DPRODUCTO (CDPRODUCTO, DSPRODUCTO, CDCATEGORIA, PRECIOVENTA, COSTOMATERIAL, COSTOMANOOBRA, ES_ESTRELLA)
WITH costos AS (
    SELECT p.nombre AS producto,
           ROUND(AVG(pr.costo_materia_prima), 2) AS costo_mat,
           ROUND(AVG(pr.mano_de_obra), 2)        AS costo_mo
    FROM produccion pr JOIN producto p ON p.id = pr.producto_id
    GROUP BY p.nombre
),
precios AS (
    SELECT p.nombre AS producto,
           ROUND(AVG(v.precio_unitario), 2) AS precio
    FROM venta v JOIN producto p ON p.id = v.producto_id
    GROUP BY p.nombre
)
SELECT
    UPPER(REPLACE(t.nombre, ' ', '_'))   AS CDPRODUCTO,
    t.nombre                             AS DSPRODUCTO,
    'Mueble de Melamina'                 AS CDCATEGORIA,
    pr.precio                            AS PRECIOVENTA,
    c.costo_mat                          AS COSTOMATERIAL,
    c.costo_mo                           AS COSTOMANOOBRA,
    CASE WHEN (pr.precio - COALESCE(c.costo_mat,0) - COALESCE(c.costo_mo,0))
              = MAX(pr.precio - COALESCE(c.costo_mat,0) - COALESCE(c.costo_mo,0)) OVER ()
         THEN TRUE ELSE FALSE END        AS ES_ESTRELLA
FROM producto t
LEFT JOIN costos  c  ON c.producto  = t.nombre
LEFT JOIN precios pr ON pr.producto = t.nombre
ON CONFLICT (CDPRODUCTO) DO NOTHING;

-- DCLIENTE
INSERT INTO DCLIENTE (
    CDCLIENTE, NOMBRE, DOCUMENTO, TIPOCLIENTE, CANAL,
    DIRECCION, TELEFONO, EMAIL,
    LIMITE_CREDITO, SALDO_PENDIENTE, ESTADO, FRECUENCIA
)
SELECT
    'CLI_' || c.id                       AS CDCLIENTE,
    c.nombre                             AS NOMBRE,
    c.documento                          AS DOCUMENTO,
    tc.nombre                            AS TIPOCLIENTE,
    CASE tc.nombre
        WHEN 'Retail'     THEN 'Tienda directa'
        WHEN 'Mayorista'  THEN 'Pedido especial'
    END                                  AS CANAL,
    c.direccion                          AS DIRECCION,
    c.telefono                           AS TELEFONO,
    c.email                              AS EMAIL,
    c.limite_credito                     AS LIMITE_CREDITO,
    c.saldo_pendiente                    AS SALDO_PENDIENTE,
    c.estado                             AS ESTADO,
    NULL::VARCHAR                        AS FRECUENCIA
FROM cliente c
JOIN tipo_cliente tc ON tc.id = c.tipo_cliente_id
ON CONFLICT (CDCLIENTE) DO NOTHING;

-- DMATERIAL
-- FIX: CDMATERIAL derivado del nombre (estable entre ejecuciones, no ROW_NUMBER)
INSERT INTO DMATERIAL (CDMATERIAL, DSMATERIAL, TIPO, UNIDADMEDIDA, PROVEEDOR)
SELECT DISTINCT
    'MAT_' || UPPER(REGEXP_REPLACE(i.material, '[^A-Za-z0-9]', '', 'g')) AS CDMATERIAL,
    i.material AS DSMATERIAL,
    CASE
        WHEN i.material ILIKE '%Melamina%' OR i.material ILIKE '%Mapresa%'  THEN 'Melamina'
        WHEN i.material ILIKE '%Tapacanto%' OR i.material ILIKE '%Tornillo%'
          OR i.material ILIKE '%Jalador%'  OR i.material ILIKE '%Corredera%'
          OR i.material ILIKE '%Bisagra%'  OR i.material ILIKE '%Patita%'   THEN 'Accesorio'
        ELSE 'Otro'
    END                AS TIPO,
    u.nombre           AS UNIDADMEDIDA,
    NULL::VARCHAR      AS PROVEEDOR
FROM inventario i
JOIN unidad_medida u ON u.id = i.unidad_id
ON CONFLICT (CDMATERIAL) DO NOTHING;

-- DCATEGORIA_GASTO
INSERT INTO DCATEGORIA_GASTO (CDCATEGORIA, DSCATEGORIA, TIPO)
SELECT
    'GAS_' || LPAD(ROW_NUMBER() OVER (ORDER BY cg.nombre)::TEXT, 2, '0') AS CDCATEGORIA,
    cg.nombre AS DSCATEGORIA,
    CASE WHEN cg.nombre ILIKE '%Alquiler%' THEN 'Fijo' ELSE 'Variable' END AS TIPO
FROM categoria_gasto cg
ON CONFLICT (CDCATEGORIA) DO NOTHING;

-- =========================================
-- 2. POBLAR HECHOS MENORES
-- =========================================

-- HGASTOS_MES
-- FIX: IDFECHA dinámico desde gasto_mes.periodo (no hardcodeado)
INSERT INTO HGASTOS_MES (IDFECHA, IDCATEGORIA, MONTO, DETALLE, ES_FIJO)
SELECT
    CAST(TO_CHAR(gm.periodo, 'YYYYMMDD') AS INT) AS IDFECHA,
    dc.IDCATEGORIA,
    gm.monto,
    gm.detalle,
    dc.TIPO = 'Fijo' AS ES_FIJO
FROM gasto_mes gm
JOIN categoria_gasto     cg ON cg.id        = gm.categoria_id
JOIN DCATEGORIA_GASTO    dc ON dc.DSCATEGORIA = cg.nombre;

-- HPRODUCCION
INSERT INTO HPRODUCCION (IDFECHA, IDPRODUCTO, CANTPRODUCIDA, COSTOMATTOTAL, COSTOMOTOTAL, COSTOTOTALPROD, DESTINO)
SELECT
    CAST(TO_CHAR(pr.fecha_produccion, 'YYYYMMDD') AS INT) AS IDFECHA,
    dp.IDPRODUCTO,
    pr.cantidad_producida,
    ROUND(pr.cantidad_producida * pr.costo_materia_prima, 2) AS COSTOMATTOTAL,
    ROUND(pr.cantidad_producida * pr.mano_de_obra, 2)        AS COSTOMOTOTAL,
    ROUND(pr.cantidad_producida * pr.costo_total, 2)         AS COSTOTOTALPROD,
    dpr.descripcion AS DESTINO
FROM produccion pr
JOIN producto            p   ON p.id  = pr.producto_id
JOIN destino_produccion  dpr ON dpr.id = pr.destino_id
JOIN DPRODUCTO           dp  ON dp.DSPRODUCTO = p.nombre;

-- HCOMPRAS_MATERIAL
INSERT INTO HCOMPRAS_MATERIAL (
    IDFECHA, IDMATERIAL, CANTCOMPRADA, PRECIOUNIT, TOTALCOMPRA, COSTOFLETE, COSTOCOMPTOTAL,
    STOCKANTES, STOCKDESPUES, ES_EMERG, ES_TEMPORADA, CANTRETAZOS
)
SELECT
    CAST(TO_CHAR(i.fecha, 'YYYYMMDD') AS INT)                              AS IDFECHA,
    -- FIX: JOIN usando la misma lógica de CDMATERIAL (nombre normalizado)
    dm.IDMATERIAL,
    i.cantidad,
    i.precio_unitario,
    i.total_compra,
    NULL                                                                   AS COSTOFLETE,
    i.total_compra                                                         AS COSTOCOMPTOTAL,
    NULL                                                                   AS STOCKANTES,
    NULL                                                                   AS STOCKDESPUES,
    CASE WHEN i.notas ILIKE '%urgente%' OR i.notas ILIKE '%emergencia%'
         THEN TRUE ELSE FALSE END                                          AS ES_EMERG,
    dt.ES_PICO                                                             AS ES_TEMPORADA,
    NULL                                                                   AS CANTRETAZOS
FROM inventario i
JOIN DMATERIAL dm ON dm.CDMATERIAL =
    'MAT_' || UPPER(REGEXP_REPLACE(i.material, '[^A-Za-z0-9]', '', 'g'))
JOIN DTIEMPO   dt ON dt.IDFECHA = CAST(TO_CHAR(i.fecha, 'YYYYMMDD') AS INT);

-- =========================================
-- 3. POBLAR HECHO PRINCIPAL (HVENTAS)
-- =========================================

INSERT INTO HVENTAS (
    IDFECHA, IDPRODUCTO, IDCLIENTE,
    CANTIDAD, PRECIOUNITVTA, IMPORTETOTAL, TIPOVENTA,
    COSTOMATTOTAL, COSTOMOTOTAL, COSTOALMACEN,
    MARGENCONTRIB, PCTMARGEN,
    DIASENTIENDA, ES_OCIOSO, COSTOCIOSO, ES_TEMPORADA
)
SELECT
    IDFECHA, IDPRODUCTO, IDCLIENTE,
    CANTIDAD, PRECIOUNITVTA, IMPORTETOTAL, TIPOVENTA,
    COSTOMATTOTAL, COSTOMOTOTAL, COSTOALMACEN,
    MARGENCONTRIB, PCTMARGEN,
    DIASENTIENDA, ES_OCIOSO, COSTOCIOSO, ES_TEMPORADA
FROM vw_g_ventas_muebleria;

-- =========================================
-- VALIDACIÓN FINAL
-- =========================================
SELECT 'DTIEMPO'           AS tabla, COUNT(*) AS filas FROM DTIEMPO
UNION ALL SELECT 'DPRODUCTO',        COUNT(*) FROM DPRODUCTO
UNION ALL SELECT 'DCLIENTE',         COUNT(*) FROM DCLIENTE
UNION ALL SELECT 'DMATERIAL',        COUNT(*) FROM DMATERIAL
UNION ALL SELECT 'DCATEGORIA_GASTO', COUNT(*) FROM DCATEGORIA_GASTO
UNION ALL SELECT '--- HECHOS ---',   0
UNION ALL SELECT 'HVENTAS',          COUNT(*) FROM HVENTAS
UNION ALL SELECT 'HPRODUCCION',      COUNT(*) FROM HPRODUCCION
UNION ALL SELECT 'HCOMPRAS_MATERIAL',COUNT(*) FROM HCOMPRAS_MATERIAL
UNION ALL SELECT 'HGASTOS_MES',      COUNT(*) FROM HGASTOS_MES;

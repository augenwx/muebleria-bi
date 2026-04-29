-- ============================================================
--  ETL: BASE TRANSACCIONAL → MODELO ESTRELLA (MEJORADO)
--  Mueblería de Melamina
-- ============================================================
--
--  CORRECCIONES vs modelo original del compañero:
--  1. HVENTAS: PK compuesta (fecha+producto+cliente) generaba
--     colisión real (03-09 Retail+Ropero aparece 2 veces en el Excel).
--     Se reemplaza por IDVENTA SERIAL como surrogate key.
--  2. HCOMPRAS_MATERIAL y HPRODUCCION: ídem, surrogate key.
--  3. Se agrega HGASTOS_MES (tabla de hechos faltante).
--  4. DCLIENTE usa surrogate key INT, no varchar.
--  5. Se eliminan Ref incorrectas (DCLIENTE.FRECUENCIA y
--     HVENTAS.COSTOMOTOTAL no son FK).
--  6. Campos sin fuente de datos (DIASENTIENDA, STOCKANTES, etc.)
--     se dejan NULL o con lógica calculable.
--  7. MARGENCONTRIB y PCTMARGEN se calculan en ETL, no en OLTP.
--  8. COSTOALMACEN se asigna proporcionalmente desde HGASTOS_MES.
-- ============================================================

-- ── Asegurarse de estar en el schema correcto ───────────────
-- \c muebleria
-- SET search_path = public;

-- ============================================================
--  PASO 0 — CREAR ESQUEMA ESTRELLA (si no existe)
-- ============================================================
-- Forzar los esquemas de trabajo
SET search_path TO estrella, transaccional, public;

-- Asegurar que las tablas se borren si el proceso falló antes
DROP TABLE IF EXISTS HVENTAS CASCADE;
DROP TABLE IF EXISTS HPRODUCCION CASCADE;
DROP TABLE IF EXISTS HCOMPRAS_MATERIAL CASCADE;
DROP TABLE IF EXISTS HGASTOS_MES CASCADE;
DROP TABLE IF EXISTS DTIEMPO CASCADE;
DROP TABLE IF EXISTS DPRODUCTO CASCADE;
DROP TABLE IF EXISTS DCLIENTE CASCADE;
DROP TABLE IF EXISTS DMATERIAL CASCADE;
DROP TABLE IF EXISTS DCATEGORIA_GASTO CASCADE;


-- ── Dimensión Tiempo ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS DTIEMPO (
    CDFECHA     CHAR(8)      PRIMARY KEY,   -- YYYYMMDD
    FECHA       DATE         NOT NULL,
    DIA         INT          NOT NULL,
    MES         INT          NOT NULL,
    MESNOMBRE   VARCHAR(15)  NOT NULL,
    TRIMESTRE   INT          NOT NULL,
    ANIO        INT          NOT NULL,
    TEMPORADA   VARCHAR(20),                -- Alta / Normal / Baja
    ES_PICO     BOOLEAN
);

-- ── Dimensión Producto ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS DPRODUCTO (
    CDPRODUCTO    VARCHAR(20)   PRIMARY KEY,
    DSPRODUCTO    VARCHAR(60)   NOT NULL,
    CDCATEGORIA   VARCHAR(40),
    PRECIOVENTA   NUMERIC(10,2),
    COSTOMATERIAL NUMERIC(10,2),
    COSTOMANOOBRA NUMERIC(10,2),
    ES_ESTRELLA   BOOLEAN
);

-- ── Dimensión Cliente ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS DCLIENTE (
    CDCLIENTE   VARCHAR(20)  PRIMARY KEY,
    TIPOCLIENTE VARCHAR(20)  NOT NULL,
    CANAL       VARCHAR(30),
    FRECUENCIA  VARCHAR(20)
);

-- ── Dimensión Material ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS DMATERIAL (
    CDMATERIAL   VARCHAR(20)  PRIMARY KEY,
    DSMATERIAL   VARCHAR(60)  NOT NULL,
    TIPO         VARCHAR(30),
    UNIDADMEDIDA VARCHAR(20),
    PROVEEDOR    VARCHAR(80)
);

-- ── Dimensión Categoría de Gasto ────────────────────────────
CREATE TABLE IF NOT EXISTS DCATEGORIA_GASTO (
    CDCATEGORIA  VARCHAR(20)  PRIMARY KEY,
    DSCATEGORIA  VARCHAR(150) NOT NULL,
    TIPO         VARCHAR(30)  -- Fijo / Variable
);

-- ── Hechos Ventas ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS HVENTAS (
    IDVENTA        SERIAL        PRIMARY KEY,   -- ← surrogate key (corrige PK original)
    CDFECHA        CHAR(8)       NOT NULL REFERENCES DTIEMPO(CDFECHA),
    CDPRODUCTO     VARCHAR(20)   NOT NULL REFERENCES DPRODUCTO(CDPRODUCTO),
    CDCLIENTE      VARCHAR(20)   NOT NULL REFERENCES DCLIENTE(CDCLIENTE),
    CANTIDAD       NUMERIC(10,3) NOT NULL,
    PRECIOUNITVTA  NUMERIC(10,2) NOT NULL,
    IMPORTETOTAL   NUMERIC(12,2) NOT NULL,
    TIPOVENTA      VARCHAR(20)   NOT NULL,
    COSTOMATTOTAL  NUMERIC(12,2) NOT NULL,
    COSTOMOTOTAL   NUMERIC(12,2),
    COSTOALMACEN   NUMERIC(10,2),              -- proporcional de gastos fijos
    MARGENCONTRIB  NUMERIC(12,2) NOT NULL,     -- calculado en ETL
    PCTMARGEN      NUMERIC(6,2),               -- calculado en ETL
    DIASENTIENDA   INT,                        -- futuro: requiere fecha ingreso a tienda
    ES_OCIOSO      BOOLEAN,
    COSTOCIOSO     NUMERIC(10,2),
    ES_TEMPORADA   BOOLEAN
);

-- ── Hechos Compras de Material ──────────────────────────────
CREATE TABLE IF NOT EXISTS HCOMPRAS_MATERIAL (
    IDCOMPRA       SERIAL        PRIMARY KEY,  -- ← surrogate key
    CDFECHA        CHAR(8)       NOT NULL REFERENCES DTIEMPO(CDFECHA),
    CDMATERIAL     VARCHAR(20)   NOT NULL REFERENCES DMATERIAL(CDMATERIAL),
    CANTCOMPRADA   NUMERIC(10,3) NOT NULL,
    PRECIOUNIT     NUMERIC(10,4) NOT NULL,
    TOTALCOMPRA    NUMERIC(12,2) NOT NULL,
    COSTOFLETE     NUMERIC(10,2),
    COSTOCOMPTOTAL NUMERIC(12,2) NOT NULL,
    STOCKANTES     NUMERIC(10,3),
    STOCKDESPUES   NUMERIC(10,3),
    ES_EMERG       BOOLEAN,
    ES_TEMPORADA   BOOLEAN,
    CANTRETAZOS    NUMERIC(10,3)
);

-- ── Hechos Producción ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS HPRODUCCION (
    IDPRODUCCION   SERIAL        PRIMARY KEY,  -- ← surrogate key
    CDFECHA        CHAR(8)       NOT NULL REFERENCES DTIEMPO(CDFECHA),
    CDPRODUCTO     VARCHAR(20)   NOT NULL REFERENCES DPRODUCTO(CDPRODUCTO),
    CANTPRODUCIDA  NUMERIC(10,3) NOT NULL,
    COSTOMATTOTAL  NUMERIC(12,2) NOT NULL,
    COSTOMOTOTAL   NUMERIC(12,2) NOT NULL,
    COSTOTOTALPROD NUMERIC(12,2) NOT NULL,
    DESTINO        VARCHAR(30)
);

-- ── Hechos Gastos del Mes (tabla faltante en modelo original) ─
CREATE TABLE IF NOT EXISTS HGASTOS_MES (
    IDGASTO       SERIAL        PRIMARY KEY,
    CDFECHA       CHAR(8)       NOT NULL REFERENCES DTIEMPO(CDFECHA),
    CDCATEGORIA   VARCHAR(20)   NOT NULL REFERENCES DCATEGORIA_GASTO(CDCATEGORIA),
    MONTO         NUMERIC(12,2) NOT NULL,
    DETALLE       TEXT,
    ES_FIJO       BOOLEAN
);

-- ============================================================
--  PASO 1 — POBLAR DTIEMPO
--  (genera todos los días de marzo 2026 desde los datos)
-- ============================================================
INSERT INTO DTIEMPO (CDFECHA, FECHA, DIA, MES, MESNOMBRE, TRIMESTRE, ANIO, TEMPORADA, ES_PICO)
SELECT DISTINCT
    TO_CHAR(f, 'YYYYMMDD')           AS CDFECHA,
    f                                AS FECHA,
    EXTRACT(DAY   FROM f)::INT       AS DIA,
    EXTRACT(MONTH FROM f)::INT       AS MES,
    TO_CHAR(f, 'TMMonth')            AS MESNOMBRE,
    EXTRACT(QUARTER FROM f)::INT     AS TRIMESTRE,
    EXTRACT(YEAR  FROM f)::INT       AS ANIO,
    CASE EXTRACT(MONTH FROM f)
        WHEN 9  THEN 'Alta'
        WHEN 10 THEN 'Alta'
        WHEN 12 THEN 'Alta'
        ELSE 'Normal'
    END                              AS TEMPORADA,
    EXTRACT(MONTH FROM f) IN (9, 10, 12) AS ES_PICO
FROM (
    SELECT fecha       AS f FROM venta
    UNION
    SELECT fecha_produccion FROM produccion
    UNION
    SELECT fecha       FROM inventario
    UNION
    SELECT '2026-03-01'::date        -- período de gastos
) sub
ON CONFLICT (CDFECHA) DO NOTHING;

-- ============================================================
--  PASO 2 — POBLAR DPRODUCTO
-- ============================================================
INSERT INTO DPRODUCTO (CDPRODUCTO, DSPRODUCTO, CDCATEGORIA, PRECIOVENTA, COSTOMATERIAL, COSTOMANOOBRA, ES_ESTRELLA)
WITH costos AS (
    -- costo unitario promedio por producto (fuente: produccion)
    SELECT
        p.nombre                            AS producto,
        ROUND(AVG(pr.costo_materia_prima), 2) AS costo_mat,
        ROUND(AVG(pr.mano_de_obra), 2)        AS costo_mo
    FROM produccion pr
    JOIN producto p ON p.id = pr.producto_id
    GROUP BY p.nombre
),
precios AS (
    -- precio de venta promedio por producto (fuente: venta)
    SELECT
        p.nombre                            AS producto,
        ROUND(AVG(v.precio_unitario), 2)    AS precio
    FROM venta v
    JOIN producto p ON p.id = v.producto_id
    GROUP BY p.nombre
),
todos AS (
    -- catálogo completo de productos
    SELECT nombre FROM producto
)
SELECT
    UPPER(REPLACE(t.nombre, ' ', '_'))          AS CDPRODUCTO,
    t.nombre                                    AS DSPRODUCTO,
    'Mueble de Melamina'                        AS CDCATEGORIA,
    pr.precio                                   AS PRECIOVENTA,
    c.costo_mat                                 AS COSTOMATERIAL,
    c.costo_mo                                  AS COSTOMANOOBRA,
    -- ES_ESTRELLA: producto con mayor margen bruto
    CASE WHEN (pr.precio - COALESCE(c.costo_mat,0) - COALESCE(c.costo_mo,0))
              = MAX(pr.precio - COALESCE(c.costo_mat,0) - COALESCE(c.costo_mo,0))
                  OVER () THEN TRUE ELSE FALSE
    END                                         AS ES_ESTRELLA
FROM todos t
LEFT JOIN costos  c  ON c.producto  = t.nombre
LEFT JOIN precios pr ON pr.producto = t.nombre
ON CONFLICT (CDPRODUCTO) DO NOTHING;

-- ============================================================
--  PASO 3 — POBLAR DCLIENTE
-- ============================================================
INSERT INTO DCLIENTE (CDCLIENTE, TIPOCLIENTE, CANAL, FRECUENCIA)
SELECT DISTINCT
    UPPER(REPLACE(tc.nombre, ' ', '_'))  AS CDCLIENTE,
    tc.nombre                            AS TIPOCLIENTE,
    CASE tc.nombre
        WHEN 'Retail'    THEN 'Tienda directa'
        WHEN 'Mayorista' THEN 'Pedido especial'
    END                                  AS CANAL,
    NULL::VARCHAR                        AS FRECUENCIA   -- derivado posterior
FROM tipo_cliente tc
ON CONFLICT (CDCLIENTE) DO NOTHING;

-- ============================================================
--  PASO 4 — POBLAR DMATERIAL
-- ============================================================
INSERT INTO DMATERIAL (CDMATERIAL, DSMATERIAL, TIPO, UNIDADMEDIDA, PROVEEDOR)
SELECT DISTINCT
    'MAT_' || LPAD(ROW_NUMBER() OVER (ORDER BY i.material)::TEXT, 3, '0') AS CDMATERIAL,
    i.material                                                              AS DSMATERIAL,
    CASE
        WHEN i.material ILIKE '%Melamina%'  THEN 'Melamina'
        WHEN i.material ILIKE '%Mapresa%'   THEN 'Melamina'
        WHEN i.material ILIKE '%Tapacanto%' THEN 'Accesorio'
        WHEN i.material ILIKE '%Tornillo%'  THEN 'Accesorio'
        WHEN i.material ILIKE '%Jalador%'   THEN 'Accesorio'
        WHEN i.material ILIKE '%Corredera%' THEN 'Accesorio'
        WHEN i.material ILIKE '%Bisagra%'   THEN 'Accesorio'
        WHEN i.material ILIKE '%Patita%'    THEN 'Accesorio'
        ELSE 'Otro'
    END                                                                     AS TIPO,
    u.nombre                                                                AS UNIDADMEDIDA,
    NULL::VARCHAR                                                           AS PROVEEDOR
FROM inventario i
JOIN unidad_medida u ON u.id = i.unidad_id
ON CONFLICT (CDMATERIAL) DO NOTHING;

-- ============================================================
--  PASO 5 — POBLAR DCATEGORIA_GASTO
-- ============================================================
INSERT INTO DCATEGORIA_GASTO (CDCATEGORIA, DSCATEGORIA, TIPO)
SELECT
    'GAS_' || LPAD(ROW_NUMBER() OVER (ORDER BY cg.nombre)::TEXT, 2, '0') AS CDCATEGORIA,
    cg.nombre                                                              AS DSCATEGORIA,
    CASE
        WHEN cg.nombre ILIKE '%Alquiler%'    THEN 'Fijo'
        WHEN cg.nombre ILIKE '%Mano de Obra%'THEN 'Variable'
        WHEN cg.nombre ILIKE '%Compra%'      THEN 'Variable'
        ELSE 'Variable'
    END                                                                    AS TIPO
FROM categoria_gasto cg
ON CONFLICT (CDCATEGORIA) DO NOTHING;

-- ============================================================
--  PASO 6 — POBLAR HGASTOS_MES
-- ============================================================
INSERT INTO HGASTOS_MES (CDFECHA, CDCATEGORIA, MONTO, DETALLE, ES_FIJO)
SELECT
    '20260301'          AS CDFECHA,
    dc.CDCATEGORIA,
    gm.monto,
    gm.detalle,
    dc.TIPO = 'Fijo'    AS ES_FIJO
FROM gasto_mes gm
JOIN categoria_gasto  cg ON cg.id    = gm.categoria_id
JOIN DCATEGORIA_GASTO dc ON dc.DSCATEGORIA = cg.nombre;

-- ============================================================
--  PASO 7 — POBLAR HPRODUCCION
-- ============================================================
INSERT INTO HPRODUCCION (CDFECHA, CDPRODUCTO, CANTPRODUCIDA, COSTOMATTOTAL, COSTOMOTOTAL, COSTOTOTALPROD, DESTINO)
SELECT
    TO_CHAR(pr.fecha_produccion, 'YYYYMMDD')                AS CDFECHA,
    dp.CDPRODUCTO,
    pr.cantidad_producida                                    AS CANTPRODUCIDA,
    ROUND(pr.cantidad_producida * pr.costo_materia_prima, 2) AS COSTOMATTOTAL,
    ROUND(pr.cantidad_producida * pr.mano_de_obra, 2)        AS COSTOMOTOTAL,
    ROUND(pr.cantidad_producida * pr.costo_total, 2)         AS COSTOTOTALPROD,
    dpr.descripcion                                          AS DESTINO
FROM produccion pr
JOIN producto            p   ON p.id  = pr.producto_id
JOIN destino_produccion  dpr ON dpr.id = pr.destino_id
JOIN DPRODUCTO           dp  ON dp.DSPRODUCTO = p.nombre;

-- ============================================================
--  PASO 8 — POBLAR HCOMPRAS_MATERIAL
-- ============================================================

-- Tabla temporal para mapear material → CDMATERIAL
-- (necesaria porque DMATERIAL usó ROW_NUMBER en INSERT anterior)
CREATE TEMP TABLE tmp_mat_map AS
SELECT CDMATERIAL, DSMATERIAL FROM DMATERIAL;

INSERT INTO HCOMPRAS_MATERIAL (
    CDFECHA, CDMATERIAL, CANTCOMPRADA, PRECIOUNIT,
    TOTALCOMPRA, COSTOFLETE, COSTOCOMPTOTAL,
    STOCKANTES, STOCKDESPUES, ES_EMERG, ES_TEMPORADA, CANTRETAZOS
)
SELECT
    TO_CHAR(i.fecha, 'YYYYMMDD')    AS CDFECHA,
    dm.CDMATERIAL,
    i.cantidad                       AS CANTCOMPRADA,
    i.precio_unitario                AS PRECIOUNIT,
    i.total_compra                   AS TOTALCOMPRA,
    NULL                             AS COSTOFLETE,       -- sin fuente
    i.total_compra                   AS COSTOCOMPTOTAL,   -- sin flete conocido
    NULL                             AS STOCKANTES,       -- sin fuente
    NULL                             AS STOCKDESPUES,
    CASE WHEN i.notas ILIKE '%urgente%' OR i.notas ILIKE '%emergencia%'
         THEN TRUE ELSE FALSE END    AS ES_EMERG,
    dt.ES_PICO                       AS ES_TEMPORADA,
    NULL                             AS CANTRETAZOS
FROM inventario i
JOIN tmp_mat_map dm ON dm.DSMATERIAL = i.material
JOIN DTIEMPO     dt ON dt.CDFECHA = TO_CHAR(i.fecha, 'YYYYMMDD');

DROP TABLE tmp_mat_map;

-- ============================================================
--  PASO 9 — POBLAR HVENTAS (con cálculo de margen)
-- ============================================================

-- Costo de almacén proporcional por unidad vendida
-- = (Gastos fijos del mes) / (total unidades vendidas del mes)
WITH total_unidades AS (
    SELECT SUM(cantidad) AS total FROM venta
),
gastos_fijos AS (
    SELECT SUM(gm.monto) AS total
    FROM gasto_mes gm
    JOIN categoria_gasto cg ON cg.id = gm.categoria_id
    WHERE cg.nombre ILIKE '%Alquiler%'   -- solo gastos fijos asignables
),
costo_almacen_unit AS (
    SELECT ROUND(gf.total::NUMERIC / NULLIF(tu.total, 0), 4) AS costo_unit
    FROM gastos_fijos gf, total_unidades tu
)
INSERT INTO HVENTAS (
    CDFECHA, CDPRODUCTO, CDCLIENTE,
    CANTIDAD, PRECIOUNITVTA, IMPORTETOTAL, TIPOVENTA,
    COSTOMATTOTAL, COSTOMOTOTAL, COSTOALMACEN,
    MARGENCONTRIB, PCTMARGEN,
    DIASENTIENDA, ES_OCIOSO, COSTOCIOSO, ES_TEMPORADA
)
SELECT
    TO_CHAR(v.fecha, 'YYYYMMDD')                                    AS CDFECHA,
    dp.CDPRODUCTO,
    dc.CDCLIENTE,
    v.cantidad                                                       AS CANTIDAD,
    v.precio_unitario                                                AS PRECIOUNITVTA,
    v.total_venta                                                    AS IMPORTETOTAL,
    tv.nombre                                                        AS TIPOVENTA,
    -- Costo mat. prima total = costo_unit × cantidad
    ROUND(dp.COSTOMATERIAL * v.cantidad, 2)                         AS COSTOMATTOTAL,
    -- Costo mano de obra total
    ROUND(dp.COSTOMANOOBRA * v.cantidad, 2)                         AS COSTOMOTOTAL,
    -- Costo almacén proporcional
    ROUND(ca.costo_unit * v.cantidad, 2)                            AS COSTOALMACEN,
    -- Margen de contribución = ingreso − costos variables
    ROUND(v.total_venta
          - COALESCE(dp.COSTOMATERIAL, 0) * v.cantidad
          - COALESCE(dp.COSTOMANOOBRA, 0) * v.cantidad, 2)          AS MARGENCONTRIB,
    -- Margen %
    CASE WHEN v.total_venta > 0
         THEN ROUND(
             (v.total_venta
              - COALESCE(dp.COSTOMATERIAL, 0) * v.cantidad
              - COALESCE(dp.COSTOMANOOBRA, 0) * v.cantidad
             ) / v.total_venta * 100, 2)
         ELSE 0
    END                                                             AS PCTMARGEN,
    NULL                                                             AS DIASENTIENDA,
    NULL                                                             AS ES_OCIOSO,
    NULL                                                             AS COSTOCIOSO,
    dt.ES_PICO                                                       AS ES_TEMPORADA
FROM venta v
JOIN producto      p   ON p.id  = v.producto_id
JOIN tipo_cliente  tc  ON tc.id = v.tipo_cliente_id
JOIN tipo_venta    tv  ON tv.id = v.tipo_venta_id
JOIN DPRODUCTO     dp  ON dp.DSPRODUCTO  = p.nombre
JOIN DCLIENTE      dc  ON dc.TIPOCLIENTE = tc.nombre
JOIN DTIEMPO       dt  ON dt.CDFECHA = TO_CHAR(v.fecha, 'YYYYMMDD'),
costo_almacen_unit ca;

-- ============================================================
--  VERIFICACIÓN FINAL
-- ============================================================
SELECT 'DTIEMPO'          AS tabla, COUNT(*) AS registros FROM DTIEMPO
UNION ALL SELECT 'DPRODUCTO',    COUNT(*) FROM DPRODUCTO
UNION ALL SELECT 'DCLIENTE',     COUNT(*) FROM DCLIENTE
UNION ALL SELECT 'DMATERIAL',    COUNT(*) FROM DMATERIAL
UNION ALL SELECT 'DCATEGORIA_GASTO', COUNT(*) FROM DCATEGORIA_GASTO
UNION ALL SELECT 'HVENTAS',      COUNT(*) FROM HVENTAS
UNION ALL SELECT 'HPRODUCCION',  COUNT(*) FROM HPRODUCCION
UNION ALL SELECT 'HCOMPRAS_MATERIAL', COUNT(*) FROM HCOMPRAS_MATERIAL
UNION ALL SELECT 'HGASTOS_MES',  COUNT(*) FROM HGASTOS_MES
ORDER BY tabla;

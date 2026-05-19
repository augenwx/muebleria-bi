-- 
-- CREACIÓN DE LA ESTRUCTURA DEL DATAMART (MODELO ESTRELLA)

-- ============================================================

CREATE SCHEMA IF NOT EXISTS estrella;
SET search_path TO estrella, transaccional, public;

-- Limpiar si el proceso falló antes
DROP TABLE IF EXISTS HVENTAS           CASCADE;
DROP TABLE IF EXISTS HPRODUCCION       CASCADE;
DROP TABLE IF EXISTS HCOMPRAS_MATERIAL CASCADE;
DROP TABLE IF EXISTS HGASTOS           CASCADE;
DROP VIEW  IF EXISTS vw_g_ventas_muebleria CASCADE;
DROP TABLE IF EXISTS DTIEMPO           CASCADE;
DROP TABLE IF EXISTS DPRODUCTO         CASCADE;
DROP TABLE IF EXISTS DCLIENTE          CASCADE;
DROP TABLE IF EXISTS DMATERIAL         CASCADE;
DROP TABLE IF EXISTS DCATEGORIA_GASTO  CASCADE;

-- ============================================================
-- DIMENSIONES
-- ============================================================

-- DTIEMPO: una fila por cada fecha presente en los hechos
CREATE TABLE DTIEMPO (
    IDFECHA     INT          PRIMARY KEY,   -- clave YYYYMMDD
    FECHA       DATE         NOT NULL,
    DIA         INT          NOT NULL,
    MES         INT          NOT NULL,
    MESNOMBRE   VARCHAR(15)  NOT NULL,
    TRIMESTRE   INT          NOT NULL,
    ANIO        INT          NOT NULL,
    TEMPORADA   VARCHAR(20),               -- 'Alta' / 'Normal'
    ES_PICO     BOOLEAN
);

-- DPRODUCTO: productos con costos y precio (SCD Tipo 2 preparado)
CREATE TABLE DPRODUCTO (
    IDPRODUCTO    SERIAL        PRIMARY KEY,
    CDPRODUCTO    VARCHAR(80)   NOT NULL UNIQUE,
    DSPRODUCTO    VARCHAR(100)  NOT NULL,
    CDCATEGORIA   VARCHAR(60),
    PRECIOVENTA   NUMERIC(10,2),
    COSTOMATERIAL NUMERIC(10,2),
    COSTOMANOOBRA NUMERIC(10,2),
    ES_ESTRELLA   BOOLEAN,
    FECHA_DESDE   DATE          DEFAULT CURRENT_DATE,
    FECHA_HASTA   DATE          DEFAULT '9999-12-31',
    ES_VIGENTE    BOOLEAN       DEFAULT TRUE
);

-- DCLIENTE: dimensión de clientes reales (ahora la OLTP tiene tabla cliente)
CREATE TABLE DCLIENTE (
    IDCLIENTE     SERIAL       PRIMARY KEY,
    CDCLIENTE     VARCHAR(30)  NOT NULL UNIQUE,   -- documento del cliente
    NOMBRE        VARCHAR(150) NOT NULL,
    TIPOCLIENTE   VARCHAR(20)  NOT NULL,           -- 'Retail' / 'Mayorista'
    CANAL         VARCHAR(30),
    LIMITE_CREDITO NUMERIC(12,2),
    FRECUENCIA    VARCHAR(20)                      -- se completa con historial multi-mes
);

-- DMATERIAL: materiales con FK real desde compra_material (ya no texto libre)
CREATE TABLE DMATERIAL (
    IDMATERIAL   SERIAL       PRIMARY KEY,
    CDMATERIAL   VARCHAR(80)  NOT NULL UNIQUE,    -- 'MAT_' + nombre normalizado
    DSMATERIAL   VARCHAR(150) NOT NULL,
    TIPO         VARCHAR(30),
    UNIDADMEDIDA VARCHAR(20),
    PROVEEDOR    VARCHAR(100)
);

-- DCATEGORIA_GASTO: categorías de la tabla gasto
CREATE TABLE DCATEGORIA_GASTO (
    IDCATEGORIA  SERIAL       PRIMARY KEY,
    CDCATEGORIA  VARCHAR(30)  NOT NULL UNIQUE,
    DSCATEGORIA  VARCHAR(150) NOT NULL,
    TIPO         VARCHAR(30)                      -- 'fijo' / 'variable'
);

-- ============================================================
-- TABLAS DE HECHOS
-- ============================================================

-- HVENTAS: una fila por línea de detalle_venta (multi-producto por venta)
CREATE TABLE HVENTAS (
    IDHVENTA       SERIAL        PRIMARY KEY,
    -- claves de dimensión
    IDFECHA        INT           NOT NULL REFERENCES DTIEMPO(IDFECHA),
    IDPRODUCTO     INT           NOT NULL REFERENCES DPRODUCTO(IDPRODUCTO),
    IDCLIENTE      INT           NOT NULL REFERENCES DCLIENTE(IDCLIENTE),
    -- referencia a venta origen
    IDVENTA_OLTP   INT           NOT NULL,        -- venta.id en OLTP
    -- métricas de venta
    CANTIDAD       NUMERIC(10,3) NOT NULL,
    PRECIOUNITVTA  NUMERIC(10,2) NOT NULL,
    IMPORTETOTAL   NUMERIC(12,2) NOT NULL,        -- subtotal de la línea
    TIPOVENTA      VARCHAR(20)   NOT NULL,
    -- métricas de costo y margen
    COSTOESTANDAR  NUMERIC(10,2),                 -- producto.costo_estandar
    COSTOMATTOTAL  NUMERIC(12,2) NOT NULL,        -- costo_estandar * cantidad
    COSTOALMACEN   NUMERIC(10,2),                 -- alquiler prorrateado
    MARGENCONTRIB  NUMERIC(12,2) NOT NULL,
    PCTMARGEN      NUMERIC(6,2),
    -- métricas de análisis adicionales
    ES_DEVUELTO    BOOLEAN       DEFAULT FALSE,
    MONTO_DEV      NUMERIC(12,2) DEFAULT 0,
    ES_TEMPORADA   BOOLEAN
);

-- HPRODUCCION: una fila por lote de producción real
CREATE TABLE HPRODUCCION (
    IDHPRODUCCION  SERIAL        PRIMARY KEY,
    IDFECHA        INT           NOT NULL REFERENCES DTIEMPO(IDFECHA),
    IDPRODUCTO     INT           NOT NULL REFERENCES DPRODUCTO(IDPRODUCTO),
    IDORDEN_OLTP   INT,                           -- orden_produccion.id en OLTP
    CANTPRODUCIDA  NUMERIC(10,3) NOT NULL,
    -- costos totales del lote (corrección v3: ya no por unidad)
    COSTOMATTOTAL  NUMERIC(12,2) NOT NULL,
    COSTOMOTOTAL   NUMERIC(12,2) NOT NULL,
    COSTOTOTALPROD NUMERIC(12,2) NOT NULL,
    COSTOUNITARIO  NUMERIC(10,4),                 -- calculado: total/cantidad
    DESTINO        VARCHAR(50)
);

-- HCOMPRAS_MATERIAL: una fila por compra de material
CREATE TABLE HCOMPRAS_MATERIAL (
    IDHCOMPRA      SERIAL        PRIMARY KEY,
    IDFECHA        INT           NOT NULL REFERENCES DTIEMPO(IDFECHA),
    IDMATERIAL     INT           NOT NULL REFERENCES DMATERIAL(IDMATERIAL),
    IDCOMPRA_OLTP  INT,                           -- compra_material.id en OLTP
    CANTCOMPRADA   NUMERIC(10,3) NOT NULL,
    PRECIOUNIT     NUMERIC(10,4) NOT NULL,
    TOTALCOMPRA    NUMERIC(12,2) NOT NULL,
    COSTOCOMPTOTAL NUMERIC(12,2) NOT NULL,
    STOCKANTES     NUMERIC(10,3),
    STOCKDESPUES   NUMERIC(10,3),
    ES_EMERG       BOOLEAN,
    ES_TEMPORADA   BOOLEAN
);

-- HGASTOS: una fila por gasto individual (tabla gasto de la nueva OLTP)
CREATE TABLE HGASTOS (
    IDHGASTO      SERIAL        PRIMARY KEY,
    IDFECHA       INT           NOT NULL REFERENCES DTIEMPO(IDFECHA),
    IDCATEGORIA   INT           NOT NULL REFERENCES DCATEGORIA_GASTO(IDCATEGORIA),
    IDGASTO_OLTP  INT,                            -- gasto.id en OLTP
    ANIO          SMALLINT      NOT NULL,
    MES           SMALLINT      NOT NULL,
    MONTO         NUMERIC(12,2) NOT NULL,
    DETALLE       TEXT,
    ES_FIJO       BOOLEAN
);

-- ============================================================
-- ÍNDICES EN CLAVES FORÁNEAS (mejora consultas analíticas)
-- ============================================================

CREATE INDEX idx_hventas_fecha      ON HVENTAS(IDFECHA);
CREATE INDEX idx_hventas_producto   ON HVENTAS(IDPRODUCTO);
CREATE INDEX idx_hventas_cliente    ON HVENTAS(IDCLIENTE);
CREATE INDEX idx_hventas_tipo       ON HVENTAS(TIPOVENTA);

CREATE INDEX idx_hprod_fecha        ON HPRODUCCION(IDFECHA);
CREATE INDEX idx_hprod_producto     ON HPRODUCCION(IDPRODUCTO);

CREATE INDEX idx_hcompras_fecha     ON HCOMPRAS_MATERIAL(IDFECHA);
CREATE INDEX idx_hcompras_material  ON HCOMPRAS_MATERIAL(IDMATERIAL);

CREATE INDEX idx_hgastos_fecha      ON HGASTOS(IDFECHA);
CREATE INDEX idx_hgastos_categoria  ON HGASTOS(IDCATEGORIA);
CREATE INDEX idx_hgastos_anio_mes   ON HGASTOS(ANIO, MES);

-- ============================================================
-- FIN 1_dm.sql
-- ============================================================
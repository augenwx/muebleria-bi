-- ============================================================
-- 1_dm.sql  — 4.0
-- CREACIÓN DE LA ESTRUCTURA DEL DATAMART (MODELO ESTRELLA)
-- Esquema: marts
--

-- ============================================================

CREATE SCHEMA IF NOT EXISTS marts;
SET search_path TO marts, transaccional, public;

-- Limpiar si el proceso falló antes
DROP TABLE IF EXISTS fact_ventas         CASCADE;
DROP TABLE IF EXISTS fact_produccion     CASCADE;
DROP TABLE IF EXISTS fact_inventario     CASCADE;
DROP TABLE IF EXISTS fact_gastos         CASCADE;
DROP TABLE IF EXISTS dim_tiempo          CASCADE;
DROP TABLE IF EXISTS dim_producto        CASCADE;
DROP TABLE IF EXISTS dim_cliente         CASCADE;
DROP TABLE IF EXISTS dim_material        CASCADE;
DROP TABLE IF EXISTS dim_categoria_gasto CASCADE;
DROP TABLE IF EXISTS dim_proveedor       CASCADE;
DROP TABLE IF EXISTS dim_destino_prod    CASCADE;
DROP TABLE IF EXISTS dim_tipo_venta      CASCADE;
DROP TABLE IF EXISTS dim_usuario         CASCADE;

-- ============================================================
-- DIMENSIONES
-- ============================================================

-- dim_tiempo: una fila por cada fecha presente en los hechos
CREATE TABLE dim_tiempo (
    fecha_key         INT          PRIMARY KEY,   -- clave YYYYMMDD
    fecha             DATE         NOT NULL,
    dia               INT          NOT NULL,
    mes               INT          NOT NULL,
    mes_nombre        TEXT         NOT NULL,
    trimestre         INT          NOT NULL,
    anio              INT          NOT NULL,
    dia_semana_num    INT          NOT NULL,
    dia_semana_nombre TEXT         NOT NULL,
    semana_anio       INT          NOT NULL
);

-- dim_producto: productos con precios y márgenes estándar
CREATE TABLE dim_producto (
    producto_id            BIGINT,
    nombre                 VARCHAR,
    costo_estandar         NUMERIC,
    precio_venta_retail    NUMERIC,
    precio_venta_mayorista NUMERIC,
    margen_retail          NUMERIC,
    margen_mayorista       NUMERIC,
    activo                 BOOLEAN
);

-- dim_cliente: clientes con tipo (Retail / Mayorista)
CREATE TABLE dim_cliente (
    cliente_id      BIGINT,
    documento       VARCHAR,
    nombre          VARCHAR,
    razon_social    VARCHAR,
    tipo_cliente    VARCHAR,
    direccion       VARCHAR,
    telefono        VARCHAR,
    email           VARCHAR,
    limite_credito  NUMERIC,
    estado          VARCHAR,
    activo          BOOLEAN
);

-- dim_material: materias primas con unidad de medida
CREATE TABLE dim_material (
    material_id        BIGINT,
    nombre             VARCHAR,
    unidad_nombre      VARCHAR,
    unidad_abreviatura VARCHAR,
    stock_minimo       NUMERIC,
    activo             BOOLEAN
);

-- dim_categoria_gasto: categorías de gasto (fijo / variable)
CREATE TABLE dim_categoria_gasto (
    categoria_id BIGINT,
    categoria    VARCHAR,
    tipo_gasto   VARCHAR
);

-- dim_proveedor: proveedores de materiales
CREATE TABLE dim_proveedor (
    proveedor_id BIGINT,
    ruc          VARCHAR,
    nombre       VARCHAR,
    contacto     VARCHAR,
    telefono     VARCHAR,
    email        VARCHAR,
    direccion    VARCHAR,
    activo       BOOLEAN
);

-- dim_destino_prod: destino de la producción
CREATE TABLE dim_destino_prod (
    destino_id BIGINT,
    destino    VARCHAR
);

-- dim_tipo_venta: tipo de venta (Contado / Crédito)
CREATE TABLE dim_tipo_venta (
    tipo_venta_id BIGINT,
    tipo_venta    VARCHAR
);

-- dim_usuario: usuarios del sistema
CREATE TABLE dim_usuario (
    usuario_id BIGINT,
    nombre     VARCHAR,
    email      VARCHAR,
    rol        VARCHAR,
    activo     BOOLEAN
);

-- ============================================================
-- TABLAS DE HECHOS
-- ============================================================

-- fact_ventas: una fila por línea de detalle_venta
CREATE TABLE fact_ventas (
    detalle_venta_id BIGINT,
    tiempo_key       INT            NOT NULL REFERENCES dim_tiempo(fecha_key),
    cliente_id       BIGINT,
    producto_id      BIGINT,
    tipo_venta_id    BIGINT,
    usuario_id       BIGINT,
    venta_id_oltp    BIGINT,
    cantidad         BIGINT,
    precio_unitario  NUMERIC,
    subtotal         NUMERIC,
    costo_estandar   NUMERIC,
    costo_total      NUMERIC,
    margen_bruto     NUMERIC,
    pct_margen       NUMERIC
);

-- fact_produccion: una fila por lote de producción
CREATE TABLE fact_produccion (
    produccion_id       BIGINT,
    tiempo_key          INT            NOT NULL REFERENCES dim_tiempo(fecha_key),
    producto_id         BIGINT,
    destino_id          BIGINT,
    usuario_id          BIGINT,
    orden_id_oltp       BIGINT,
    numero_orden        VARCHAR,
    cantidad_producida  BIGINT,
    costo_materia_prima NUMERIC,
    mano_de_obra        NUMERIC,
    costo_total         NUMERIC,
    costo_unitario      NUMERIC
);

-- fact_inventario: una fila por movimiento de material (Kardex)
CREATE TABLE fact_inventario (
    movimiento_id    BIGINT,
    tiempo_key       INT            NOT NULL REFERENCES dim_tiempo(fecha_key),
    material_id      BIGINT,
    proveedor_id     BIGINT,        -- NULL para salidas y ajustes
    tipo_movimiento  VARCHAR,
    cantidad         NUMERIC,
    precio_unitario  NUMERIC,
    total_valor      NUMERIC,
    referencia_id    BIGINT,
    referencia_tabla VARCHAR,
    notas            VARCHAR
);

-- fact_gastos: una fila por gasto operativo registrado
CREATE TABLE fact_gastos (
    gasto_id     BIGINT,
    tiempo_key   INT            NOT NULL REFERENCES dim_tiempo(fecha_key),
    categoria_id BIGINT,
    usuario_id   BIGINT,
    anio         BIGINT,
    mes          BIGINT,
    monto        NUMERIC,
    detalle      VARCHAR,
    comprobante  VARCHAR
);

-- ============================================================
-- ÍNDICES EN CLAVES FORÁNEAS (mejora consultas analíticas)
-- ============================================================

CREATE INDEX idx_fact_ventas_tiempo     ON fact_ventas(tiempo_key);
CREATE INDEX idx_fact_ventas_cliente    ON fact_ventas(cliente_id);
CREATE INDEX idx_fact_ventas_producto   ON fact_ventas(producto_id);
CREATE INDEX idx_fact_ventas_tipo       ON fact_ventas(tipo_venta_id);

CREATE INDEX idx_fact_prod_tiempo       ON fact_produccion(tiempo_key);
CREATE INDEX idx_fact_prod_producto     ON fact_produccion(producto_id);
CREATE INDEX idx_fact_prod_destino      ON fact_produccion(destino_id);

CREATE INDEX idx_fact_inv_tiempo        ON fact_inventario(tiempo_key);
CREATE INDEX idx_fact_inv_material      ON fact_inventario(material_id);
CREATE INDEX idx_fact_inv_proveedor     ON fact_inventario(proveedor_id);

CREATE INDEX idx_fact_gastos_tiempo     ON fact_gastos(tiempo_key);
CREATE INDEX idx_fact_gastos_categoria  ON fact_gastos(categoria_id);
CREATE INDEX idx_fact_gastos_anio_mes   ON fact_gastos(anio, mes);

-- ============================================================
-- FIN 1_dm.sql
-- ============================================================
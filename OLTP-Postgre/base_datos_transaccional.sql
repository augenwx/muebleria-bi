-- ============================================================
--  BASE DE DATOS TRANSACCIONAL - MUEBLERIA / CARPINTERÍA
--  Generado desde: data.xlsx (hojas: venta, producion mes,
--                              inventario, gastos mes)
--  Moneda: Soles peruanos (S/)
-- ============================================================

-- ── Crear base de datos (ejecutar como superusuario si es necesario) ──
-- CREATE DATABASE muebleria;
-- \c muebleria

-- ============================================================
--  TABLAS DE CATÁLOGO / MAESTRAS
-- ============================================================

CREATE TABLE tipo_cliente (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE   -- 'Retail', 'Mayorista'
);

CREATE TABLE tipo_venta (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE   -- 'Contado', 'Crédito'
);

CREATE TABLE producto (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL UNIQUE  -- 'Ropero', 'Velador', 'Cómoda', 'Comodín'
);

CREATE TABLE destino_produccion (
    id          SERIAL PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL UNIQUE  -- 'Stock + pedidos', 'Mayoristas', etc.
);

CREATE TABLE unidad_medida (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE   -- 'planchas', 'caja', 'rollos', 'unidades', 'pares'
);

CREATE TABLE categoria_gasto (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL UNIQUE
);

-- ============================================================
--  TABLAS TRANSACCIONALES
-- ============================================================

-- ── Ventas ──────────────────────────────────────────────────
CREATE TABLE venta (
    id                  SERIAL PRIMARY KEY,
    fecha               DATE           NOT NULL,
    tipo_cliente_id     INT            NOT NULL REFERENCES tipo_cliente(id),
    producto_id         INT            NOT NULL REFERENCES producto(id),
    cantidad            INT            NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMERIC(10,2)  NOT NULL CHECK (precio_unitario >= 0),
    total_venta         NUMERIC(12,2)  NOT NULL CHECK (total_venta >= 0),
    tipo_venta_id       INT            NOT NULL REFERENCES tipo_venta(id),
    created_at          TIMESTAMPTZ    DEFAULT NOW()
);

-- ── Producción ──────────────────────────────────────────────
CREATE TABLE produccion (
    id                      SERIAL PRIMARY KEY,
    fecha_produccion        DATE           NOT NULL,
    producto_id             INT            NOT NULL REFERENCES producto(id),
    cantidad_producida      INT            NOT NULL CHECK (cantidad_producida > 0),
    costo_materia_prima     NUMERIC(10,2)  NOT NULL CHECK (costo_materia_prima >= 0),
    mano_de_obra            NUMERIC(10,2)  NOT NULL CHECK (mano_de_obra >= 0),
    costo_total             NUMERIC(10,2)  NOT NULL CHECK (costo_total >= 0),
    destino_id              INT            NOT NULL REFERENCES destino_produccion(id),
    created_at              TIMESTAMPTZ    DEFAULT NOW()
);

-- ── Inventario (compras de materiales) ──────────────────────
CREATE TABLE inventario (
    id                  SERIAL PRIMARY KEY,
    fecha               DATE           NOT NULL,
    material            VARCHAR(150)   NOT NULL,
    cantidad            NUMERIC(10,2)  NOT NULL CHECK (cantidad > 0),
    unidad_id           INT            NOT NULL REFERENCES unidad_medida(id),
    precio_unitario     NUMERIC(10,2)  NOT NULL CHECK (precio_unitario >= 0),
    total_compra        NUMERIC(12,2)  NOT NULL CHECK (total_compra >= 0),
    notas               TEXT,
    created_at          TIMESTAMPTZ    DEFAULT NOW()
);

-- ── Gastos del mes ──────────────────────────────────────────
CREATE TABLE gasto_mes (
    id                  SERIAL PRIMARY KEY,
    categoria_id        INT            NOT NULL REFERENCES categoria_gasto(id),
    monto               NUMERIC(12,2)  NOT NULL CHECK (monto >= 0),
    detalle             TEXT,
    periodo             DATE,          -- primer día del mes al que corresponde
    created_at          TIMESTAMPTZ    DEFAULT NOW()
);

-- ============================================================
--  ÍNDICES
-- ============================================================
CREATE INDEX idx_venta_fecha        ON venta(fecha);
CREATE INDEX idx_venta_producto     ON venta(producto_id);
CREATE INDEX idx_produccion_fecha   ON produccion(fecha_produccion);
CREATE INDEX idx_inventario_fecha   ON inventario(fecha);
CREATE INDEX idx_gasto_mes_periodo  ON gasto_mes(periodo);

-- ============================================================
--  DATOS MAESTROS
-- ============================================================

INSERT INTO tipo_cliente (nombre) VALUES
    ('Retail'),
    ('Mayorista');

INSERT INTO tipo_venta (nombre) VALUES
    ('Contado'),
    ('Crédito');

INSERT INTO producto (nombre) VALUES
    ('Ropero'),
    ('Velador'),
    ('Cómoda'),
    ('Comodín');

INSERT INTO destino_produccion (descripcion) VALUES
    ('Stock + pedidos'),
    ('Mayoristas'),
    ('Stock'),
    ('Retail'),
    ('Pedidos finales');

INSERT INTO unidad_medida (nombre) VALUES
    ('planchas'),
    ('caja'),
    ('rollos'),
    ('unidades'),
    ('pares');

INSERT INTO categoria_gasto (nombre) VALUES
    ('Mano de Obra (eventual)'),
    ('Compra Melamina y accesorios'),
    ('Alquiler local + servicios'),
    ('Transporte y delivery'),
    ('Otros (herramientas, etc.)');

-- ============================================================
--  DATOS TRANSACCIONALES — VENTAS (hoja: venta)
-- ============================================================

INSERT INTO venta (fecha, tipo_cliente_id, producto_id, cantidad, precio_unitario, total_venta, tipo_venta_id)
SELECT
    v.fecha,
    tc.id,
    p.id,
    v.cantidad,
    v.precio_unitario,
    v.total_venta,
    tv.id
FROM (VALUES
    ('2026-03-02'::date, 'Retail',    'Ropero',  2, 760, 1520, 'Contado'),
    ('2026-03-02'::date, 'Retail',    'Velador', 3,  90,  270, 'Contado'),
    ('2026-03-03'::date, 'Retail',    'Velador', 2,  90,  180, 'Contado'),
    ('2026-03-04'::date, 'Retail',    'Ropero',  3, 760, 2280, 'Contado'),
    ('2026-03-04'::date, 'Retail',    'Comodín', 2, 230,  460, 'Contado'),
    ('2026-03-05'::date, 'Retail',    'Velador', 4,  90,  360, 'Contado'),
    ('2026-03-06'::date, 'Mayorista', 'Ropero',  5, 730, 3650, 'Crédito'),
    ('2026-03-06'::date, 'Retail',    'Cómoda',  1, 480,  480, 'Contado'),
    ('2026-03-08'::date, 'Retail',    'Velador', 5,  90,  450, 'Contado'),
    ('2026-03-09'::date, 'Retail',    'Ropero',  1, 760,  760, 'Contado'),
    ('2026-03-09'::date, 'Retail',    'Ropero',  3, 760, 2280, 'Contado'),
    ('2026-03-09'::date, 'Retail',    'Comodín', 2, 230,  460, 'Contado'),
    ('2026-03-11'::date, 'Retail',    'Velador', 6,  90,  540, 'Contado'),
    ('2026-03-11'::date, 'Retail',    'Cómoda',  2, 480,  960, 'Contado'),
    ('2026-03-12'::date, 'Retail',    'Ropero',  1, 760,  760, 'Contado'),
    ('2026-03-13'::date, 'Retail',    'Velador', 4,  90,  360, 'Contado'),
    ('2026-03-14'::date, 'Mayorista', 'Ropero',  6, 740, 4440, 'Crédito'),
    ('2026-03-15'::date, 'Retail',    'Cómoda',  3, 480, 1440, 'Contado'),
    ('2026-03-16'::date, 'Retail',    'Velador', 7,  90,  630, 'Contado'),
    ('2026-03-17'::date, 'Retail',    'Ropero',  3, 760, 2280, 'Contado'),
    ('2026-03-18'::date, 'Retail',    'Comodín', 3, 230,  690, 'Contado'),
    ('2026-03-19'::date, 'Retail',    'Velador', 5,  90,  450, 'Contado'),
    ('2026-03-20'::date, 'Retail',    'Ropero',  2, 760, 1520, 'Contado'),
    ('2026-03-21'::date, 'Retail',    'Velador', 3,  90,  270, 'Contado'),
    ('2026-03-23'::date, 'Mayorista', 'Ropero',  8, 730, 5840, 'Contado'),
    ('2026-03-24'::date, 'Retail',    'Cómoda',  4, 480, 1920, 'Contado'),
    ('2026-03-25'::date, 'Retail',    'Velador', 6,  90,  540, 'Contado'),
    ('2026-03-26'::date, 'Retail',    'Ropero',  1, 760,  760, 'Contado'),
    ('2026-03-27'::date, 'Retail',    'Comodín', 3, 230,  690, 'Contado'),
    ('2026-03-28'::date, 'Retail',    'Velador', 5,  90,  450, 'Contado'),
    ('2026-03-30'::date, 'Retail',    'Ropero',  4, 760, 3040, 'Contado')
) AS v(fecha, tipo_cliente, producto, cantidad, precio_unitario, total_venta, tipo_venta)
JOIN tipo_cliente tc ON tc.nombre = v.tipo_cliente
JOIN producto     p  ON p.nombre  = v.producto
JOIN tipo_venta   tv ON tv.nombre = v.tipo_venta;

-- ============================================================
--  DATOS TRANSACCIONALES — PRODUCCIÓN (hoja: producion mes)
-- ============================================================

INSERT INTO produccion (fecha_produccion, producto_id, cantidad_producida, costo_materia_prima, mano_de_obra, costo_total, destino_id)
SELECT
    pr.fecha,
    p.id,
    pr.cantidad,
    pr.costo_mp,
    pr.mano_obra,
    pr.costo_total,
    d.id
FROM (VALUES
    ('2026-03-02'::date, 'Ropero',  12, 5.76, 1.68, 7.44, 'Stock + pedidos'),
    ('2026-03-10'::date, 'Ropero',  15, 6.75, 2.10, 8.85, 'Mayoristas'),
    ('2026-03-15'::date, 'Cómoda',  18, 4.32, 1.44, 5.76, 'Stock'),
    ('2026-03-20'::date, 'Velador', 35, 2.45, 1.05, 3.50, 'Retail'),
    ('2026-03-25'::date, 'Comodín', 15, 1.35, 0.75, 2.10, 'Stock'),
    ('2026-03-28'::date, 'Ropero',  10, 4.80, 1.40, 6.20, 'Pedidos finales')
) AS pr(fecha, producto, cantidad, costo_mp, mano_obra, costo_total, destino)
JOIN producto            p ON p.nombre      = pr.producto
JOIN destino_produccion  d ON d.descripcion = pr.destino;

-- ============================================================
--  DATOS TRANSACCIONALES — INVENTARIO (hoja: inventario)
-- ============================================================

INSERT INTO inventario (fecha, material, cantidad, unidad_id, precio_unitario, total_compra, notas)
SELECT
    i.fecha,
    i.material,
    i.cantidad,
    u.id,
    i.precio_unit,
    i.total_compra,
    NULLIF(i.notas, '-')
FROM (VALUES
    ('2026-03-01'::date, 'Melamina Blanco 18mm',  8,  'planchas',  150.0, 1200, 'Compra inicial'),
    ('2026-03-03'::date, 'Mapresa (fondo)',         5,  'planchas',  100.0,  500, '-'),
    ('2026-03-05'::date, 'Tornillos (caja 1000)',   1,  'caja',       80.0,   80, '-'),
    ('2026-03-07'::date, 'Melamina Color 18mm',     6,  'planchas',  180.0, 1080, '-'),
    ('2026-03-10'::date, 'Tapacanto (rollo)',        3,  'rollos',     35.0,  105, '-'),
    ('2026-03-12'::date, 'Jaladores',              150,  'unidades',    1.0,  150, '-'),
    ('2026-03-14'::date, 'Correderas (30cm)',       40,  'pares',      20.0,  800, '-'),
    ('2026-03-18'::date, 'Melamina Blanco 18mm',    7,  'planchas',  152.0, 1064, 'Compra adicional'),
    ('2026-03-20'::date, 'Bisagras (caja 100)',      1,  'caja',       90.0,   90, '-'),
    ('2026-03-23'::date, 'Mapresa',                  4,  'planchas',  100.0,  400, '-'),
    ('2026-03-25'::date, 'Melamina Color 18mm',      5,  'planchas',  175.0,  875, 'Compra urgente'),
    ('2026-03-28'::date, 'Patitas',                200,  'unidades',    0.4,   80, '-'),
    ('2026-03-30'::date, 'Tornillos (caja)',          1,  'caja',       80.0,   80, 'Reposición')
) AS i(fecha, material, cantidad, unidad, precio_unit, total_compra, notas)
JOIN unidad_medida u ON u.nombre = i.unidad;

-- ============================================================
--  DATOS TRANSACCIONALES — GASTOS (hoja: gastos mes)
-- ============================================================

INSERT INTO gasto_mes (categoria_id, monto, detalle, periodo)
SELECT
    cg.id,
    g.monto,
    NULLIF(g.detalle, ''),
    '2026-03-01'::date
FROM (VALUES
    ('Mano de Obra (eventual)',          6800,  '3 trabajadores'),
    ('Compra Melamina y accesorios',    12740,  'Principal gasto variable'),
    ('Alquiler local + servicios',       2800,  'Fijo'),
    ('Transporte y delivery',             980,  NULL),
    ('Otros (herramientas, etc.)',         650,  NULL)
) AS g(categoria, monto, detalle)
JOIN categoria_gasto cg ON cg.nombre = g.categoria;

-- ============================================================
--  VISTAS ANALÍTICAS DE UTILIDAD
-- ============================================================

-- Resumen de ventas por producto y tipo de cliente
CREATE OR REPLACE VIEW v_ventas_resumen AS
SELECT
    p.nombre                     AS producto,
    tc.nombre                    AS tipo_cliente,
    tv.nombre                    AS tipo_venta,
    COUNT(*)                     AS num_transacciones,
    SUM(v.cantidad)              AS unidades_vendidas,
    SUM(v.total_venta)           AS total_ingresos
FROM venta v
JOIN producto     p  ON p.id  = v.producto_id
JOIN tipo_cliente tc ON tc.id = v.tipo_cliente_id
JOIN tipo_venta   tv ON tv.id = v.tipo_venta_id
GROUP BY p.nombre, tc.nombre, tv.nombre;

-- Costo unitario vs precio de venta por producto
CREATE OR REPLACE VIEW v_margen_producto AS
SELECT
    p.nombre                                    AS producto,
    ROUND(AVG(pr.costo_total), 2)               AS costo_unitario_promedio,
    ROUND(AVG(v.precio_unitario), 2)            AS precio_venta_promedio,
    ROUND(AVG(v.precio_unitario)
          - AVG(pr.costo_total), 2)             AS margen_bruto_unitario
FROM producto p
LEFT JOIN produccion pr ON pr.producto_id = p.id
LEFT JOIN venta       v  ON v.producto_id  = p.id
GROUP BY p.nombre;

-- Compras de inventario por material
CREATE OR REPLACE VIEW v_inventario_resumen AS
SELECT
    material,
    u.nombre                     AS unidad,
    SUM(i.cantidad)              AS cantidad_total,
    SUM(i.total_compra)          AS gasto_total
FROM inventario i
JOIN unidad_medida u ON u.id = i.unidad_id
GROUP BY material, u.nombre
ORDER BY gasto_total DESC;

-- ============================================================
--  VERIFICACIÓN RÁPIDA
-- ============================================================
-- SELECT 'ventas'     AS tabla, COUNT(*) FROM venta       UNION ALL
-- SELECT 'produccion',          COUNT(*) FROM produccion  UNION ALL
-- SELECT 'inventario',          COUNT(*) FROM inventario  UNION ALL
-- SELECT 'gastos',              COUNT(*) FROM gasto_mes;

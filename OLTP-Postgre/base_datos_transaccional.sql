-- ============================================================
--  BASE DE DATOS TRANSACCIONAL - MUEBLERIA / CARPINTERÍA
--  Moneda: Soles peruanos (S/)
-- ============================================================

SET search_path TO transaccional, public;

-- ============================================================
--  TABLAS DE CATÁLOGO / MAESTRAS
-- ============================================================

CREATE TABLE IF NOT EXISTS tipo_cliente (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_venta (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS producto (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS destino_produccion (
    id          SERIAL PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS unidad_medida (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS categoria_gasto (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL UNIQUE
);

-- ============================================================
--  TABLAS TRANSACCIONALES
-- ============================================================

CREATE TABLE IF NOT EXISTS venta (
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

CREATE TABLE IF NOT EXISTS produccion (
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

CREATE TABLE IF NOT EXISTS inventario (
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

CREATE TABLE IF NOT EXISTS gasto_mes (
    id                  SERIAL PRIMARY KEY,
    categoria_id        INT            NOT NULL REFERENCES categoria_gasto(id),
    monto               NUMERIC(12,2)  NOT NULL CHECK (monto >= 0),
    detalle             TEXT,
    periodo             DATE,
    created_at          TIMESTAMPTZ    DEFAULT NOW()
);

-- ============================================================
--  ÍNDICES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_venta_fecha        ON venta(fecha);
CREATE INDEX IF NOT EXISTS idx_venta_producto     ON venta(producto_id);
CREATE INDEX IF NOT EXISTS idx_produccion_fecha   ON produccion(fecha_produccion);
CREATE INDEX IF NOT EXISTS idx_inventario_fecha   ON inventario(fecha);
CREATE INDEX IF NOT EXISTS idx_gasto_mes_periodo  ON gasto_mes(periodo);

-- ============================================================
--  DATOS MAESTROS
-- ============================================================

INSERT INTO tipo_cliente (nombre) VALUES ('Retail'), ('Mayorista')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO tipo_venta (nombre) VALUES ('Contado'), ('Crédito')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO producto (nombre) VALUES ('Ropero'), ('Velador'), ('Cómoda'), ('Comodín')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO destino_produccion (descripcion) VALUES
    ('Stock + pedidos'), ('Mayoristas'), ('Stock'), ('Retail'), ('Pedidos finales')
ON CONFLICT (descripcion) DO NOTHING;

INSERT INTO unidad_medida (nombre) VALUES
    ('planchas'), ('caja'), ('rollos'), ('unidades'), ('pares')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_gasto (nombre) VALUES
    ('Mano de Obra (eventual)'),
    ('Compra Melamina y accesorios'),
    ('Alquiler local + servicios'),
    ('Transporte y delivery'),
    ('Otros (herramientas, etc.)')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================================
--  DATOS TRANSACCIONALES — VENTAS
-- ============================================================

INSERT INTO venta (fecha, tipo_cliente_id, producto_id, cantidad, precio_unitario, total_venta, tipo_venta_id)
SELECT v.fecha, tc.id, p.id, v.cantidad, v.precio_unitario, v.total_venta, tv.id
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
--  DATOS TRANSACCIONALES — PRODUCCIÓN
-- ============================================================

INSERT INTO produccion (fecha_produccion, producto_id, cantidad_producida, costo_materia_prima, mano_de_obra, costo_total, destino_id)
SELECT pr.fecha, p.id, pr.cantidad, pr.costo_mp, pr.mano_obra, pr.costo_total, d.id
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
--  DATOS TRANSACCIONALES — INVENTARIO
-- ============================================================

INSERT INTO inventario (fecha, material, cantidad, unidad_id, precio_unitario, total_compra, notas)
SELECT i.fecha, i.material, i.cantidad, u.id, i.precio_unit, i.total_compra, NULLIF(i.notas, '-')
FROM (VALUES
    ('2026-03-01'::date, 'Melamina Blanco 18mm',  8,   'planchas',  150.0, 1200, 'Compra inicial'),
    ('2026-03-03'::date, 'Mapresa (fondo)',         5,   'planchas',  100.0,  500, '-'),
    ('2026-03-05'::date, 'Tornillos (caja 1000)',   1,   'caja',       80.0,   80, '-'),
    ('2026-03-07'::date, 'Melamina Color 18mm',     6,   'planchas',  180.0, 1080, '-'),
    ('2026-03-10'::date, 'Tapacanto (rollo)',        3,   'rollos',     35.0,  105, '-'),
    ('2026-03-12'::date, 'Jaladores',              150,   'unidades',    1.0,  150, '-'),
    ('2026-03-14'::date, 'Correderas (30cm)',       40,   'pares',      20.0,  800, '-'),
    ('2026-03-18'::date, 'Melamina Blanco 18mm',    7,   'planchas',  152.0, 1064, 'Compra adicional'),
    ('2026-03-20'::date, 'Bisagras (caja 100)',      1,   'caja',       90.0,   90, '-'),
    ('2026-03-23'::date, 'Mapresa',                  4,   'planchas',  100.0,  400, '-'),
    ('2026-03-25'::date, 'Melamina Color 18mm',      5,   'planchas',  175.0,  875, 'Compra urgente'),
    ('2026-03-28'::date, 'Patitas',                200,   'unidades',    0.4,   80, '-'),
    ('2026-03-30'::date, 'Tornillos (caja)',          1,   'caja',       80.0,   80, 'Reposición')
) AS i(fecha, material, cantidad, unidad, precio_unit, total_compra, notas)
JOIN unidad_medida u ON u.nombre = i.unidad;

-- ============================================================
--  DATOS TRANSACCIONALES — GASTOS
-- ============================================================

INSERT INTO gasto_mes (categoria_id, monto, detalle, periodo)
SELECT cg.id, g.monto, NULLIF(g.detalle, ''), '2026-03-01'::date
FROM (VALUES
    ('Mano de Obra (eventual)',          6800, '3 trabajadores'),
    ('Compra Melamina y accesorios',    12740, 'Principal gasto variable'),
    ('Alquiler local + servicios',       2800, 'Fijo'),
    ('Transporte y delivery',             980, ''),
    ('Otros (herramientas, etc.)',         650, '')
) AS g(categoria, monto, detalle)
JOIN categoria_gasto cg ON cg.nombre = g.categoria;

-- ============================================================
--  BASE DE DATOS TRANSACCIONAL - MUEBLERIA / CARPINTERÍA
--  Moneda: Soles peruanos (S/)
--  VERSIÓN COMPLETA CON MEJORAS
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
    nombre      VARCHAR(100) NOT NULL UNIQUE,
    costo_estandar NUMERIC(10,2) DEFAULT 0,
    precio_venta_retail NUMERIC(10,2),
    precio_venta_mayorista NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS destino_produccion (
    id          SERIAL PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS unidad_medida (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    abreviatura VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS categoria_gasto (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL UNIQUE,
    tipo        VARCHAR(20) DEFAULT 'fijo' -- fijo, variable
);

CREATE TABLE IF NOT EXISTS proveedor (
    id          SERIAL PRIMARY KEY,
    ruc         VARCHAR(20) UNIQUE,
    nombre      VARCHAR(100) NOT NULL,
    contacto    VARCHAR(100),
    telefono    VARCHAR(20),
    email       VARCHAR(100),
    direccion   TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS material (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL UNIQUE,
    unidad_medida_id INT NOT NULL REFERENCES unidad_medida(id),
    stock_minimo    NUMERIC(10,2) DEFAULT 0,
    stock_actual    NUMERIC(10,2) DEFAULT 0,
    proveedor_preferido_id INT REFERENCES proveedor(id)
);

CREATE TABLE IF NOT EXISTS cliente (
    id              SERIAL PRIMARY KEY,
    tipo_cliente_id INT NOT NULL REFERENCES tipo_cliente(id),
    documento       VARCHAR(20) UNIQUE,
    nombre          VARCHAR(100) NOT NULL,
    razon_social    VARCHAR(150),
    direccion       TEXT,
    telefono        VARCHAR(20),
    email           VARCHAR(100),
    limite_credito  NUMERIC(12,2) DEFAULT 0,
    saldo_pendiente NUMERIC(12,2) DEFAULT 0,
    estado          VARCHAR(20) DEFAULT 'activo', -- activo, inactivo, moroso
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS usuario (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    rol         VARCHAR(50) DEFAULT 'vendedor', -- admin, vendedor, produccion, contador
    activo      BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
--  TABLAS TRANSACCIONALES
-- ============================================================

CREATE TABLE IF NOT EXISTS venta (
    id                  SERIAL PRIMARY KEY,
    fecha               DATE NOT NULL,
    cliente_id          INT NOT NULL REFERENCES cliente(id),
    tipo_cliente_id     INT NOT NULL REFERENCES tipo_cliente(id),
    producto_id         INT NOT NULL REFERENCES producto(id),
    cantidad            INT NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    total_venta         NUMERIC(12,2) NOT NULL CHECK (total_venta >= 0),
    tipo_venta_id       INT NOT NULL REFERENCES tipo_venta(id),
    usuario_id          INT REFERENCES usuario(id),
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cuentas_cobrar (
    id                  SERIAL PRIMARY KEY,
    venta_id            INT NOT NULL REFERENCES venta(id),
    fecha_emision       DATE NOT NULL,
    fecha_vencimiento   DATE NOT NULL,
    monto_total         NUMERIC(12,2) NOT NULL CHECK (monto_total > 0),
    saldo_pendiente     NUMERIC(12,2) NOT NULL CHECK (saldo_pendiente >= 0),
    estado              VARCHAR(20) DEFAULT 'pendiente', -- pendiente, parcial, pagado, vencido
    numero_cuota        INT DEFAULT 1,
    total_cuotas        INT DEFAULT 1,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pago_cliente (
    id                  SERIAL PRIMARY KEY,
    cuenta_cobrar_id    INT NOT NULL REFERENCES cuentas_cobrar(id),
    fecha               DATE NOT NULL,
    monto               NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    metodo_pago         VARCHAR(50), -- efectivo, transferencia, tarjeta, cheque
    referencia          VARCHAR(100),
    usuario_id          INT REFERENCES usuario(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orden_produccion (
    id                  SERIAL PRIMARY KEY,
    numero_orden        VARCHAR(50) UNIQUE,
    fecha_inicio        DATE NOT NULL,
    fecha_fin_estimada  DATE,
    fecha_fin_real      DATE,
    producto_id         INT NOT NULL REFERENCES producto(id),
    cantidad_ordenada   INT NOT NULL CHECK (cantidad_ordenada > 0),
    cantidad_producida  INT DEFAULT 0,
    estado              VARCHAR(30) DEFAULT 'planificada', -- planificada, en_proceso, completada, cancelada
    responsable_id      INT REFERENCES usuario(id),
    costo_materia_prima_estimado NUMERIC(10,2),
    costo_mano_obra_estimado NUMERIC(10,2),
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS produccion (
    id                      SERIAL PRIMARY KEY,
    orden_produccion_id     INT NOT NULL REFERENCES orden_produccion(id),
    fecha_produccion        DATE NOT NULL,
    producto_id             INT NOT NULL REFERENCES producto(id),
    cantidad_producida      INT NOT NULL CHECK (cantidad_producida > 0),
    costo_materia_prima     NUMERIC(10,2) NOT NULL CHECK (costo_materia_prima >= 0),
    mano_de_obra            NUMERIC(10,2) NOT NULL CHECK (mano_de_obra >= 0),
    costo_total             NUMERIC(10,2) NOT NULL CHECK (costo_total >= 0),
    destino_id              INT NOT NULL REFERENCES destino_produccion(id),
    notas                   TEXT,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS consumo_material (
    id                  SERIAL PRIMARY KEY,
    produccion_id       INT NOT NULL REFERENCES produccion(id),
    material_id         INT NOT NULL REFERENCES material(id),
    cantidad_consumida  NUMERIC(10,2) NOT NULL CHECK (cantidad_consumida > 0),
    costo_unitario      NUMERIC(10,2) NOT NULL,
    costo_total         NUMERIC(12,2) NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS compra_material (
    id                  SERIAL PRIMARY KEY,
    fecha               DATE NOT NULL,
    proveedor_id        INT REFERENCES proveedor(id),
    material_id         INT NOT NULL REFERENCES material(id),
    cantidad            NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    total_compra        NUMERIC(12,2) NOT NULL CHECK (total_compra >= 0),
    factura_numero      VARCHAR(50),
    notas               TEXT,
    usuario_id          INT REFERENCES usuario(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventario_material (
    id                  SERIAL PRIMARY KEY,
    fecha               DATE NOT NULL,
    material_id         INT NOT NULL REFERENCES material(id),
    tipo_movimiento     VARCHAR(20) NOT NULL, -- entrada, salida, ajuste
    cantidad            NUMERIC(10,2) NOT NULL,
    precio_unitario     NUMERIC(10,2),
    total_valor         NUMERIC(12,2),
    referencia_id       INT, -- ID de compra_material o consumo_material
    referencia_tabla    VARCHAR(50), -- compra_material, consumo_material
    notas               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_producto_terminado (
    producto_id         INT PRIMARY KEY REFERENCES producto(id),
    cantidad_disponible INT NOT NULL DEFAULT 0,
    cantidad_reservada  INT NOT NULL DEFAULT 0,
    punto_reorden       INT DEFAULT 5,
    ultima_actualizacion TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devolucion_venta (
    id                  SERIAL PRIMARY KEY,
    venta_id            INT NOT NULL REFERENCES venta(id),
    fecha               DATE NOT NULL,
    cantidad            INT NOT NULL CHECK (cantidad > 0),
    motivo              TEXT,
    monto_reembolsado   NUMERIC(12,2),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gasto (
    id                  SERIAL PRIMARY KEY,
    fecha               DATE NOT NULL,
    categoria_id        INT NOT NULL REFERENCES categoria_gasto(id),
    monto               NUMERIC(12,2) NOT NULL CHECK (monto >= 0),
    detalle             TEXT,
    comprobante         VARCHAR(50),
    usuario_id          INT REFERENCES usuario(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
--  TABLAS DE CONTROL Y AUDITORÍA
-- ============================================================

CREATE TABLE IF NOT EXISTS caja (
    id                  SERIAL PRIMARY KEY,
    fecha_apertura      DATE NOT NULL,
    fecha_cierre        DATE,
    saldo_inicial       NUMERIC(12,2) NOT NULL,
    saldo_final         NUMERIC(12,2),
    total_ingresos      NUMERIC(12,2) DEFAULT 0,
    total_egresos       NUMERIC(12,2) DEFAULT 0,
    estado              VARCHAR(20) DEFAULT 'abierta',
    usuario_apertura_id INT REFERENCES usuario(id),
    usuario_cierre_id   INT REFERENCES usuario(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS movimiento_caja (
    id                  SERIAL PRIMARY KEY,
    caja_id             INT NOT NULL REFERENCES caja(id),
    fecha               TIMESTAMPTZ DEFAULT NOW(),
    tipo                VARCHAR(20) NOT NULL, -- ingreso, egreso
    concepto            VARCHAR(200) NOT NULL,
    monto               NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    referencia_id       INT, -- ID de venta, pago_cliente, gasto, etc.
    referencia_tabla    VARCHAR(50),
    usuario_id          INT REFERENCES usuario(id),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
--  ÍNDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_venta_fecha ON venta(fecha);
CREATE INDEX IF NOT EXISTS idx_venta_cliente ON venta(cliente_id);
CREATE INDEX IF NOT EXISTS idx_venta_producto ON venta(producto_id);
CREATE INDEX IF NOT EXISTS idx_venta_tipo_venta ON venta(tipo_venta_id);

CREATE INDEX IF NOT EXISTS idx_cuentas_cobrar_cliente ON cuentas_cobrar(venta_id);
CREATE INDEX IF NOT EXISTS idx_cuentas_cobrar_estado ON cuentas_cobrar(estado);
CREATE INDEX IF NOT EXISTS idx_cuentas_cobrar_vencimiento ON cuentas_cobrar(fecha_vencimiento);

CREATE INDEX IF NOT EXISTS idx_pago_cliente_cuenta ON pago_cliente(cuenta_cobrar_id);
CREATE INDEX IF NOT EXISTS idx_pago_cliente_fecha ON pago_cliente(fecha);

CREATE INDEX IF NOT EXISTS idx_orden_produccion_estado ON orden_produccion(estado);
CREATE INDEX IF NOT EXISTS idx_orden_produccion_fechas ON orden_produccion(fecha_inicio, fecha_fin_estimada);

CREATE INDEX IF NOT EXISTS idx_produccion_orden ON produccion(orden_produccion_id);
CREATE INDEX IF NOT EXISTS idx_produccion_fecha ON produccion(fecha_produccion);

CREATE INDEX IF NOT EXISTS idx_consumo_material_produccion ON consumo_material(produccion_id);
CREATE INDEX IF NOT EXISTS idx_consumo_material_material ON consumo_material(material_id);

CREATE INDEX IF NOT EXISTS idx_compra_material_fecha ON compra_material(fecha);
CREATE INDEX IF NOT EXISTS idx_compra_material_proveedor ON compra_material(proveedor_id);

CREATE INDEX IF NOT EXISTS idx_inventario_material_fecha ON inventario_material(fecha);
CREATE INDEX IF NOT EXISTS idx_inventario_material_material ON inventario_material(material_id);
CREATE INDEX IF NOT EXISTS idx_inventario_material_tipo ON inventario_material(tipo_movimiento);

CREATE INDEX IF NOT EXISTS idx_gasto_fecha ON gasto(fecha);
CREATE INDEX IF NOT EXISTS idx_gasto_categoria ON gasto(categoria_id);

CREATE INDEX IF NOT EXISTS idx_movimiento_caja_fecha ON movimiento_caja(fecha);
CREATE INDEX IF NOT EXISTS idx_movimiento_caja_caja ON movimiento_caja(caja_id);

-- ============================================================
--  FUNCIONES Y TRIGGERS
-- ============================================================

-- Actualizar stock de producto terminado después de producción
CREATE OR REPLACE FUNCTION actualizar_stock_produccion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO stock_producto_terminado (producto_id, cantidad_disponible, ultima_actualizacion)
    VALUES (NEW.producto_id, NEW.cantidad_producida, NOW())
    ON CONFLICT (producto_id) 
    DO UPDATE SET 
        cantidad_disponible = stock_producto_terminado.cantidad_disponible + NEW.cantidad_producida,
        ultima_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_stock_produccion
AFTER INSERT ON produccion
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_produccion();

-- Actualizar stock de producto terminado después de venta
CREATE OR REPLACE FUNCTION actualizar_stock_venta()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE stock_producto_terminado
    SET cantidad_disponible = cantidad_disponible - NEW.cantidad,
        ultima_actualizacion = NOW()
    WHERE producto_id = NEW.producto_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_stock_venta
AFTER INSERT ON venta
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_venta();

-- Actualizar stock de material después de compra
CREATE OR REPLACE FUNCTION actualizar_stock_material_compra()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE material
    SET stock_actual = stock_actual + NEW.cantidad
    WHERE id = NEW.material_id;
    
    INSERT INTO inventario_material (fecha, material_id, tipo_movimiento, cantidad, precio_unitario, total_valor, referencia_id, referencia_tabla)
    VALUES (NEW.fecha, NEW.material_id, 'entrada', NEW.cantidad, NEW.precio_unitario, NEW.total_compra, NEW.id, 'compra_material');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_stock_compra
AFTER INSERT ON compra_material
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_material_compra();

-- Actualizar stock de material después de consumo
CREATE OR REPLACE FUNCTION actualizar_stock_material_consumo()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE material
    SET stock_actual = stock_actual - NEW.cantidad_consumida
    WHERE id = NEW.material_id;
    
    INSERT INTO inventario_material (fecha, material_id, tipo_movimiento, cantidad, precio_unitario, total_valor, referencia_id, referencia_tabla)
    VALUES (CURRENT_DATE, NEW.material_id, 'salida', NEW.cantidad_consumida, NEW.costo_unitario, NEW.costo_total, NEW.id, 'consumo_material');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_stock_consumo
AFTER INSERT ON consumo_material
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_material_consumo();

-- Actualizar saldo pendiente del cliente después de pago
CREATE OR REPLACE FUNCTION actualizar_saldo_cliente_pago()
RETURNS TRIGGER AS $$
DECLARE
    v_cliente_id INTEGER;
    v_venta_id INTEGER;
BEGIN
    SELECT venta_id INTO v_venta_id FROM cuentas_cobrar WHERE id = NEW.cuenta_cobrar_id;
    SELECT cliente_id INTO v_cliente_id FROM venta WHERE id = v_venta_id;
    
    UPDATE cuentas_cobrar
    SET saldo_pendiente = saldo_pendiente - NEW.monto,
        estado = CASE 
            WHEN saldo_pendiente - NEW.monto <= 0 THEN 'pagado'
            WHEN saldo_pendiente - NEW.monto < monto_total THEN 'parcial'
            ELSE estado
        END
    WHERE id = NEW.cuenta_cobrar_id;
    
    UPDATE cliente
    SET saldo_pendiente = saldo_pendiente - NEW.monto,
        updated_at = NOW()
    WHERE id = v_cliente_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_saldo_cliente
AFTER INSERT ON pago_cliente
FOR EACH ROW
EXECUTE FUNCTION actualizar_saldo_cliente_pago();

-- ============================================================
--  DATOS MAESTROS
-- ============================================================

INSERT INTO tipo_cliente (nombre) VALUES ('Retail'), ('Mayorista')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO tipo_venta (nombre) VALUES ('Contado'), ('Crédito')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO producto (nombre, costo_estandar, precio_venta_retail, precio_venta_mayorista) VALUES
    ('Ropero', 125.00, 760.00, 730.00),
    ('Velador', 28.00, 90.00, 85.00),
    ('Cómoda', 85.00, 480.00, 460.00),
    ('Comodín', 35.00, 230.00, 220.00)
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO destino_produccion (descripcion) VALUES
    ('Stock + pedidos'), ('Mayoristas'), ('Stock'), ('Retail'), ('Pedidos finales')
ON CONFLICT (descripcion) DO NOTHING;

INSERT INTO unidad_medida (nombre, abreviatura) VALUES
    ('planchas', 'pl'),
    ('caja', 'cj'),
    ('rollos', 'rl'),
    ('unidades', 'und'),
    ('pares', 'pr')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_gasto (nombre, tipo) VALUES
    ('Mano de Obra (eventual)', 'variable'),
    ('Compra Melamina y accesorios', 'variable'),
    ('Alquiler local + servicios', 'fijo'),
    ('Transporte y delivery', 'variable'),
    ('Otros (herramientas, etc.)', 'variable')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO proveedor (ruc, nombre, contacto, telefono) VALUES
    ('20123456789', 'Melaminas del Perú', 'Carlos López', '987654321'),
    ('20567890123', 'Ferretodo S.A.C.', 'María García', '976543210'),
    ('20678901234', 'Maderas Noble', 'Juan Pérez', '965432187')
ON CONFLICT (ruc) DO NOTHING;

INSERT INTO material (nombre, unidad_medida_id, stock_minimo, proveedor_preferido_id) VALUES
    ('Melamina Blanco 18mm', (SELECT id FROM unidad_medida WHERE nombre = 'planchas'), 5, (SELECT id FROM proveedor WHERE ruc = '20123456789')),
    ('Mapresa (fondo)', (SELECT id FROM unidad_medida WHERE nombre = 'planchas'), 3, (SELECT id FROM proveedor WHERE ruc = '20567890123')),
    ('Tornillos (caja 1000)', (SELECT id FROM unidad_medida WHERE nombre = 'caja'), 2, (SELECT id FROM proveedor WHERE ruc = '20567890123')),
    ('Melamina Color 18mm', (SELECT id FROM unidad_medida WHERE nombre = 'planchas'), 4, (SELECT id FROM proveedor WHERE ruc = '20123456789')),
    ('Tapacanto (rollo)', (SELECT id FROM unidad_medida WHERE nombre = 'rollos'), 2, (SELECT id FROM proveedor WHERE ruc = '20678901234')),
    ('Jaladores', (SELECT id FROM unidad_medida WHERE nombre = 'unidades'), 50, (SELECT id FROM proveedor WHERE ruc = '20567890123')),
    ('Correderas (30cm)', (SELECT id FROM unidad_medida WHERE nombre = 'pares'), 20, (SELECT id FROM proveedor WHERE ruc = '20678901234')),
    ('Bisagras (caja 100)', (SELECT id FROM unidad_medida WHERE nombre = 'caja'), 1, (SELECT id FROM proveedor WHERE ruc = '20567890123')),
    ('Patitas', (SELECT id FROM unidad_medida WHERE nombre = 'unidades'), 100, (SELECT id FROM proveedor WHERE ruc = '20567890123'))
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO cliente (tipo_cliente_id, documento, nombre, direccion, telefono, limite_credito) VALUES
    ((SELECT id FROM tipo_cliente WHERE nombre = 'Retail'), '12345678', 'Cliente Retail 1', 'Av. Principal 123', '987654321', 0),
    ((SELECT id FROM tipo_cliente WHERE nombre = 'Retail'), '87654321', 'Cliente Retail 2', 'Calle Las Flores 456', '976543210', 0),
    ((SELECT id FROM tipo_cliente WHERE nombre = 'Mayorista'), '20123456789', 'Muebles Mayorista S.A.C.', 'Av. Industrial 789', '965432187', 15000.00),
    ((SELECT id FROM tipo_cliente WHERE nombre = 'Mayorista'), '20567890123', 'Distribuidora El Mueble', 'Calle Comercio 321', '954321876', 10000.00);

INSERT INTO usuario (nombre, email, rol) VALUES
    ('Admin Sistema', 'admin@muebleria.com', 'admin'),
    ('Juan Vendedor', 'juan@muebleria.com', 'vendedor'),
    ('Pedro Producción', 'pedro@muebleria.com', 'produccion'),
    ('Maria Contadora', 'maria@muebleria.com', 'contador');

-- ============================================================
--  DATOS TRANSACCIONALES — VENTAS (Actualizado con clientes)
-- ============================================================

INSERT INTO venta (fecha, cliente_id, tipo_cliente_id, producto_id, cantidad, precio_unitario, total_venta, tipo_venta_id, usuario_id)
SELECT 
    v.fecha, 
    c.id, 
    tc.id, 
    p.id, 
    v.cantidad, 
    v.precio_unitario, 
    v.total_venta, 
    tv.id,
    (SELECT id FROM usuario WHERE email = 'juan@muebleria.com')
FROM (VALUES
    ('2026-03-02'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  2, 760, 1520, 'Contado'),
    ('2026-03-02'::date, 'Cliente Retail 2', 'Retail',    'Velador', 3,  90,  270, 'Contado'),
    ('2026-03-03'::date, 'Cliente Retail 1', 'Retail',    'Velador', 2,  90,  180, 'Contado'),
    ('2026-03-04'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  3, 760, 2280, 'Contado'),
    ('2026-03-04'::date, 'Cliente Retail 2', 'Retail',    'Comodín', 2, 230,  460, 'Contado'),
    ('2026-03-05'::date, 'Cliente Retail 1', 'Retail',    'Velador', 4,  90,  360, 'Contado'),
    ('2026-03-06'::date, 'Muebles Mayorista S.A.C.', 'Mayorista', 'Ropero',  5, 730, 3650, 'Crédito'),
    ('2026-03-06'::date, 'Cliente Retail 1', 'Retail',    'Cómoda',  1, 480,  480, 'Contado'),
    ('2026-03-08'::date, 'Cliente Retail 2', 'Retail',    'Velador', 5,  90,  450, 'Contado'),
    ('2026-03-09'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  1, 760,  760, 'Contado'),
    ('2026-03-09'::date, 'Cliente Retail 2', 'Retail',    'Ropero',  3, 760, 2280, 'Contado'),
    ('2026-03-09'::date, 'Cliente Retail 1', 'Retail',    'Comodín', 2, 230,  460, 'Contado'),
    ('2026-03-11'::date, 'Cliente Retail 1', 'Retail',    'Velador', 6,  90,  540, 'Contado'),
    ('2026-03-11'::date, 'Cliente Retail 2', 'Retail',    'Cómoda',  2, 480,  960, 'Contado'),
    ('2026-03-12'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  1, 760,  760, 'Contado'),
    ('2026-03-13'::date, 'Cliente Retail 2', 'Retail',    'Velador', 4,  90,  360, 'Contado'),
    ('2026-03-14'::date, 'Distribuidora El Mueble', 'Mayorista', 'Ropero',  6, 740, 4440, 'Crédito'),
    ('2026-03-15'::date, 'Cliente Retail 1', 'Retail',    'Cómoda',  3, 480, 1440, 'Contado'),
    ('2026-03-16'::date, 'Cliente Retail 2', 'Retail',    'Velador', 7,  90,  630, 'Contado'),
    ('2026-03-17'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  3, 760, 2280, 'Contado'),
    ('2026-03-18'::date, 'Cliente Retail 2', 'Retail',    'Comodín', 3, 230,  690, 'Contado'),
    ('2026-03-19'::date, 'Cliente Retail 1', 'Retail',    'Velador', 5,  90,  450, 'Contado'),
    ('2026-03-20'::date, 'Cliente Retail 2', 'Retail',    'Ropero',  2, 760, 1520, 'Contado'),
    ('2026-03-21'::date, 'Cliente Retail 1', 'Retail',    'Velador', 3,  90,  270, 'Contado'),
    ('2026-03-23'::date, 'Muebles Mayorista S.A.C.', 'Mayorista', 'Ropero',  8, 730, 5840, 'Contado'),
    ('2026-03-24'::date, 'Cliente Retail 1', 'Retail',    'Cómoda',  4, 480, 1920, 'Contado'),
    ('2026-03-25'::date, 'Cliente Retail 2', 'Retail',    'Velador', 6,  90,  540, 'Contado'),
    ('2026-03-26'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  1, 760,  760, 'Contado'),
    ('2026-03-27'::date, 'Cliente Retail 2', 'Retail',    'Comodín', 3, 230,  690, 'Contado'),
    ('2026-03-28'::date, 'Cliente Retail 1', 'Retail',    'Velador', 5,  90,  450, 'Contado'),
    ('2026-03-30'::date, 'Cliente Retail 1', 'Retail',    'Ropero',  4, 760, 3040, 'Contado')
) AS v(fecha, cliente_nombre, tipo_cliente, producto, cantidad, precio_unitario, total_venta, tipo_venta)
JOIN cliente c ON c.nombre = v.cliente_nombre
JOIN tipo_cliente tc ON tc.nombre = v.tipo_cliente
JOIN producto p ON p.nombre = v.producto
JOIN tipo_venta tv ON tv.nombre = v.tipo_venta;

-- ============================================================
--  DATOS TRANSACCIONALES — CUENTAS POR COBRAR (Para ventas a crédito)
-- ============================================================

INSERT INTO cuentas_cobrar (venta_id, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado)
SELECT 
    v.id,
    v.fecha,
    v.fecha + INTERVAL '15 days',
    v.total_venta,
    v.total_venta,
    'pendiente'
FROM venta v
WHERE v.tipo_venta_id = (SELECT id FROM tipo_venta WHERE nombre = 'Crédito');

-- ============================================================
--  DATOS TRANSACCIONALES — ORDENES DE PRODUCCIÓN
-- ============================================================

INSERT INTO orden_produccion (numero_orden, fecha_inicio, fecha_fin_estimada, producto_id, cantidad_ordenada, estado, responsable_id)
VALUES
    ('OP-001', '2026-03-01', '2026-03-05', (SELECT id FROM producto WHERE nombre = 'Ropero'), 12, 'completada', (SELECT id FROM usuario WHERE email = 'pedro@muebleria.com')),
    ('OP-002', '2026-03-08', '2026-03-12', (SELECT id FROM producto WHERE nombre = 'Ropero'), 15, 'completada', (SELECT id FROM usuario WHERE email = 'pedro@muebleria.com')),
    ('OP-003', '2026-03-12', '2026-03-18', (SELECT id FROM producto WHERE nombre = 'Cómoda'), 18, 'completada', (SELECT id FROM usuario WHERE email = 'pedro@muebleria.com')),
    ('OP-004', '2026-03-18', '2026-03-22', (SELECT id FROM producto WHERE nombre = 'Velador'), 35, 'completada', (SELECT id FROM usuario WHERE email = 'pedro@muebleria.com')),
    ('OP-005', '2026-03-22', '2026-03-27', (SELECT id FROM producto WHERE nombre = 'Comodín'), 15, 'completada', (SELECT id FROM usuario WHERE email = 'pedro@muebleria.com')),
    ('OP-006', '2026-03-25', '2026-03-30', (SELECT id FROM producto WHERE nombre = 'Ropero'), 10, 'completada', (SELECT id FROM usuario WHERE email = 'pedro@muebleria.com'));

-- ============================================================
--  DATOS TRANSACCIONALES — PRODUCCIÓN (Actualizado con orden_produccion_id)
-- ============================================================

INSERT INTO produccion (orden_produccion_id, fecha_produccion, producto_id, cantidad_producida, costo_materia_prima, mano_de_obra, costo_total, destino_id)
SELECT 
    op.id,
    pr.fecha, 
    p.id, 
    pr.cantidad, 
    pr.costo_mp, 
    pr.mano_obra, 
    pr.costo_total, 
    d.id
FROM (VALUES
    ('OP-001', '2026-03-02'::date, 'Ropero',  12, 5.76, 1.68, 7.44, 'Stock + pedidos'),
    ('OP-002', '2026-03-10'::date, 'Ropero',  15, 6.75, 2.10, 8.85, 'Mayoristas'),
    ('OP-003', '2026-03-15'::date, 'Cómoda',  18, 4.32, 1.44, 5.76, 'Stock'),
    ('OP-004', '2026-03-20'::date, 'Velador', 35, 2.45, 1.05, 3.50, 'Retail'),
    ('OP-005', '2026-03-25'::date, 'Comodín', 15, 1.35, 0.75, 2.10, 'Stock'),
    ('OP-006', '2026-03-28'::date, 'Ropero',  10, 4.80, 1.40, 6.20, 'Pedidos finales')
) AS pr(orden_numero, fecha, producto, cantidad, costo_mp, mano_obra, costo_total, destino)
JOIN orden_produccion op ON op.numero_orden = pr.orden_numero
JOIN producto p ON p.nombre = pr.producto
JOIN destino_produccion d ON d.descripcion = pr.destino;

-- ============================================================
--  DATOS TRANSACCIONALES — CONSUMO DE MATERIALES
-- ============================================================

INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario, costo_total)
SELECT 
    p.id,
    m.id,
    consumos.cantidad,
    consumos.costo_unitario,
    consumos.cantidad * consumos.costo_unitario
FROM produccion p
JOIN producto prod ON prod.id = p.producto_id
CROSS JOIN (VALUES
    ('Ropero', 'Melamina Blanco 18mm', 2.5, 150.00),
    ('Ropero', 'Mapresa (fondo)', 1.0, 100.00),
    ('Ropero', 'Tornillos (caja 1000)', 0.05, 80.00),
    ('Ropero', 'Jaladores', 4.0, 1.00),
    ('Ropero', 'Correderas (30cm)', 2.0, 20.00),
    ('Ropero', 'Patitas', 4.0, 0.40),
    ('Velador', 'Melamina Blanco 18mm', 0.8, 150.00),
    ('Velador', 'Mapresa (fondo)', 0.3, 100.00),
    ('Velador', 'Tornillos (caja 1000)', 0.02, 80.00),
    ('Velador', 'Jaladores', 1.0, 1.00),
    ('Velador', 'Patitas', 4.0, 0.40),
    ('Cómoda', 'Melamina Color 18mm', 2.0, 180.00),
    ('Cómoda', 'Mapresa (fondo)', 0.8, 100.00),
    ('Cómoda', 'Tornillos (caja 1000)', 0.04, 80.00),
    ('Cómoda', 'Jaladores', 3.0, 1.00),
    ('Cómoda', 'Correderas (30cm)', 2.0, 20.00),
    ('Comodín', 'Melamina Blanco 18mm', 1.2, 150.00),
    ('Comodín', 'Mapresa (fondo)', 0.5, 100.00),
    ('Comodín', 'Tornillos (caja 1000)', 0.03, 80.00),
    ('Comodín', 'Jaladores', 2.0, 1.00),
    ('Comodín', 'Bisagras (caja 100)', 0.02, 90.00)
) AS consumos(producto_nombre, material_nombre, cantidad, costo_unitario)
JOIN material m ON m.nombre = consumos.material_nombre
WHERE prod.nombre = consumos.producto_nombre
AND p.cantidad_producida = (
    SELECT MAX(p2.cantidad_producida) 
    FROM produccion p2 
    JOIN producto prod2 ON prod2.id = p2.producto_id 
    WHERE prod2.nombre = consumos.producto_nombre
    GROUP BY prod2.nombre
);

-- ============================================================
--  DATOS TRANSACCIONALES — COMPRA DE MATERIALES
-- ============================================================

INSERT INTO compra_material (fecha, proveedor_id, material_id, cantidad, precio_unitario, total_compra, notas, usuario_id)
SELECT 
    cm.fecha,
    COALESCE(m.proveedor_preferido_id, 1),
    m.id,
    cm.cantidad,
    cm.precio_unit,
    cm.cantidad * cm.precio_unit,
    cm.notas,
    (SELECT id FROM usuario WHERE email = 'admin@muebleria.com')
FROM (VALUES
    ('2026-03-01'::date, 'Melamina Blanco 18mm', 8, 150.00, 'Compra inicial'),
    ('2026-03-03'::date, 'Mapresa (fondo)', 5, 100.00, 'Compra inicial'),
    ('2026-03-05'::date, 'Tornillos (caja 1000)', 1, 80.00, 'Compra inicial'),
    ('2026-03-07'::date, 'Melamina Color 18mm', 6, 180.00, 'Compra inicial'),
    ('2026-03-10'::date, 'Tapacanto (rollo)', 3, 35.00, 'Compra inicial'),
    ('2026-03-12'::date, 'Jaladores', 150, 1.00, 'Compra inicial'),
    ('2026-03-14'::date, 'Correderas (30cm)', 40, 20.00, 'Compra inicial'),
    ('2026-03-18'::date, 'Melamina Blanco 18mm', 7, 152.00, 'Compra adicional'),
    ('2026-03-20'::date, 'Bisagras (caja 100)', 1, 90.00, 'Compra inicial'),
    ('2026-03-23'::date, 'Mapresa (fondo)', 4, 100.00, 'Reposición'),
    ('2026-03-25'::date, 'Melamina Color 18mm', 5, 175.00, 'Compra urgente'),
    ('2026-03-28'::date, 'Patitas', 200, 0.40, 'Compra inicial'),
    ('2026-03-30'::date, 'Tornillos (caja 1000)', 1, 80.00, 'Reposición')
) AS cm(fecha, material_nombre, cantidad, precio_unit, notas)
JOIN material m ON m.nombre = cm.material_nombre;

-- ============================================================
--  DATOS TRANSACCIONALES — GASTOS
-- ============================================================

INSERT INTO gasto (fecha, categoria_id, monto, detalle, usuario_id)
SELECT 
    g.fecha,
    cg.id,
    g.monto,
    g.detalle,
    (SELECT id FROM usuario WHERE email = 'maria@muebleria.com')
FROM (VALUES
    ('2026-03-15'::date, 'Mano de Obra (eventual)', 6800, 'Pago 3 trabajadores - Marzo'),
    ('2026-03-20'::date, 'Compra Melamina y accesorios', 5240, 'Compra materiales producción'),
    ('2026-03-05'::date, 'Alquiler local + servicios', 2800, 'Alquiler marzo + servicios'),
    ('2026-03-25'::date, 'Transporte y delivery', 980, 'Entregas marzo'),
    ('2026-03-28'::date, 'Otros (herramientas, etc.)', 650, 'Mantenimiento y herramientas')
) AS g(fecha, categoria, monto, detalle)
JOIN categoria_gasto cg ON cg.nombre = g.categoria;

-- ============================================================
--  VISTAS DE COMPATIBILIDAD PARA SCRIPTS ETL DEL DATAMART
--  Las tablas "gasto_mes" e "inventario" no existen como tablas
--  independientes. Se definen como vistas sobre datos existentes
--  para que los scripts 2_G_pasos.sql y 3_poblar.sql funcionen
--  sin modificar su lógica.
-- ============================================================

-- Vista gasto_mes: expone la tabla gasto con el alias "periodo"
CREATE OR REPLACE VIEW gasto_mes AS
SELECT
    id,
    fecha           AS periodo,
    categoria_id,
    monto,
    detalle
FROM gasto;

-- Vista inventario: expone compra_material enriquecida con el
-- nombre del material (estructura plana que espera el ETL)
CREATE OR REPLACE VIEW inventario AS
SELECT
    cm.id,
    cm.fecha,
    m.nombre                AS material,
    m.unidad_medida_id      AS unidad_id,
    cm.cantidad,
    cm.precio_unitario,
    cm.total_compra,
    COALESCE(cm.notas, '')  AS notas
FROM compra_material cm
JOIN material m ON m.id = cm.material_id;

-- ============================================================
--  CONSULTAS ÚTILES DE VERIFICACIÓN
-- ============================================================

-- 1. Ver stock actual de materiales
SELECT m.nombre, m.stock_actual, um.abreviatura, m.stock_minimo,
       CASE WHEN m.stock_actual <= m.stock_minimo THEN 'ALERTA: Stock bajo' ELSE 'OK' END as estado
FROM material m
JOIN unidad_medida um ON um.id = m.unidad_medida_id
ORDER BY m.stock_actual;

-- 2. Ver stock de productos terminados
SELECT p.nombre, s.cantidad_disponible, s.punto_reorden,
       CASE WHEN s.cantidad_disponible <= s.punto_reorden THEN 'ALERTA: Stock bajo' ELSE 'OK' END as estado
FROM stock_producto_terminado s
JOIN producto p ON p.id = s.producto_id
ORDER BY s.cantidad_disponible;

-- 3. Ver cuentas por cobrar pendientes
SELECT c.nombre as cliente, v.fecha, v.total_venta, cc.saldo_pendiente, cc.fecha_vencimiento,
       CASE WHEN cc.fecha_vencimiento < CURRENT_DATE AND cc.saldo_pendiente > 0 THEN 'VENCIDO' ELSE 'OK' END as estado
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE cc.saldo_pendiente > 0
ORDER BY cc.fecha_vencimiento;

-- 4. Resumen de ventas por producto
SELECT p.nombre, COUNT(*) as num_ventas, SUM(v.cantidad) as unidades_vendidas, SUM(v.total_venta) as ingreso_total
FROM venta v
JOIN producto p ON p.id = v.producto_id
GROUP BY p.nombre
ORDER BY ingreso_total DESC;

-- 5. Rentabilidad por producto
SELECT 
    p.nombre,
    SUM(v.cantidad) as unidades_vendidas,
    SUM(v.total_venta) as ingreso_total,
    AVG(v.precio_unitario) as precio_promedio,
    p.costo_estandar as costo_unitario_estandar,
    SUM(v.total_venta) - (SUM(v.cantidad) * p.costo_estandar) as margen_bruto,
    ((SUM(v.total_venta) - (SUM(v.cantidad) * p.costo_estandar)) / SUM(v.total_venta)) * 100 as margen_porcentaje
FROM venta v
JOIN producto p ON p.id = v.producto_id
GROUP BY p.nombre, p.costo_estandar
ORDER BY margen_bruto DESC;

-- 6. Consumo de materiales por producto
SELECT 
    prod.nombre as producto,
    m.nombre as material,
    SUM(cm.cantidad_consumida / p.cantidad_producida) as consumo_por_unidad,
    um.abreviatura as unidad
FROM consumo_material cm
JOIN produccion p ON p.id = cm.produccion_id
JOIN producto prod ON prod.id = p.producto_id
JOIN material m ON m.id = cm.material_id
JOIN unidad_medida um ON um.id = m.unidad_medida_id
GROUP BY prod.nombre, m.nombre, um.abreviatura
ORDER BY prod.nombre, m.nombre;